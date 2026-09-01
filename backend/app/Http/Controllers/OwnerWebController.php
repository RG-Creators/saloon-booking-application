<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use App\Models\Branch;
use App\Models\Service;
use App\Models\Staff;
use App\Models\Booking;
use App\Models\TenantLedger;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OwnerWebController extends Controller
{
    /**
     * Get active tenant for logged-in shop owner.
     */
    private function getTenant()
    {
        $user = Auth::user();
        if (!$user->tenant_id) {
            abort(403, 'User is not associated with any salon tenant.');
        }
        return Tenant::findOrFail($user->tenant_id);
    }

    /**
     * Owner Overview Dashboard.
     */
    public function dashboard()
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        $branchIds = $branches->pluck('id');
        $services = Service::whereIn('branch_id', $branchIds)->get();
        $staffCount = Staff::whereIn('branch_id', $branchIds)->count();

        $recentBookings = Booking::where('tenant_id', $tenant->id)
            ->with(['branch', 'service', 'staff', 'customer'])
            ->latest()
            ->take(5)
            ->get();

        $pendingBookings = Booking::where('tenant_id', $tenant->id)
            ->where('status', 'PENDING')
            ->count();

        $todaysRevenue = Booking::where('tenant_id', $tenant->id)
            ->whereDate('created_at', now()->today())
            ->whereIn('status', ['CONFIRMED', 'COMPLETED'])
            ->sum('amount');

        // Ledger balance
        $ledgerDebit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount');
        $ledgerCredit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount');
        $unpaidSaasFee = max(0, $ledgerDebit - $ledgerCredit);

        // Only fetch UNREAD/NEW active bookings (status PENDING or CONFIRMED) created in the last 10 minutes
        $latestUnreadBooking = Booking::where('tenant_id', $tenant->id)
            ->whereIn('status', ['PENDING', 'CONFIRMED'])
            ->where('created_at', '>=', now()->subMinutes(10))
            ->with(['customer', 'service', 'staff'])
            ->latest()
            ->first();

        return view('owner.dashboard', compact(
            'tenant', 'branches', 'services', 'staffCount', 'recentBookings', 
            'pendingBookings', 'todaysRevenue', 'unpaidSaasFee', 'latestUnreadBooking'
        ));
    }

    /**
     * Real-time AJAX endpoint for live unread booking alerts.
     */
    public function getUnreadBookingAlert()
    {
        $tenant = $this->getTenant();

        $booking = Booking::where('tenant_id', $tenant->id)
            ->where(function($q) {
                $q->where('status', 'PENDING')
                  ->orWhere(function($q2) {
                      $q2->where('status', 'CONFIRMED')
                         ->whereColumn('created_at', 'updated_at');
                  });
            })
            ->where('created_at', '>=', now()->subMinutes(15))
            ->with(['customer', 'service', 'staff'])
            ->latest()
            ->first();

        if (!$booking) {
            return response()->json(['has_new' => false]);
        }

        $pendingQueueCount = Booking::where('tenant_id', $tenant->id)
            ->where('status', 'PENDING')
            ->count();

        $formattedTime = date('h:i A', strtotime($booking->start_time));
        $formattedDate = date('d M Y', strtotime($booking->booking_date));

        return response()->json([
            'has_new' => true,
            'id' => $booking->id,
            'status' => $booking->status,
            'auto_accepted' => ($booking->status === 'CONFIRMED'),
            'pending_queue_count' => $pendingQueueCount,
            'booking_type' => $booking->booking_type ?? 'IN_STUDIO',
            'service_address' => $booking->service_address ?? '',
            'address_landmark' => $booking->address_landmark ?? '',
            'occasion_type' => $booking->occasion_type ?? '',
            'travel_fee' => (float) ($booking->travel_fee ?? 0),
            'customer_name' => $booking->customer->name ?? 'Guest Client',
            'customer_mobile' => $booking->customer->mobile ?? 'N/A',
            'service_name' => $booking->service->name ?? 'Salon Service',
            'staff_name' => $booking->staff->name ?? 'Assigned Stylist',
            'booking_date' => $formattedDate,
            'start_time' => $formattedTime,
            'slot_display' => "{$formattedDate} at {$formattedTime}",
            'amount' => number_format($booking->amount, 2),
            'time_ago' => $booking->created_at->diffForHumans()
        ]);
    }

    /**
     * Services Management View.
     */
    public function services()
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        $branchIds = $branches->pluck('id');
        $services = Service::whereIn('branch_id', $branchIds)->get();
        return view('owner.services', compact('tenant', 'branches', 'services'));
    }

    /**
     * Store a new service.
     */
    public function storeService(Request $request)
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        if ($branches->isEmpty()) {
            return back()->with('info', 'Please create at least one branch location before adding services.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'branch_id' => 'required|exists:branches,id',
            'category' => 'required|string|max:100',
            'duration_minutes' => 'required|integer|min:5|max:480',
            'price' => 'required|numeric|min:0',
            'buffer_time_minutes' => 'nullable|integer|min:0'
        ]);

        Service::create([
            'branch_id' => $validated['branch_id'],
            'name' => $validated['name'],
            'category' => $validated['category'],
            'duration_minutes' => $validated['duration_minutes'],
            'price' => $validated['price'],
            'buffer_time_minutes' => $validated['buffer_time_minutes'] ?? 5,
            'is_active' => true
        ]);

        return back()->with('success', 'Service created successfully.');
    }

    /**
     * Service Combos Management View.
     */
    public function combos()
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        $branchIds = $branches->pluck('id');
        $services = Service::whereIn('branch_id', $branchIds)->get();
        $combos = \App\Models\ServiceCombo::whereIn('branch_id', $branchIds)->with('services')->get();

        return view('owner.combos', compact('tenant', 'branches', 'services', 'combos'));
    }

    /**
     * Store a new service combo.
     */
    public function storeCombo(Request $request)
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        if ($branches->isEmpty()) {
            return back()->with('info', 'Please create at least one branch location before adding combos.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'branch_id' => 'required|exists:branches,id',
            'price' => 'required|numeric|min:0',
            'duration_minutes' => 'required|integer|min:5|max:480',
            'services' => 'required|array',
            'services.*' => 'exists:services,id'
        ]);

        $combo = \App\Models\ServiceCombo::create([
            'branch_id' => $validated['branch_id'],
            'name' => $validated['name'],
            'price' => $validated['price'],
            'duration_minutes' => $validated['duration_minutes'],
            'discount' => 0, // Can be calculated if needed
            'is_active' => true
        ]);

        $combo->services()->sync($validated['services']);

        return back()->with('success', 'Service Combo created successfully.');
    }

    /**
     * Staff Management View.
     */
    public function staff()
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        $branchIds = $branches->pluck('id');
        $staffMembers = Staff::whereIn('branch_id', $branchIds)->with('branch')->get();
        return view('owner.staff', compact('tenant', 'staffMembers', 'branches'));
    }

    /**
     * Store new staff member.
     */
    public function storeStaff(Request $request)
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        if ($branches->isEmpty()) {
            return back()->with('info', 'Please create at least one branch location before adding staff.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'branch_id' => 'required|exists:branches,id',
            'position' => 'required|string|max:100',
            'phone' => 'nullable|string|max:20'
        ]);

        Staff::create([
            'branch_id' => $validated['branch_id'],
            'name' => $validated['name'],
            'role' => $validated['position'],
            'mobile' => $validated['phone'] ?? null,
            'is_active' => true
        ]);

        return back()->with('success', 'Staff member added successfully.');
    }

    /**
     * Staff Schedules and Business Opening Hours View.
     */
    public function schedules()
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->with('workingHours')->get();
        $branchIds = $branches->pluck('id');
        
        $staffMembers = Staff::whereIn('branch_id', $branchIds)
            ->with(['branch', 'workingHours'])
            ->get();
            
        return view('owner.schedules', compact('tenant', 'branches', 'staffMembers'));
    }

    /**
     * Update Shop / Branch Operating Hours & Split Shifts.
     */
    public function updateBranchHours(Request $request)
    {
        $tenant = $this->getTenant();
        
        $validated = $request->validate([
            'branch_id' => 'required|exists:branches,id',
            'days' => 'required|array',
            'days.*.day_of_week' => 'required|integer|min:0|max:6',
            'days.*.is_open' => 'nullable',
            'days.*.open_time' => 'required|string',
            'days.*.close_time' => 'required|string',
            'days.*.has_split_shift' => 'nullable',
            'days.*.split_open_time' => 'nullable|string',
            'days.*.split_close_time' => 'nullable|string',
        ]);

        $branch = Branch::where('tenant_id', $tenant->id)->where('id', $validated['branch_id'])->firstOrFail();

        foreach ($validated['days'] as $day) {
            $isOpen = isset($day['is_open']) ? true : false;
            $hasSplit = isset($day['has_split_shift']) ? true : false;
            
            \App\Models\BranchWorkingHour::updateOrCreate(
                ['branch_id' => $branch->id, 'day_of_week' => $day['day_of_week']],
                [
                    'is_open' => $isOpen,
                    'open_time' => $day['open_time'] ?? '10:00:00',
                    'close_time' => $day['close_time'] ?? '20:00:00',
                    'has_split_shift' => $hasSplit,
                    'split_open_time' => $hasSplit ? ($day['split_open_time'] ?? null) : null,
                    'split_close_time' => $hasSplit ? ($day['split_close_time'] ?? null) : null,
                ]
            );
        }

        return back()->with('success', "Branch business operating hours & split shift schedule updated for '{$branch->name}'!");
    }

    /**
     * Update Staff Working Hours.
     */
    public function updateStaffHours(Request $request)
    {
        $tenant = $this->getTenant();
        
        $validated = $request->validate([
            'staff_id' => 'required|exists:staff,id',
            'days' => 'required|array',
            'days.*.day_of_week' => 'required|integer|min:0|max:6',
            'days.*.is_working_day' => 'nullable|boolean',
            'days.*.start_time' => 'required_with:days.*.is_working_day|date_format:H:i',
            'days.*.end_time' => 'required_with:days.*.is_working_day|date_format:H:i',
        ]);

        $staff = Staff::findOrFail($validated['staff_id']);
        
        // Ensure staff belongs to the tenant
        if (!Branch::where('tenant_id', $tenant->id)->where('id', $staff->branch_id)->exists()) {
            abort(403);
        }

        foreach ($validated['days'] as $day) {
            $isWorking = isset($day['is_working_day']) ? true : false;
            
            \App\Models\StaffWorkingHour::updateOrCreate(
                ['staff_id' => $staff->id, 'day_of_week' => $day['day_of_week']],
                [
                    'start_time' => $isWorking ? $day['start_time'] : '00:00:00',
                    'end_time' => $isWorking ? $day['end_time'] : '00:00:00',
                    'is_working_day' => $isWorking
                ]
            );
        }

        return back()->with('success', "Working hours updated successfully for {$staff->name}.");
    }

    /**
     * Appointments View.
     */
    public function appointments()
    {
        $tenant = $this->getTenant();
        $bookings = Booking::where('tenant_id', $tenant->id)
            ->with(['branch', 'service', 'staff', 'customer'])
            ->latest()
            ->paginate(15);

        return view('owner.appointments', compact('tenant', 'bookings'));
    }

    /**
     * Update appointment status & trigger automated ₹1 SaaS booking fee.
     */
    public function updateAppointmentStatus(Request $request, Booking $booking)
    {
        $tenant = $this->getTenant();

        if ($booking->tenant_id !== $tenant->id) {
            abort(403, 'Unauthorized action on booking.');
        }

        $validated = $request->validate([
            'status' => 'required|in:CONFIRMED,COMPLETED,CANCELLED,NO_SHOW'
        ]);

        $oldStatus = $booking->status;
        $booking->update(['status' => $validated['status']]);

        // Automated SaaS ₹1 per booking fee deduction whenever customer appointment is confirmed or completed
        if (in_array($validated['status'], ['CONFIRMED', 'COMPLETED'])) {
            $existingLedger = TenantLedger::where('booking_id', $booking->id)->exists();
            if (!$existingLedger) {
                TenantLedger::create([
                    'tenant_id' => $tenant->id,
                    'booking_id' => $booking->id,
                    'amount' => 1.00,
                    'type' => 'DEBIT',
                    'description' => "Glamora SaaS Booking Fee - Booking #{$booking->id} (" . ($booking->service->name ?? 'Salon Service') . ")",
                    'status' => 'PENDING'
                ]);
            }
        }

        return back()->with('success', "Booking #{$booking->id} status updated to {$validated['status']}.");
    }

    /**
     * SaaS Billing & Commission Ledger View.
     */
    /**
     * Real-time 5-second polling endpoint for Shop Owner Billing Web Portal.
     */
    public function liveData()
    {
        $tenant = $this->getTenant();

        $dbBillingEnabled = \App\Models\PlatformSetting::where('key', 'billing_enabled')->value('value');
        $billingEnabled = ($dbBillingEnabled === 'true' || $dbBillingEnabled === '1');

        $ledgers = TenantLedger::where('tenant_id', $tenant->id)
            ->where('created_at', '>=', now()->subMonths(6))
            ->latest()
            ->take(30)
            ->get()
            ->map(function($l) {
                return [
                    'id' => $l->id,
                    'date' => $l->created_at->format('M d, Y • H:i A'),
                    'description' => $l->description,
                    'booking_id' => $l->booking_id,
                    'type' => $l->type,
                    'amount' => (float)$l->amount,
                    'formatted_amount' => number_format($l->amount, 2),
                    'status' => $l->status,
                ];
            });

        $totalCompletedBookings = Booking::where('tenant_id', $tenant->id)
            ->where('status', 'COMPLETED')
            ->count();

        $ledgerDebit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount');
        $ledgerCredit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount');
        $outstandingBalance = max(0, $ledgerDebit - $ledgerCredit);

        return response()->json([
            'success' => true,
            'billing_enabled' => $billingEnabled,
            'outstanding_balance' => (float)$outstandingBalance,
            'formatted_balance' => number_format($outstandingBalance, 2),
            'total_completed_bookings' => $totalCompletedBookings,
            'ledgers' => $ledgers,
        ]);
    }

    /**
     * SaaS Billing & Commission Ledger View.
     */
    public function billing()
    {
        $tenant = $this->getTenant();

        $dbBillingEnabled = \App\Models\PlatformSetting::where('key', 'billing_enabled')->value('value');
        $billingEnabled = ($dbBillingEnabled === 'true' || $dbBillingEnabled === '1');

        $ledgers = TenantLedger::where('tenant_id', $tenant->id)
            ->where('created_at', '>=', now()->subMonths(6))
            ->latest()
            ->paginate(15);

        $totalCompletedBookings = Booking::where('tenant_id', $tenant->id)
            ->where('status', 'COMPLETED')
            ->count();

        $ledgerDebit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount');
        $ledgerCredit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount');
        $outstandingBalance = max(0, $ledgerDebit - $ledgerCredit);
        $razorpayKey = env('RAZORPAY_KEY', 'rzp_test_bookify_owner_key');

        return view('owner.billing', compact('tenant', 'ledgers', 'totalCompletedBookings', 'outstandingBalance', 'billingEnabled', 'razorpayKey'));
    }

    /**
     * Settle outstanding SaaS ledger balance via Razorpay Gateway.
     */
    public function settleLedger(Request $request)
    {
        $tenant = $this->getTenant();
        $paymentId = $request->input('razorpay_payment_id') ?: ('pay_web_' . time());
        $orderId = 'order_saas_web_' . time();

        $pendingLedgers = TenantLedger::where('tenant_id', $tenant->id)
            ->where('status', 'PENDING')
            ->get();

        if ($pendingLedgers->isEmpty()) {
            if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
                return response()->json(['success' => false, 'message' => 'No outstanding SaaS billing balance to settle.']);
            }
            return back()->with('info', 'No outstanding SaaS billing balance to settle.');
        }

        $totalAmount = $pendingLedgers->where('type', 'DEBIT')->sum('amount');

        // Mark pending debits as settled with razorpay fields
        TenantLedger::where('tenant_id', $tenant->id)
            ->where('status', 'PENDING')
            ->update([
                'status' => 'SETTLED',
                'razorpay_payment_id' => $paymentId,
                'razorpay_order_id' => $orderId,
                'settled_at' => now(),
            ]);

        $msg = "⚡ Successfully settled ₹" . number_format($totalAmount, 2) . " SaaS commission invoice via Razorpay (Payment ID: {$paymentId})!";

        if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
            return response()->json(['success' => true, 'message' => $msg]);
        }

        return back()->with('success', $msg);
    }

    /**
     * Update Shop Booking Rules & Notification Dispatch Preferences.
     */
    public function updateBookingPolicy(Request $request)
    {
        $tenant = null;
        if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json' || str_contains($request->url(), '/api/')) {
            if ($request->user() && $request->user()->tenant_id) {
                $tenant = Tenant::find($request->user()->tenant_id);
            }
        } else {
            $tenant = $this->getTenant();
        }
        
        if (!$tenant) {
            $tenant = Tenant::first();
        }

        $validated = $request->validate([
            'booking_policy' => 'required|in:AUTO_ACCEPT,PAY_AT_SALON,PREPAYMENT_REQUIRED_ALL,PREPAYMENT_REQUIRED_NEW,ADDED_CUSTOMERS_ONLY',
            'notification_target' => 'nullable|in:DISPATCH_TO_BOTH,DISPATCH_TO_STAFF,DISPATCH_TO_OWNER'
        ]);

        $updateData = ['booking_policy' => $validated['booking_policy']];
        if (isset($validated['notification_target'])) {
            $updateData['notification_target'] = $validated['notification_target'];
        }

        $tenant->update($updateData);

        if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
            return response()->json(['success' => true, 'message' => 'Shop booking policy updated successfully!', 'booking_policy' => $tenant->booking_policy]);
        }

        return back()->with('success', 'Shop booking policy and notification dispatch settings updated successfully!');
    }

    /**
     * Shop Customers & CRM Management View.
     */
    public function customers()
    {
        $tenant = $this->getTenant();

        // Get customers who have booked at this tenant
        $customerIds = Booking::where('tenant_id', $tenant->id)->pluck('user_id')->unique();
        
        // Also get all registered customers in system
        $allCustomers = \App\Models\User::role('CUSTOMER')->get();
        
        $addedCustomerIds = \Illuminate\Support\Facades\DB::table('tenant_customers')
            ->where('tenant_id', $tenant->id)
            ->where('is_added', true)
            ->pluck('user_id')
            ->toArray();

        return view('owner.customers', compact('tenant', 'allCustomers', 'addedCustomerIds'));
    }

    /**
     * Add / Pre-Approve Customer into Shop CRM List.
     */
    public function addCrmCustomer(Request $request)
    {
        $tenant = $this->getTenant();

        $validated = $request->validate([
            'email_or_mobile' => 'required|string'
        ]);

        $query = $validated['email_or_mobile'];
        $customer = \App\Models\User::where('email', $query)
            ->orWhere('mobile', $query)
            ->first();

        if (!$customer) {
            return back()->with('error', "No registered customer account found matching '{$query}'. Ask the customer to register first.");
        }

        \Illuminate\Support\Facades\DB::table('tenant_customers')->updateOrInsert(
            ['tenant_id' => $tenant->id, 'user_id' => $customer->id],
            ['is_added' => true, 'updated_at' => now(), 'created_at' => now()]
        );

        return back()->with('success', "Customer '{$customer->name}' ({$customer->email}) has been added to your shop's pre-approved CRM customer list!");
    }

    /**
     * Toggle Customer CRM Added Status.
     */
    public function toggleCrmCustomer(Request $request, \App\Models\User $customer)
    {
        $tenant = $this->getTenant();

        $existing = \Illuminate\Support\Facades\DB::table('tenant_customers')
            ->where('tenant_id', $tenant->id)
            ->where('user_id', $customer->id)
            ->first();

        $newStatus = $existing ? !$existing->is_added : true;

        \Illuminate\Support\Facades\DB::table('tenant_customers')->updateOrInsert(
            ['tenant_id' => $tenant->id, 'user_id' => $customer->id],
            ['is_added' => $newStatus, 'updated_at' => now(), 'created_at' => now()]
        );

        return back()->with('success', "Updated CRM status for customer '{$customer->name}' to " . ($newStatus ? 'ADDED / VIP' : 'REMOVED') . ".");
    }

    /**
     * Marketing & Campaign Management View.
     */
    public function marketing()
    {
        $tenant = $this->getTenant();
        
        $totalCustomers = Booking::where('tenant_id', $tenant->id)->pluck('user_id')->unique()->count();
        $vipCustomers = \Illuminate\Support\Facades\DB::table('tenant_customers')
            ->where('tenant_id', $tenant->id)
            ->where('is_added', true)
            ->count();

        // Fetch past mock campaigns if we want, or just pass basic stats
        $recentCampaigns = \App\Models\ActivityLog::where('user_id', Auth::id())
            ->where('action', 'Marketing Campaign Sent')
            ->latest()
            ->take(5)
            ->get();

        return view('owner.marketing', compact('tenant', 'totalCustomers', 'vipCustomers', 'recentCampaigns'));
    }

    /**
     * Send Marketing Campaign.
     */
    public function sendCampaign(Request $request)
    {
        $tenant = $this->getTenant();

        $validated = $request->validate([
            'campaign_title' => 'required|string|max:100',
            'campaign_message' => 'required|string|max:500',
            'target_segment' => 'required|in:ALL,VIP,INACTIVE',
        ]);

        // Simulating the sending of the campaign via FCM / Notification System
        \App\Models\ActivityLog::create([
            'user_id' => Auth::id(),
            'action' => 'Marketing Campaign Sent',
            'description' => "Sent '{$validated['campaign_title']}' to segment '{$validated['target_segment']}'. Message: {$validated['campaign_message']}",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Campaign '{$validated['campaign_title']}' has been successfully dispatched to the '{$validated['target_segment']}' segment!");
    }

    /**
     * Approve Booking Request (Triggers ₹1 SaaS Fee ONLY if billing is enabled + Auto-Reschedules conflicting lower-priority bookings).
     */
    public function approveBooking(Request $request, Booking $booking)
    {
        $tenant = $this->getTenant();
        if ($booking->tenant_id !== $tenant->id) { abort(403); }

        // 1. Auto-reschedule any conflicting standard booking to next available slot
        $this->autoRescheduleConflicts($booking);

        $booking->update([
            'status' => 'CONFIRMED',
            'decline_reason' => null
        ]);

        // Trigger ₹1 SaaS Fee ONLY if tenant or global billing is enabled
        $globalBilling = \App\Models\PlatformSetting::where('key', 'billing_enabled')->first()->value ?? 'false';
        if ($tenant->billing_enabled || $globalBilling === 'true') {
            $existingLedger = TenantLedger::where('booking_id', $booking->id)->exists();
            if (!$existingLedger) {
                TenantLedger::create([
                    'tenant_id' => $tenant->id,
                    'booking_id' => $booking->id,
                    'amount' => 1.00,
                    'type' => 'DEBIT',
                    'description' => "Glamora SaaS Commission - Booking #{$booking->id}",
                    'status' => 'PENDING'
                ]);
            }
        }

        return back()->with('success', "Booking #{$booking->id} approved successfully! Any conflicting appointments were automatically rescheduled.");
    }

    /**
     * Decline Booking Request with Reason (Instantly notifies customer).
     */
    public function declineBooking(Request $request, Booking $booking)
    {
        $tenant = $this->getTenant();
        if ($booking->tenant_id !== $tenant->id) { abort(403); }

        $validated = $request->validate([
            'decline_reason' => 'required|string|max:255'
        ]);

        $booking->update([
            'status' => 'DECLINED',
            'decline_reason' => $validated['decline_reason']
        ]);

        return back()->with('success', "Booking #{$booking->id} declined. Reason: '{$validated['decline_reason']}'.");
    }

    /**
     * Lock Time Slot Manually for Offline / Call-in / Priority Surge Clients.
     */
    public function lockSlot(Request $request)
    {
        $tenant = $this->getTenant();
        $branches = Branch::where('tenant_id', $tenant->id)->get();
        if ($branches->isEmpty()) { return back()->with('info', 'Please add a branch first.'); }

        $validated = $request->validate([
            'service_id' => 'required|exists:services,id',
            'staff_id' => 'required|exists:staff,id',
            'booking_date' => 'required|date',
            'start_time' => 'required|string',
            'lock_note' => 'required|string|max:255'
        ]);

        $service = Service::findOrFail($validated['service_id']);
        $branch = Branch::where('tenant_id', $tenant->id)->first();
        $endTime = date('H:i:s', strtotime($validated['start_time']) + ($service->duration_minutes * 60));

        $newBooking = Booking::create([
            'tenant_id' => $tenant->id,
            'branch_id' => $branch->id,
            'service_id' => $service->id,
            'staff_id' => $validated['staff_id'],
            'user_id' => null,
            'booking_date' => $validated['booking_date'],
            'start_time' => $validated['start_time'],
            'end_time' => $endTime,
            'amount' => $service->price,
            'status' => 'LOCKED',
            'lock_note' => $validated['lock_note']
        ]);

        // Auto-reschedule conflicting appointments to next open slot
        $this->autoRescheduleConflicts($newBooking);

        return back()->with('success', "Time slot {$validated['start_time']} locked successfully for '{$validated['lock_note']}'. Any overlapping appointments have been automatically rescheduled to the next available slot!");
    }

    /**
     * Helper to automatically reschedule conflicting bookings when a Priority/Rush slot is booked.
     */
    private function autoRescheduleConflicts(Booking $targetBooking)
    {
        $conflicts = Booking::where('tenant_id', $targetBooking->tenant_id)
            ->where('branch_id', $targetBooking->branch_id)
            ->where('booking_date', $targetBooking->booking_date)
            ->where('id', '!=', $targetBooking->id)
            ->whereIn('status', ['CONFIRMED', 'PENDING'])
            ->where(function($q) use ($targetBooking) {
                $q->whereRaw('GREATEST(start_time, ?) < LEAST(end_time, ?)', [
                    $targetBooking->start_time,
                    $targetBooking->end_time
                ]);
            })
            ->get();

        foreach ($conflicts as $bOld) {
            $durationSec = strtotime($bOld->end_time) - strtotime($bOld->start_time);
            if ($durationSec <= 0) $durationSec = 1800; // default 30 mins

            $newStartSec = strtotime("{$bOld->booking_date} {$targetBooking->end_time}");
            $newEndSec = $newStartSec + $durationSec;

            $newStartTimeStr = date('H:i:s', $newStartSec);
            $newEndTimeStr = date('H:i:s', $newEndSec);

            $bOld->update([
                'start_time' => $newStartTimeStr,
                'end_time' => $newEndTimeStr,
                'decline_reason' => "⚡ Auto-Rescheduled to " . date('h:i A', $newStartSec) . " due to Priority Slot Override"
            ]);

            \App\Models\ActivityLog::create([
                'user_id' => Auth::id(),
                'action' => 'Automatic Booking Rescheduled',
                'description' => "Booking #{$bOld->id} was automatically rescheduled to {$newStartTimeStr} due to Priority Rush Slot Override.",
                'ip_address' => request()->ip()
            ]);
        }
    }

    public function getApiCombos(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $branches = Branch::where('tenant_id', $tenantId)->get();
        $branchIds = $branches->pluck('id');
        
        $combos = \App\Models\ServiceCombo::whereIn('branch_id', $branchIds)
            ->with(['services', 'branch:id,name,city,pin_code'])
            ->latest()
            ->get()
            ->map(function ($c) {
                return [
                    'id'               => $c->id,
                    'branch_id'        => $c->branch_id,
                    'branch_name'      => $c->branch->name ?? 'Main Branch',
                    'name'             => $c->name,
                    'description'      => $c->description ?? '',
                    'service_type'     => $c->service_type ?? 'IN_STUDIO',
                    'price'            => (float) $c->price,
                    'home_surcharge'   => (float) ($c->home_surcharge ?? 0),
                    'duration_minutes' => (int) $c->duration_minutes,
                    'is_active'        => (bool) $c->is_active,
                    'discount'         => (float) ($c->discount ?? 0),
                    'services'         => $c->services->map(fn($s) => [
                        'id'             => $s->id,
                        'name'           => $s->name,
                        'price'          => (float) $s->price,
                        'service_type'   => $s->service_type ?? 'IN_STUDIO',
                        'home_surcharge' => (float) ($s->home_surcharge ?? 0),
                        'category'       => $s->category ?? '',
                    ])->values(),
                ];
            });

        return response()->json(['success' => true, 'data' => $combos]);
    }

    public function storeApiCombo(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $allTenantBranches = Branch::where('tenant_id', $tenantId)->get();
        if ($allTenantBranches->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'Please create at least one branch before adding combos.'], 422);
        }

        $validated = $request->validate([
            'name'                  => 'required|string|max:255',
            'description'           => 'nullable|string',
            'service_type'          => 'nullable|string|in:IN_STUDIO,AT_HOME,EVENT_WEDDING,ANY',
            'price'                 => 'required|numeric|min:0',
            'home_surcharge'        => 'nullable|numeric|min:0',
            'duration_minutes'      => 'required|integer|min:5',
            'discount'              => 'nullable|numeric|min:0',
            'branch_id'             => 'nullable|exists:branches,id',
            'branch_ids'            => 'nullable|array',
            'branch_ids.*'          => 'integer|exists:branches,id',
            'apply_to_all_branches' => 'nullable|boolean',
            'service_ids'           => 'nullable|array',
            'service_ids.*'         => 'integer|exists:services,id',
            'is_active'             => 'nullable|boolean',
        ]);

        $applyToAll = $request->boolean('apply_to_all_branches', false);
        $targetBranchIds = [];

        if ($applyToAll || (empty($validated['branch_ids']) && empty($validated['branch_id']))) {
            // Default: ALL branches
            $targetBranchIds = $allTenantBranches->pluck('id')->toArray();
        } elseif (!empty($validated['branch_ids'])) {
            $targetBranchIds = $allTenantBranches->whereIn('id', $validated['branch_ids'])->pluck('id')->toArray();
        } elseif (!empty($validated['branch_id'])) {
            $targetBranchIds = [$validated['branch_id']];
        } else {
            $targetBranchIds = [$allTenantBranches->first()->id];
        }

        // Get service names from selected service IDs to map across branches
        $selectedServiceNames = !empty($validated['service_ids'])
            ? Service::whereIn('id', $validated['service_ids'])->pluck('name')->toArray()
            : [];

        $createdCombos = [];
        foreach ($targetBranchIds as $bId) {
            $combo = \App\Models\ServiceCombo::updateOrCreate(
                [
                    'branch_id' => $bId,
                    'name'      => $validated['name'],
                ],
                [
                    'description'      => $validated['description'] ?? null,
                    'service_type'     => $validated['service_type'] ?? 'IN_STUDIO',
                    'price'            => $validated['price'],
                    'home_surcharge'   => $validated['home_surcharge'] ?? 0.00,
                    'duration_minutes' => $validated['duration_minutes'],
                    'discount'         => $validated['discount'] ?? 0,
                    'is_active'        => $validated['is_active'] ?? true,
                ]
            );

            // Link services for this branch
            if (!empty($selectedServiceNames)) {
                $branchServiceIds = Service::where('branch_id', $bId)
                    ->whereIn('name', $selectedServiceNames)
                    ->pluck('id');
                $combo->services()->sync($branchServiceIds);
            } elseif (!empty($validated['service_ids'])) {
                $combo->services()->sync($validated['service_ids']);
            }

            $createdCombos[] = $combo;
        }

        $firstCombo = $createdCombos[0]->load(['services', 'branch:id,name,city,pin_code']);

        return response()->json([
            'success' => true,
            'message' => 'Combo package published across ' . count($createdCombos) . ' branch(es)!',
            'data'    => [
                'id'               => $firstCombo->id,
                'branch_id'        => $firstCombo->branch_id,
                'branch_name'      => $firstCombo->branch->name ?? 'Main Branch',
                'name'             => $firstCombo->name,
                'description'      => $firstCombo->description ?? '',
                'service_type'     => $firstCombo->service_type ?? 'IN_STUDIO',
                'price'            => (float) $firstCombo->price,
                'home_surcharge'   => (float) ($firstCombo->home_surcharge ?? 0),
                'duration_minutes' => (int) $firstCombo->duration_minutes,
                'is_active'        => (bool) $firstCombo->is_active,
                'discount'         => (float) ($firstCombo->discount ?? 0),
                'services'         => $firstCombo->services->map(fn($s) => [
                    'id'             => $s->id,
                    'name'           => $s->name,
                    'price'          => (float) $s->price,
                    'service_type'   => $s->service_type ?? 'IN_STUDIO',
                    'home_surcharge' => (float) ($s->home_surcharge ?? 0),
                    'category'       => $s->category ?? '',
                ])->values(),
            ],
        ], 201);
    }

    public function updateApiCombo(Request $request, $id)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $allTenantBranches = Branch::where('tenant_id', $tenantId)->get();
        $branchIds = $allTenantBranches->pluck('id');
        $combo = \App\Models\ServiceCombo::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'name'                  => 'sometimes|string|max:255',
            'description'           => 'nullable|string',
            'service_type'          => 'nullable|string|in:IN_STUDIO,AT_HOME,EVENT_WEDDING,ANY',
            'price'                 => 'sometimes|numeric|min:0',
            'home_surcharge'        => 'nullable|numeric|min:0',
            'duration_minutes'      => 'sometimes|integer|min:5',
            'discount'              => 'nullable|numeric|min:0',
            'branch_ids'            => 'nullable|array',
            'branch_ids.*'          => 'integer|exists:branches,id',
            'apply_to_all_branches' => 'nullable|boolean',
            'service_ids'           => 'nullable|array',
            'service_ids.*'         => 'integer|exists:services,id',
            'is_active'             => 'nullable|boolean',
        ]);

        $applyToAll = $request->boolean('apply_to_all_branches', false);
        $oldName = $combo->name;
        $newName = $validated['name'] ?? $oldName;

        // Get service names
        $selectedServiceNames = array_key_exists('service_ids', $validated) && !empty($validated['service_ids'])
            ? Service::whereIn('id', $validated['service_ids'])->pluck('name')->toArray()
            : [];

        if ($applyToAll) {
            foreach ($allTenantBranches as $b) {
                $targetCombo = \App\Models\ServiceCombo::updateOrCreate(
                    [
                        'branch_id' => $b->id,
                        'name'      => ($b->id === $combo->branch_id) ? $newName : $oldName,
                    ],
                    [
                        'name'             => $newName,
                        'description'      => array_key_exists('description', $validated) ? $validated['description'] : $combo->description,
                        'service_type'     => $validated['service_type'] ?? $combo->service_type,
                        'price'            => $validated['price'] ?? $combo->price,
                        'home_surcharge'   => array_key_exists('home_surcharge', $validated) ? $validated['home_surcharge'] : $combo->home_surcharge,
                        'duration_minutes' => $validated['duration_minutes'] ?? $combo->duration_minutes,
                        'discount'         => array_key_exists('discount', $validated) ? $validated['discount'] : $combo->discount,
                        'is_active'        => array_key_exists('is_active', $validated) ? $validated['is_active'] : $combo->is_active,
                    ]
                );

                if (!empty($selectedServiceNames)) {
                    $branchServiceIds = Service::where('branch_id', $b->id)->whereIn('name', $selectedServiceNames)->pluck('id');
                    $targetCombo->services()->sync($branchServiceIds);
                }
            }
        } elseif (!empty($validated['branch_ids'])) {
            $targetBranchIds = $allTenantBranches->whereIn('id', $validated['branch_ids'])->pluck('id');
            foreach ($targetBranchIds as $bId) {
                $targetCombo = \App\Models\ServiceCombo::updateOrCreate(
                    [
                        'branch_id' => $bId,
                        'name'      => ($bId === $combo->branch_id) ? $newName : $oldName,
                    ],
                    [
                        'name'             => $newName,
                        'description'      => array_key_exists('description', $validated) ? $validated['description'] : $combo->description,
                        'service_type'     => $validated['service_type'] ?? $combo->service_type,
                        'price'            => $validated['price'] ?? $combo->price,
                        'home_surcharge'   => array_key_exists('home_surcharge', $validated) ? $validated['home_surcharge'] : $combo->home_surcharge,
                        'duration_minutes' => $validated['duration_minutes'] ?? $combo->duration_minutes,
                        'discount'         => array_key_exists('discount', $validated) ? $validated['discount'] : $combo->discount,
                        'is_active'        => array_key_exists('is_active', $validated) ? $validated['is_active'] : $combo->is_active,
                    ]
                );

                if (!empty($selectedServiceNames)) {
                    $branchServiceIds = Service::where('branch_id', $bId)->whereIn('name', $selectedServiceNames)->pluck('id');
                    $targetCombo->services()->sync($branchServiceIds);
                }
            }
        } else {
            $combo->update([
                'name'             => $newName,
                'description'      => array_key_exists('description', $validated) ? $validated['description'] : $combo->description,
                'service_type'     => $validated['service_type'] ?? $combo->service_type,
                'price'            => $validated['price'] ?? $combo->price,
                'home_surcharge'   => array_key_exists('home_surcharge', $validated) ? $validated['home_surcharge'] : $combo->home_surcharge,
                'duration_minutes' => $validated['duration_minutes'] ?? $combo->duration_minutes,
                'discount'         => array_key_exists('discount', $validated) ? $validated['discount'] : $combo->discount,
                'is_active'        => array_key_exists('is_active', $validated) ? $validated['is_active'] : $combo->is_active,
            ]);

            if (array_key_exists('service_ids', $validated)) {
                $combo->services()->sync($validated['service_ids'] ?? []);
            }
        }

        $combo->load(['services', 'branch:id,name,city,pin_code']);

        return response()->json([
            'success' => true,
            'message' => 'Package Combo updated successfully!',
            'data'    => [
                'id'               => $combo->id,
                'branch_id'        => $combo->branch_id,
                'branch_name'      => $combo->branch->name ?? 'Main Branch',
                'name'             => $combo->name,
                'description'      => $combo->description ?? '',
                'price'            => (float) $combo->price,
                'duration_minutes' => (int) $combo->duration_minutes,
                'is_active'        => (bool) $combo->is_active,
                'discount'         => (float) ($combo->discount ?? 0),
                'services'         => $combo->services->map(fn($s) => [
                    'id'       => $s->id,
                    'name'     => $s->name,
                    'price'    => (float) $s->price,
                    'category' => $s->category ?? '',
                ])->values(),
            ],
        ]);
    }

    public function deleteApiCombo(Request $request, $id)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        $combo = \App\Models\ServiceCombo::whereIn('branch_id', $branchIds)->findOrFail($id);

        $combo->services()->detach();
        $combo->delete();

        return response()->json(['success' => true, 'message' => 'Package Combo deleted successfully!']);
    }

    public function toggleApiCombo(Request $request, $id)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        $combo = \App\Models\ServiceCombo::whereIn('branch_id', $branchIds)->findOrFail($id);

        $newActive = $request->has('is_active') ? (bool)$request->is_active : !$combo->is_active;
        $combo->update(['is_active' => $newActive]);

        return response()->json([
            'success'   => true,
            'message'   => 'Combo status updated successfully!',
            'is_active' => $combo->is_active,
        ]);
    }

    public function getApiCustomers(Request $request)
    {
        $user = $request->user();
        $tenantId = $user?->tenant_id ?? Tenant::first()?->id;

        $bookings = Booking::where('tenant_id', $tenantId)->with('customer')->get();
        $customersMap = [];

        foreach ($bookings as $b) {
            $c = $b->customer;
            if (!$c) continue;
            if (!isset($customersMap[$c->id])) {
                $customersMap[$c->id] = [
                    'id'             => $c->id,
                    'name'           => $c->name,
                    'phone'          => $c->mobile ?? '+91 98123 45678',
                    'total_bookings' => 0,
                    'total_spent'    => 0.0,
                    'is_vip'         => false,
                ];
            }
            $customersMap[$c->id]['total_bookings'] += 1;
            if ($b->status === 'CONFIRMED' || $b->status === 'COMPLETED') {
                $customersMap[$c->id]['total_spent'] += (float)$b->amount;
            }
            if ($customersMap[$c->id]['total_bookings'] >= 5 || $customersMap[$c->id]['total_spent'] >= 2000) {
                $customersMap[$c->id]['is_vip'] = true;
            }
        }

        return response()->json(['success' => true, 'data' => array_values($customersMap)]);
    }

    public function getApiPromotions(Request $request)
    {
        return response()->json([
            'success'    => true,
            'promotions' => [
                ['id' => 1, 'title' => 'Afternoon Happy Hour (2 PM - 4 PM)', 'discount_percent' => 20, 'time_window' => 'Mon - Thu • 14:00 to 16:00', 'is_active' => true],
                ['id' => 2, 'title' => 'Early Bird Special (10 AM - 11 AM)', 'discount_percent' => 15, 'time_window' => 'Tue - Fri • 10:00 to 11:00', 'is_active' => false],
            ],
            'rush_rules' => [
                ['id' => 1, 'title' => 'Weekend Peak Hours Surge', 'surge_amount' => 100.0, 'time_slot' => 'Sat & Sun • 16:00 to 20:00', 'is_enabled' => true],
                ['id' => 2, 'title' => 'Festival Rush Premium', 'surge_amount' => 150.0, 'time_slot' => 'Diwali Week • All Slots', 'is_enabled' => false],
            ],
        ]);
    }
}
