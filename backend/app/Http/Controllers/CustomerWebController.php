<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use App\Models\Branch;
use App\Models\Service;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CustomerWebController extends Controller
{
    /**
     * Customer Dashboard Overview.
     */
    public function dashboard()
    {
        $user = Auth::user();

        $myBookings = Booking::where('user_id', $user->id)
            ->with(['tenant', 'branch', 'service', 'staff'])
            ->latest()
            ->get();

        $activeBookings = $myBookings->whereIn('status', ['CONFIRMED', 'LOCKED', 'PENDING']);
        $featuredSalons = Tenant::whereNotIn('status', ['SUSPENDED', 'REJECTED'])->with(['branches.workingHours'])->take(4)->get();

        return view('customer.dashboard', compact('user', 'myBookings', 'activeBookings', 'featuredSalons'));
    }

    /**
     * Customer Salon Discovery & Search.
     */
    public function explore(Request $request)
    {
        $query = $request->query('q');
        $pincode = $request->query('pincode');
        $category = $request->query('category');

        $salonsQuery = Tenant::whereNotIn('status', ['SUSPENDED', 'REJECTED', 'SUSPENDED_FOR_DELETION'])
            ->with(['branches.workingHours', 'branches.staff', 'branches.combos']);

        if ($query) {
            $salonsQuery->where(function($q) use ($query) {
                $q->where('business_name', 'LIKE', "%{$query}%")
                  ->orWhereHas('branches', function($b) use ($query) {
                      $b->where('pin_code', 'LIKE', "%{$query}%")
                        ->orWhere('city', 'LIKE', "%{$query}%")
                        ->orWhere('address', 'LIKE', "%{$query}%")
                        ->orWhere('name', 'LIKE', "%{$query}%");
                  });
            });
        }

        $salons = $salonsQuery->get();

        // 📍 Proximity Priority Sorting: If pincode is provided, salons with matching or nearest branch PIN appear first!
        if (!empty($pincode)) {
            $cleanPin = trim($pincode);
            $salons = $salons->sortBy(function($salon) use ($cleanPin) {
                $hasExactPin = $salon->branches->contains(function($b) use ($cleanPin) {
                    return trim($b->pin_code) === $cleanPin;
                });
                if ($hasExactPin) return 0;

                // Close prefix match (e.g. same postal region first 3 digits)
                $prefixMatch = $salon->branches->contains(function($b) use ($cleanPin) {
                    return substr(trim($b->pin_code), 0, 3) === substr($cleanPin, 0, 3);
                });
                return $prefixMatch ? 1 : 2;
            })->values();
        }

        $services = Service::where('is_active', true)->get();
        $combos = \App\Models\ServiceCombo::where('is_active', true)->with('services')->get();

        return view('customer.explore', compact('salons', 'services', 'combos', 'query', 'pincode', 'category'));
    }

    /**
     * Customer Booking History.
     */
    public function bookings()
    {
        $user = Auth::user();
        $bookings = Booking::where('user_id', $user->id)
            ->with(['tenant', 'branch', 'service', 'combo', 'staff'])
            ->latest()
            ->paginate(10);

        return view('customer.bookings', compact('bookings'));
    }

    /**
     * Real Customer Booking Handler with Shop Policy & CRM Evaluation.
     */
    public function storeBooking(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'tenant_id' => 'required|exists:tenants,id',
            'branch_id' => 'nullable|exists:branches,id',
            'service_id' => 'nullable|exists:services,id',
            'combo_id' => 'nullable|exists:service_combos,id',
            'staff_id' => 'nullable',
            'booking_date' => 'required|date',
            'start_time' => 'required|string',
        ]);

        if (empty($validated['service_id']) && empty($validated['combo_id'])) {
            return back()->with('error', 'Please select either a service or a combo.');
        }

        $tenant = Tenant::findOrFail($validated['tenant_id']);
        $branch = !empty($validated['branch_id']) 
            ? Branch::where('tenant_id', $tenant->id)->findOrFail($validated['branch_id']) 
            : Branch::where('tenant_id', $tenant->id)->first();

        // 0a. Validate Branch Active status
        if ($branch && !$branch->is_active) {
            return back()->with('error', "Booking Denied: Branch '{$branch->name}' is temporarily closed / disabled by the salon owner.");
        }

        // 0b. Validate Owner Online / Emergency Availability
        if (in_array($tenant->status, ['EMERGENCY_CLOSED', 'OFFLINE', 'SUSPENDED_FOR_DELETION'])) {
            return back()->with('error', "Booking Denied: '{$tenant->business_name}' is currently offline (bookings paused by owner). Please check back later.");
        }

        // 0c. Validate Branch Business Hours for the selected date
        $dayOfWeek = date('w', strtotime($validated['booking_date']));
        $bwh = \App\Models\BranchWorkingHour::where('branch_id', $branch->id ?? null)
            ->where('day_of_week', $dayOfWeek)
            ->first();

        if ($bwh && !$bwh->is_open) {
            return back()->with('error', "Booking Denied: Branch '{$branch->name}' is closed on " . date('l', strtotime($validated['booking_date'])) . "s.");
        }
        
        $durationMinutes = 0;
        $amount = 0;
        $itemName = '';

        if (!empty($validated['combo_id'])) {
            $combo = \App\Models\ServiceCombo::findOrFail($validated['combo_id']);
            $durationMinutes = $combo->duration_minutes;
            $amount = $combo->price;
            $itemName = $combo->name . ' (Combo)';
        } else {
            $service = Service::findOrFail($validated['service_id']);
            $durationMinutes = $service->duration_minutes;
            $amount = $service->price;
            $itemName = $service->name;
        }

        $staffId = null;
        if (!empty($validated['staff_id']) && $validated['staff_id'] !== 'any') {
            $staffId = $validated['staff_id'];
        } else {
            // Find any available staff in the branch
            $staff = \App\Models\Staff::where('branch_id', $branch->id ?? null)->first();
            $staffId = $staff->id ?? null;
        }

        // 1. Check if customer is added in shop CRM list
        $isCrmAdded = \Illuminate\Support\Facades\DB::table('tenant_customers')
            ->where('tenant_id', $tenant->id)
            ->where('user_id', $user->id)
            ->where('is_added', true)
            ->exists();

        // 1b. 🛡️ Anti-Abuse Guard: Cap active PENDING/LOCKED bookings to max 3 per customer
        $activeCount = Booking::where('user_id', $user->id)
            ->whereIn('status', ['PENDING', 'LOCKED'])
            ->count();

        if ($activeCount >= 3) {
            return back()->with('error', '🛡️ Anti-Abuse Guard: You already have 3 active pending appointments. Please wait for salon approval before creating new ones.');
        }

        // 1c. 🛡️ Cool-Down Anti-Spam Guard: Prevent duplicate requests within 10 seconds
        $recentReq = Booking::where('user_id', $user->id)
            ->where('created_at', '>=', now()->subSeconds(10))
            ->first();

        if ($recentReq) {
            return back()->with('error', '⏱️ Anti-Spam Guard: Please wait 10 seconds before submitting another booking.');
        }

        // 2. Evaluate Shop Booking Policy
        if ($tenant->booking_policy === 'ADDED_CUSTOMERS_ONLY' && !$isCrmAdded) {
            return back()->with('error', "Booking Denied: '{$tenant->business_name}' currently accepts bookings exclusively for pre-approved CRM members. Please contact the salon owner to add your account.");
        }

        $status = 'PENDING';
        $paymentNote = 'Pay at Salon (Pending Owner Approval)';

        if ($tenant->booking_policy === 'AUTO_ACCEPT' || $tenant->booking_policy === 'PREPAYMENT_REQUIRED_ALL') {
            $status = 'CONFIRMED';
            $paymentNote = 'Confirmed automatically by Shop Auto-Accept policy';
        } elseif ($tenant->booking_policy === 'PREPAYMENT_REQUIRED_NEW' && !$isCrmAdded) {
            $status = 'CONFIRMED';
            $paymentNote = 'Prepayment Completed (New Customer)';
        }

        $startTimeStr = $validated['start_time'];
        $endTimeStr = date('H:i:s', strtotime($startTimeStr) + ($durationMinutes * 60));
        $bookingDate = $validated['booking_date'];

        // 🔒 3. Concurrency Lock: Atomic DB Transaction to prevent double booking during 15+ simultaneous incoming bookings
        return \Illuminate\Support\Facades\DB::transaction(function () use ($tenant, $branch, $validated, $staffId, $user, $bookingDate, $startTimeStr, $endTimeStr, $amount, $status, $paymentNote) {
            $conflict = Booking::where('tenant_id', $tenant->id)
                ->where('booking_date', $bookingDate)
                ->where('staff_id', $staffId)
                ->whereIn('status', ['CONFIRMED', 'PENDING', 'LOCKED'])
                ->where(function ($q) use ($startTimeStr, $endTimeStr) {
                    $q->where('start_time', '<', $endTimeStr)
                      ->where('end_time', '>', $startTimeStr);
                })
                ->lockForUpdate()
                ->exists();

            if ($conflict) {
                return back()->with('error', '⚠️ Slot Conflict: This time slot was reserved by another customer a split-second ago. Please choose another slot.');
            }

            $booking = Booking::create([
                'tenant_id' => $tenant->id,
                'branch_id' => $branch->id ?? 1,
                'service_id' => $validated['service_id'] ?? null,
                'combo_id' => $validated['combo_id'] ?? null,
                'staff_id' => $staffId,
                'user_id' => $user->id,
                'booking_date' => $bookingDate,
                'start_time' => $startTimeStr,
                'end_time' => $endTimeStr,
                'amount' => $amount,
                'status' => $status
            ]);

            return redirect()->route('customer.bookings')->with('success', "🎉 Booking #{$booking->id} submitted successfully at {$tenant->business_name}! Status: {$status} ({$paymentNote}).");
        });
    }

    /**
     * Dynamic Slot Calculation Engine (Branch Working Hours + Split Shift + Duration + Buffer + Gap Fitting)
     */
    public function getAvailableSlots(Request $request)
    {
        $tenantId = $request->query('tenant_id');
        $branchId = $request->query('branch_id');
        $serviceId = $request->query('service_id');
        $comboId = $request->query('combo_id');
        $staffId = $request->query('staff_id');
        $date = $request->query('date', date('Y-m-d'));

        if (!$tenantId) {
            return response()->json(['slots' => [], 'is_closed' => false]);
        }

        $branch = !empty($branchId)
            ? Branch::where('tenant_id', $tenantId)->find($branchId)
            : Branch::where('tenant_id', $tenantId)->first();

        if (!$branch) {
            return response()->json(['slots' => [], 'is_closed' => false]);
        }

        if (!$branch->is_active) {
            return response()->json([
                'is_closed' => true,
                'message' => "Branch '{$branch->name}' is temporarily closed / disabled by the salon owner.",
                'slots' => []
            ]);
        }

        // 0. Check Branch Business Hours for this Day of Week
        $dayOfWeek = date('w', strtotime($date)); // 0=Sunday
        $bwh = \App\Models\BranchWorkingHour::where('branch_id', $branch->id)
            ->where('day_of_week', $dayOfWeek)
            ->first();

        if ($bwh && !$bwh->is_open) {
            return response()->json([
                'is_closed' => true,
                'message' => 'Salon is CLOSED on ' . date('l', strtotime($date)) . 's.',
                'slots' => []
            ]);
        }

        // 1. Calculate target duration and buffer time
        $durationMinutes = 30;
        $bufferMinutes = 5;

        if ($comboId) {
            $combo = \App\Models\ServiceCombo::find($comboId);
            if ($combo) {
                $durationMinutes = $combo->duration_minutes;
                $bufferMinutes = 5;
            }
        } elseif ($serviceId) {
            $service = Service::find($serviceId);
            if ($service) {
                $durationMinutes = $service->duration_minutes;
                $bufferMinutes = $service->buffer_time_minutes ?? 5;
            }
        }

        $totalRequiredMinutes = $durationMinutes + $bufferMinutes;

        // 2. Define Operating Time Windows (Main Shift & Split Shift)
        $shiftWindows = [];
        $mainStart = $bwh ? $bwh->open_time : '10:00:00';
        $mainClose = $bwh ? $bwh->close_time : '20:00:00';
        $shiftWindows[] = ['start' => strtotime("{$date} {$mainStart}"), 'end' => strtotime("{$date} {$mainClose}")];

        if ($bwh && $bwh->has_split_shift && $bwh->split_open_time && $bwh->split_close_time) {
            $shiftWindows[] = ['start' => strtotime("{$date} {$bwh->split_open_time}"), 'end' => strtotime("{$date} {$bwh->split_close_time}")];
        }

        // 3. Fetch Existing Active Bookings for that date & staff/branch
        $bookingsQuery = Booking::where('branch_id', $branch->id)
            ->where('booking_date', $date)
            ->whereIn('status', ['CONFIRMED', 'PENDING', 'LOCKED']);

        if ($staffId && $staffId !== 'any') {
            $bookingsQuery->where('staff_id', $staffId);
        }

        $existingBookings = $bookingsQuery->orderBy('start_time', 'asc')->get();

        $occupiedIntervals = [];
        foreach ($existingBookings as $b) {
            $bStart = strtotime("{$date} {$b->start_time}");
            $bEnd = strtotime("{$date} {$b->end_time}");
            $occupiedIntervals[] = ['start' => $bStart, 'end' => $bEnd];
        }

        // 4. Calculate Dynamic Slots Across All Open Operating Shift Windows
        $availableSlots = [];

        foreach ($shiftWindows as $window) {
            $currentSec = $window['start'];
            $shopEndSec = $window['end'];

            while ($currentSec + ($totalRequiredMinutes * 60) <= $shopEndSec) {
                $candidateEndSec = $currentSec + ($totalRequiredMinutes * 60);
                
                $hasCollision = false;
                $nextJumpSec = null;

                foreach ($occupiedIntervals as $interval) {
                    if (max($currentSec, $interval['start']) < min($candidateEndSec, $interval['end'])) {
                        $hasCollision = true;
                        if ($nextJumpSec === null || $interval['end'] > $nextJumpSec) {
                            $nextJumpSec = $interval['end'];
                        }
                    }
                }

                if (!$hasCollision) {
                    $gapEndSec = $shopEndSec;
                    foreach ($occupiedIntervals as $interval) {
                        if ($interval['start'] > $currentSec && $interval['start'] < $gapEndSec) {
                            $gapEndSec = $interval['start'];
                        }
                    }

                    $availableGapMinutes = floor(($gapEndSec - $currentSec) / 60);

                    $availableSlots[] = [
                        'time_value' => date('H:i:s', $currentSec),
                        'display_text' => date('h:i A', $currentSec),
                        'available_gap_minutes' => $availableGapMinutes,
                        'fits_requested_service' => ($availableGapMinutes >= $totalRequiredMinutes)
                    ];

                    $currentSec += 15 * 60;
                } else {
                    $currentSec = $nextJumpSec ? $nextJumpSec : ($currentSec + 15 * 60);
                }
            }
        }

        return response()->json([
            'required_minutes' => $totalRequiredMinutes,
            'duration_minutes' => $durationMinutes,
            'buffer_minutes' => $bufferMinutes,
            'slots' => $availableSlots
        ]);
    }
}
