<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Service;
use App\Models\Staff;
use App\Models\Tenant;
use App\Models\TenantCustomer;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\FcmService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    /**
     * Get bookings for the authenticated user (Owner sees all shop bookings; Staff sees ONLY their assigned bookings).
     */
    public function ownerBookings(Request $request)
    {
        $user = $request->user();
        $tenantId = $user->tenant_id;
        
        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated.'], 404);
        }

        $query = Booking::where('tenant_id', $tenantId)
            ->with(['user:id,name,email,mobile', 'service:id,name,price,duration_minutes', 'staff:id,name,role']);

        // 🛑 STAFF RBAC GUARD: Staff members ONLY see their own assigned bookings
        $isStaff = $user->hasRole('STAFF') || Staff::where('user_id', $user->id)->exists();
        if ($isStaff) {
            $staffRecord = Staff::where('user_id', $user->id)->first();
            if ($staffRecord) {
                $query->where('staff_id', $staffRecord->id);
            }
        }

        $bookings = $query->latest('booking_date')
            ->latest('start_time')
            ->get();

        return response()->json([
            'success' => true,
            'is_staff' => $isStaff,
            'data' => $bookings,
        ]);
    }

    /**
     * Get today's time slot schedule — booked and available slots per staff member.
     * Returns 30-min intervals from 09:00 to 20:00 for each bookable staff.
     */
    public function todaySlots(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id;

        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No salon tenant associated with this account.'], 404);
        }

        $today = now()->toDateString();

        $branchIds = \App\Models\Branch::where('tenant_id', $tenantId)->pluck('id');
        $staffQuery = \App\Models\Staff::whereIn('branch_id', $branchIds)
            ->where('is_bookable', true);

        // 🛑 STAFF RBAC: If a staff member is requesting, ONLY return their own schedule
        $isStaff = $user->hasRole('STAFF') || \App\Models\Staff::where('user_id', $user->id)->exists();
        if ($isStaff) {
            $staffRecord = \App\Models\Staff::where('user_id', $user->id)->first();
            if ($staffRecord) {
                $staffQuery->where('id', $staffRecord->id);
            }
        }

        $staffList = $staffQuery->get(['id', 'name', 'role']);

        // Get all bookings for today
        $todayBookings = Booking::where('tenant_id', $tenantId)
            ->whereDate('booking_date', $today)
            ->whereIn('status', ['CONFIRMED', 'PENDING', 'LOCKED'])
            ->with(['user:id,name,mobile', 'service:id,name,price,duration_minutes', 'staff:id,name'])
            ->get();

        // Build 30-min slots from 09:00 to 20:00
        $slotTimes = [];
        $start = strtotime('09:00');
        $end   = strtotime('20:00');
        for ($t = $start; $t < $end; $t += 1800) {
            $slotTimes[] = date('H:i', $t);
        }

        $schedule = [];
        foreach ($staffList as $staff) {
            $staffBookings = $todayBookings->where('staff_id', $staff->id)->values();

            $slots = [];
            foreach ($slotTimes as $time) {
                $slotStart = strtotime($time);
                $slotEnd   = $slotStart + 1800;

                // Check if any booking occupies this slot
                $booking = $staffBookings->first(function ($b) use ($slotStart, $slotEnd) {
                    $bStart = strtotime($b->start_time);
                    $bEnd   = $b->end_time ? strtotime($b->end_time) : ($bStart + ($b->service?->duration_minutes ?? 30) * 60);
                    return $bStart < $slotEnd && $bEnd > $slotStart;
                });

                $slots[] = [
                    'time'     => $time,
                    'is_booked' => $booking !== null,
                    'booking'  => $booking ? [
                        'id'            => $booking->id,
                        'customer_name' => $booking->user?->name ?? 'Walk-in Client',
                        'customer_phone'=> $booking->user?->mobile ?? '',
                        'service_name'  => $booking->service?->name ?? 'Salon Service',
                        'amount'        => number_format((float)$booking->amount, 2),
                        'status'        => $booking->status,
                        'start_time'    => $booking->start_time,
                        'end_time'      => $booking->end_time,
                    ] : null,
                ];
            }

            $schedule[] = [
                'staff_id'   => $staff->id,
                'staff_name' => $staff->name,
                'staff_role' => $staff->role,
                'slots'      => $slots,
                'booked_count'    => collect($slots)->where('is_booked', true)->count(),
                'available_count' => collect($slots)->where('is_booked', false)->count(),
            ];
        }

        return response()->json([
            'success'  => true,
            'date'     => $today,
            'schedule' => $schedule,
        ]);
    }

    /**
     * Lock a time slot for 5 minutes during the checkout process.
     */
    public function lockSlot(Request $request)
    {
        $validated = $request->validate([
            'branch_id' => 'required|exists:branches,id',
            'service_id' => 'required|exists:services,id',
            'staff_id' => 'required|exists:staff,id',
            'date' => 'required|date_format:Y-m-d',
            'time' => 'required|date_format:H:i',
            'booking_type' => 'nullable|in:IN_STUDIO,AT_HOME,EVENT_WEDDING',
            'service_address' => 'nullable|string',
            'address_landmark' => 'nullable|string',
            'occasion_type' => 'nullable|string',
            'travel_fee' => 'nullable|numeric',
            'combo_id' => 'nullable|integer',
        ]);

        $user = $request->user();

        // 🛡️ 1. Anti-Abuse Guard: Cap active PENDING/LOCKED bookings to max 3 per user
        $activeUserBookingsCount = Booking::where('user_id', $user->id)
            ->whereIn('status', ['PENDING', 'LOCKED'])
            ->where(function ($q) {
                $q->whereNull('lock_expires_at')
                  ->orWhere('lock_expires_at', '>', now());
            })
            ->count();

        if ($activeUserBookingsCount >= 3) {
            return response()->json([
                'success' => false,
                'message' => '🛡️ Anti-Abuse Protection: You already have 3 active pending/locked bookings. Please wait for approval before creating another.',
            ], 429);
        }

        // 🛡️ 2. Cool-Down Anti-Spam Guard: Prevent rapid spam requests within 10 seconds
        $recentBooking = Booking::where('user_id', $user->id)
            ->where('created_at', '>=', now()->subSeconds(10))
            ->first();

        if ($recentBooking) {
            return response()->json([
                'success' => false,
                'message' => '⏱️ Anti-Spam Guard: Please wait 10 seconds before submitting another booking request.',
            ], 429);
        }

        $service = Service::findOrFail($validated['service_id']);
        $tenant = $service->branch->tenant;
        $tenantId = $tenant->id;

        if (in_array($tenant->status, ['EMERGENCY_CLOSED', 'OFFLINE', 'SUSPENDED_FOR_DELETION'])) {
            return response()->json([
                'success' => false,
                'message' => "Booking Denied: '{$tenant->business_name}' is currently offline (bookings paused by owner). Please try again later.",
            ], 422);
        }

        // 🔒 3. 3-Strike Consecutive Decline Guard: Prevent spam to shop if last 3 bookings were declined
        $declineLimit = $tenant->consecutive_declines_limit ?? 3;
        $recentStatuses = Booking::where('user_id', $user->id)
            ->where('tenant_id', $tenantId)
            ->latest()
            ->take($declineLimit)
            ->pluck('status')
            ->toArray();

        if (count($recentStatuses) >= $declineLimit && collect($recentStatuses)->every(fn($s) => $s === 'DECLINED')) {
            $contactPhone = $service->branch->contact_mobile ?? '+91 98765 43210';
            return response()->json([
                'success' => false,
                'strike_blocked' => true,
                'message' => "🚫 Booking Notice: Your previous {$declineLimit} booking requests were declined by '{$tenant->business_name}'. To schedule an appointment without delay, please call the salon directly at {$contactPhone}.",
            ], 403);
        }

        // 🔒 CRM-Only Mode Guard: If crm_only_booking is enabled, reject users who are NOT in the shop's CRM directory
        $userMobile = $user->mobile ? preg_replace('/[^\d]/', '', $user->mobile) : null;
        $userMobile10 = $userMobile ? (strlen($userMobile) > 10 ? substr($userMobile, -10) : $userMobile) : null;

        $inCrm = TenantCustomer::where('tenant_id', $tenantId)
            ->where(function ($q) use ($user, $userMobile10) {
                $q->where('user_id', $user->id);
                if ($userMobile10) {
                    $q->orWhere('phone', 'like', "%{$userMobile10}%");
                }
            })
            ->exists();

        if ($tenant->crm_only_booking && !$inCrm) {
            return response()->json([
                'success' => false,
                'crm_blocked' => true,
                'message' => "'{$tenant->business_name}' currently accepts bookings only from their registered CRM clients. Please contact the shop directly to be added.",
            ], 403);
        }

        $startDatetime = Carbon::parse($validated['date'] . ' ' . $validated['time']);
        $endDatetime = $startDatetime->copy()->addMinutes($service->duration_minutes);
        $travelFee = isset($validated['travel_fee']) ? (float)$validated['travel_fee'] : 0.00;
        $totalAmount = (float)$service->price + $travelFee;

        // 🔒 4. Concurrency Lock: Use DB Transaction to guarantee atomic ACID isolation during high concurrency (10-15+ bookings at once)
        return DB::transaction(function () use ($validated, $tenantId, $service, $startDatetime, $endDatetime, $user, $travelFee, $totalAmount, $inCrm, $tenant) {
            $startTime = $startDatetime->format('H:i:s');
            $endTime = $endDatetime->format('H:i:s');

            $conflict = Booking::where('staff_id', $validated['staff_id'])
                ->where('booking_date', $validated['date'])
                ->where(function ($query) use ($startTime, $endTime) {
                    $query->where(function ($q) use ($startTime, $endTime) {
                        $q->where('start_time', '<', $endTime)
                          ->where('end_time', '>', $startTime);
                    });
                })
                ->where(function ($query) {
                    $query->where('status', 'CONFIRMED')
                          ->orWhere(function ($q) {
                              $q->where('status', 'LOCKED')
                                ->where('lock_expires_at', '>', now());
                          });
                })
                ->lockForUpdate()
                ->exists();

            if ($conflict) {
                return response()->json([
                    'success' => false,
                    'message' => '⚠️ Slot Conflict: This slot was just reserved by another client milliseconds ago. Please select a different time slot.',
                ], 409);
            }

            $bookingType = $validated['booking_type'] ?? 'IN_STUDIO';
            $policy = $tenant->booking_policy ?? 'PAY_AT_SALON';

            $booking = Booking::create([
                'tenant_id' => $tenantId,
                'branch_id' => $validated['branch_id'],
                'service_id' => $validated['service_id'],
                'staff_id' => $validated['staff_id'],
                'user_id' => $user->id,
                'combo_id' => $validated['combo_id'] ?? null,
                'booking_type' => $bookingType,
                'service_address' => $validated['service_address'] ?? null,
                'address_landmark' => $validated['address_landmark'] ?? null,
                'occasion_type' => $validated['occasion_type'] ?? null,
                'travel_fee' => $travelFee,
                'amount' => $totalAmount,
                'booking_date' => $validated['date'],
                'start_time' => $startTime,
                'end_time' => $endTime,
                'status' => 'LOCKED',
                'lock_expires_at' => now()->addMinutes(5),
                'payment_status' => 'PENDING',
            ]);

        // STORE PENDING OFFLINE NOTIFICATION FOR OWNER & ASSIGNED STAFF
        try {
            $customerName = $request->user()->name ?? 'Customer';
            $serviceName = $service->name ?? 'Salon Service';
            $formattedTime = $startDatetime->format('h:i A');

            // 1. Owner User Notification & FCM
            $tenant = Tenant::find($tenantId);
            $ownerUsers = User::where('tenant_id', $tenantId)
                ->whereHas('roles', function ($q) { $q->where('name', 'OWNER'); })
                ->get();

            foreach ($ownerUsers as $owner) {
                UserNotification::create([
                    'user_id' => $owner->id,
                    'tenant_id' => $tenantId,
                    'title' => "💈 New Booking Request from {$customerName}!",
                    'body' => "{$customerName} requested {$serviceName} for {$formattedTime} today.",
                    'type' => 'BOOKING_REQUEST',
                    'data' => [
                        'booking_id' => (string)$booking->id,
                        'customer_name' => $customerName,
                        'service_name' => $serviceName,
                        'original_time' => $formattedTime,
                        'amount' => (string)$service->price,
                    ],
                ]);

                if (!empty($owner->fcm_token)) {
                    FcmService::send(
                        $owner->fcm_token,
                        "💈 New Booking Request from {$customerName}!",
                        "{$customerName} requested {$serviceName} for {$formattedTime} today. Tap to Accept, Decline, or Shift Time.",
                        [
                            'type' => 'BOOKING_REQUEST',
                            'booking_id' => (string)$booking->id,
                            'customer_name' => $customerName,
                            'service_name' => $serviceName,
                            'original_time' => $formattedTime,
                            'amount' => (string)$service->price,
                            'target_user_id' => (string)$owner->id,
                            'target_tenant_id' => (string)$tenantId,
                        ]
                    );
                }
            }

            // 2. Staff User Notification & FCM (if staff has login user_id)
            $staffObj = Staff::find($validated['staff_id']);
            if ($staffObj && $staffObj->user_id) {
                $staffUser = User::find($staffObj->user_id);
                if ($staffUser) {
                    UserNotification::create([
                        'user_id' => $staffUser->id,
                        'tenant_id' => $tenantId,
                        'title' => "✂️ New Appointment Assigned to You!",
                        'body' => "You have a new appointment with {$customerName} for {$serviceName} at {$formattedTime}.",
                        'type' => 'STAFF_ASSIGNMENT',
                        'data' => [
                            'booking_id' => (string)$booking->id,
                            'customer_name' => $customerName,
                            'service_name' => $serviceName,
                            'original_time' => $formattedTime,
                        ],
                    ]);

                    if (!empty($staffUser->fcm_token)) {
                        FcmService::send(
                            $staffUser->fcm_token,
                            "✂️ New Appointment Assigned to You!",
                            "You have a new appointment with {$customerName} for {$serviceName} at {$formattedTime}.",
                            [
                                'type' => 'STAFF_ASSIGNMENT',
                                'booking_id' => (string)$booking->id,
                                'customer_name' => $customerName,
                                'service_name' => $serviceName,
                                'original_time' => $formattedTime,
                                'target_user_id' => (string)$staffUser->id,
                                'target_tenant_id' => (string)$tenantId,
                            ]
                        );
                    }
                }
            }
        } catch (\Exception $e) {}

        return response()->json(['success' => true, 'data' => $booking]);
    });
}

    /**
     * Confirm a booking
     */
    public function confirm(Request $request)
    {
        $validated = $request->validate([
            'booking_id' => 'required|exists:bookings,id',
        ]);

        $booking = Booking::findOrFail($validated['booking_id']);

        if ($booking->status === 'CONFIRMED') {
            return response()->json(['success' => true, 'data' => $booking]);
        }

        if ($booking->status === 'LOCKED' && $booking->lock_expires_at < now()) {
            return response()->json(['success' => false, 'message' => 'Booking lock expired'], 400);
        }

        $booking->update([
            'status' => 'CONFIRMED',
            'payment_status' => 'PAID',
        ]);

        $existingLedger = \App\Models\TenantLedger::where('booking_id', $booking->id)->exists();
        if (!$existingLedger) {
            \App\Models\TenantLedger::create([
                'tenant_id' => $booking->tenant_id,
                'booking_id' => $booking->id,
                'amount' => 1.00,
                'type' => 'DEBIT',
                'description' => "Glamora SaaS Booking Fee - Booking #{$booking->id} (" . ($booking->service->name ?? 'Salon Service') . ")",
                'status' => 'PENDING'
            ]);
        }

        return response()->json(['success' => true, 'data' => $booking]);
    }

    /**
     * Owner / Staff Action: Respond to booking (Accept, Decline, or Add Extra Time / Shift Minutes)
     */
    public function respondBooking(Request $request, $id)
    {
        $validated = $request->validate([
            'action' => 'required|in:ACCEPT,DECLINE,ADD_TIME',
            'delay_minutes' => 'nullable',
        ]);

        $booking = Booking::with(['user', 'service', 'tenant'])->find($id);
        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking record not found.'], 404);
        }

        $action = strtoupper($validated['action']);
        $delayMinutes = isset($validated['delay_minutes']) ? (int)$validated['delay_minutes'] : 0;

        $origStart = Carbon::parse($booking->booking_date . ' ' . $booking->start_time);
        $origEnd = Carbon::parse($booking->booking_date . ' ' . $booking->end_time);

        if ($action === 'ACCEPT' || $action === 'ADD_TIME') {
            if ($delayMinutes > 0) {
                $newStart = $origStart->copy()->addMinutes($delayMinutes);
                $newEnd = $origEnd->copy()->addMinutes($delayMinutes);

                $booking->start_time = $newStart->format('H:i:s');
                $booking->end_time = $newEnd->format('H:i:s');
            }

            $booking->status = 'CONFIRMED';
            $booking->save();

            $newFormattedTime = Carbon::parse($booking->booking_date . ' ' . $booking->start_time)->format('h:i A');
            $shopName = $booking->tenant->business_name ?? 'The Salon';

            // Send notification to customer
            if ($booking->user) {
                UserNotification::create([
                    'user_id' => $booking->user->id,
                    'tenant_id' => $booking->tenant_id,
                    'title' => "🎉 Booking Confirmed at {$shopName}!",
                    'body' => $delayMinutes > 0 
                        ? "Your appointment for {$booking->service->name} has been shifted to {$newFormattedTime} (+{$delayMinutes} mins)."
                        : "Your appointment for {$booking->service->name} at {$newFormattedTime} has been accepted!",
                    'type' => 'BOOKING_CONFIRMATION',
                ]);

                if (!empty($booking->user->fcm_token)) {
                    FcmService::send(
                        $booking->user->fcm_token,
                        "🎉 Booking Confirmed at {$shopName}!",
                        $delayMinutes > 0 
                            ? "Your appointment for {$booking->service->name} has been shifted to {$newFormattedTime} (+{$delayMinutes} mins)."
                            : "Your appointment for {$booking->service->name} at {$newFormattedTime} has been accepted!",
                        [
                            'type' => 'BOOKING_UPDATE',
                            'booking_id' => (string)$booking->id,
                            'status' => 'CONFIRMED',
                            'confirmed_time' => $newFormattedTime,
                        ]
                    );
                }
            }

            $msg = $delayMinutes > 0
                ? "Booking confirmed and shifted by +{$delayMinutes} mins to {$newFormattedTime}!"
                : "Booking confirmed successfully!";

            return response()->json(['success' => true, 'message' => $msg, 'data' => $booking]);
        } else {
            $booking->status = 'CANCELLED';
            $booking->save();

            if ($booking->user) {
                UserNotification::create([
                    'user_id' => $booking->user->id,
                    'tenant_id' => $booking->tenant_id,
                    'title' => "❌ Booking Request Declined",
                    'body' => "Your booking request for {$booking->service->name} was declined by the salon.",
                    'type' => 'BOOKING_DECLINED',
                ]);

                if (!empty($booking->user->fcm_token)) {
                    FcmService::send(
                        $booking->user->fcm_token,
                        "❌ Booking Request Declined",
                        "Your booking request for {$booking->service->name} was declined by the salon.",
                        [
                            'type' => 'BOOKING_UPDATE',
                            'booking_id' => (string)$booking->id,
                            'status' => 'CANCELLED',
                        ]
                    );
                }
            }

            return response()->json(['success' => true, 'message' => 'Booking declined.', 'data' => $booking]);
        }
    }

    /**
     * Customer App: Get authenticated user's upcoming and past bookings.
     */
    public function customerBookings(Request $request)
    {
        $user = $request->user();
        $bookings = Booking::where('user_id', $user->id)
            ->with(['tenant', 'branch', 'service', 'staff', 'combo'])
            ->latest('booking_date')
            ->latest('start_time')
            ->get();

        $now = Carbon::now('Asia/Kolkata');

        $formatted = $bookings->map(function ($b) use ($now) {
            $tenant = $b->tenant;
            $bufferMins = (int)($tenant?->cancellation_buffer_minutes ?? 120);
            $appointmentTime = Carbon::parse($b->booking_date . ' ' . $b->start_time, 'Asia/Kolkata');
            $cancellationCutoff = $appointmentTime->copy()->subMinutes($bufferMins);

            $canCancel = in_array($b->status, ['PENDING', 'LOCKED', 'CONFIRMED']) && $now->lt($cancellationCutoff);
            $bufferLabel = $bufferMins >= 60 ? ($bufferMins / 60) . ' hour(s)' : "{$bufferMins} mins";

            return [
                'id' => $b->id,
                'tenant_id' => $b->tenant_id,
                'salon_name' => $tenant?->business_name ?? 'Salon Partner',
                'salon_phone' => $b->branch?->contact_mobile ?? '+91 98765 43210',
                'branch_name' => $b->branch?->name ?? 'Main Branch',
                'branch_address' => $b->branch?->address ?? '',
                'service_name' => $b->service?->name ?? ($b->combo?->name ?? 'Salon Service'),
                'staff_name' => $b->staff?->name ?? 'Assigned Stylist',
                'booking_type' => $b->booking_type ?? 'IN_STUDIO',
                'service_address' => $b->service_address ?? '',
                'address_landmark' => $b->address_landmark ?? '',
                'occasion_type' => $b->occasion_type ?? '',
                'booking_date' => $b->booking_date,
                'start_time' => $b->start_time,
                'end_time' => $b->end_time,
                'amount' => (float)$b->amount,
                'travel_fee' => (float)($b->travel_fee ?? 0.00),
                'status' => $b->status,
                'payment_status' => $b->payment_status,
                'can_cancel' => $canCancel,
                'cancellation_buffer_minutes' => $bufferMins,
                'cancellation_policy_text' => "Free cancellation up to {$bufferLabel} before appointment.",
                'created_at' => $b->created_at?->toIso8601String(),
            ];
        });

        $upcoming = $formatted->filter(function ($b) use ($now) {
            $appointmentTime = Carbon::parse($b['booking_date'] . ' ' . $b['start_time'], 'Asia/Kolkata');
            return $appointmentTime->gte($now->copy()->startOfDay()) && in_array($b['status'], ['PENDING', 'LOCKED', 'CONFIRMED']);
        })->values();

        $past = $formatted->filter(function ($b) use ($now) {
            $appointmentTime = Carbon::parse($b['booking_date'] . ' ' . $b['start_time'], 'Asia/Kolkata');
            return $appointmentTime->lt($now->copy()->startOfDay()) || in_array($b['status'], ['COMPLETED', 'DECLINED', 'CANCELLED']);
        })->values();

        return response()->json([
            'success' => true,
            'upcoming' => $upcoming,
            'past' => $past,
            'all' => $formatted,
        ]);
    }

    /**
     * Customer App: Cancel booking if within salon's allowable cancellation window.
     */
    public function customerCancelBooking(Request $request, $id)
    {
        $user = $request->user();
        $booking = Booking::with(['tenant', 'branch', 'service', 'staff'])
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking not found.'], 404);
        }

        if (!in_array($booking->status, ['PENDING', 'LOCKED', 'CONFIRMED'])) {
            return response()->json(['success' => false, 'message' => "Booking is already {$booking->status}."], 422);
        }

        $now = Carbon::now('Asia/Kolkata');
        $tenant = $booking->tenant;
        $bufferMins = (int)($tenant?->cancellation_buffer_minutes ?? 120);
        $appointmentTime = Carbon::parse($booking->booking_date . ' ' . $booking->start_time, 'Asia/Kolkata');
        $cancellationCutoff = $appointmentTime->copy()->subMinutes($bufferMins);

        if ($now->gte($cancellationCutoff)) {
            $bufferLabel = $bufferMins >= 60 ? ($bufferMins / 60) . ' hour(s)' : "{$bufferMins} mins";
            return response()->json([
                'success' => false,
                'message' => "Cancellation deadline expired: As per salon policy, cancellations must be made at least {$bufferLabel} before the appointment. Please contact the salon directly.",
            ], 422);
        }

        $booking->update([
            'status' => 'CANCELLED',
            'decline_reason' => 'Cancelled by Customer via App',
        ]);

        // Send push & in-app notification to Owner
        try {
            $customerName = $user->name ?? 'Customer';
            $serviceName = $booking->service?->name ?? 'Service';
            $formattedTime = Carbon::parse($booking->booking_date . ' ' . $booking->start_time)->format('h:i A, M d');

            $ownerUsers = User::where('tenant_id', $booking->tenant_id)
                ->whereHas('roles', function ($q) { $q->where('name', 'OWNER'); })
                ->get();

            foreach ($ownerUsers as $owner) {
                UserNotification::create([
                    'user_id' => $owner->id,
                    'tenant_id' => $booking->tenant_id,
                    'title' => "⚠️ Appointment Cancelled by {$customerName}",
                    'body' => "{$customerName} cancelled their appointment for {$serviceName} scheduled at {$formattedTime}.",
                    'type' => 'BOOKING_CANCELLED',
                    'data' => [
                        'booking_id' => (string)$booking->id,
                        'customer_name' => $customerName,
                        'service_name' => $serviceName,
                    ],
                ]);

                if (!empty($owner->fcm_token)) {
                    FcmService::send(
                        $owner->fcm_token,
                        "⚠️ Appointment Cancelled by {$customerName}",
                        "{$customerName} cancelled their appointment for {$serviceName} scheduled at {$formattedTime}.",
                        [
                            'type' => 'BOOKING_CANCELLED',
                            'booking_id' => (string)$booking->id,
                        ]
                    );
                }
            }
        } catch (\Exception $e) {}

        return response()->json([
            'success' => true,
            'message' => 'Booking has been cancelled successfully.',
            'data' => $booking,
        ]);
    }
}

