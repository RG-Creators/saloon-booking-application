<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Tenant;
use App\Models\TenantCustomer;
use App\Models\User;
use Illuminate\Http\Request;

class CrmController extends Controller
{
    private function getTenantId(Request $request): int
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        return (int) ($user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id ?? 1);
    }

    private function cleanPhone(string $phone): string
    {
        $digits = preg_replace('/[^\d]/', '', $phone);
        if (strlen($digits) > 10) {
            return substr($digits, -10);
        }
        return $digits;
    }

    /**
     * Get CRM customer directory with full booking analytics.
     */
    public function index(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $customers = TenantCustomer::where('tenant_id', $tenantId)
            ->with('user')
            ->orderBy('id', 'desc')
            ->get();

        // Calculate dynamic real-time stats for each CRM customer
        $crmList = $customers->map(function ($tc) use ($tenantId) {
            $cleanPhone = $tc->phone ? $this->cleanPhone($tc->phone) : '';

            $userBookings = Booking::where('tenant_id', $tenantId)
                ->where(function ($q) use ($tc, $cleanPhone) {
                    if ($tc->user_id) {
                        $q->where('user_id', $tc->user_id);
                    }
                    if ($cleanPhone) {
                        $q->orWhere('customer_phone', 'like', "%{$cleanPhone}%");
                    }
                })
                ->get();

            $bookingCount = $userBookings->count();
            $spent = (float) $userBookings->whereIn('status', ['COMPLETED', 'CONFIRMED'])->sum('amount');
            $isVip = $tc->is_vip || $bookingCount >= 5 || $spent >= 2000;

            return [
                'id'             => $tc->id,
                'user_id'        => $tc->user_id,
                'name'           => $tc->name ?: ($tc->user?->name ?? 'Valued Client'),
                'phone'          => $tc->phone ?: ($tc->user?->mobile ?? '+91 98765 43210'),
                'email'          => $tc->email ?: ($tc->user?->email ?? ''),
                'gender'         => $tc->gender ?? '',
                'notes'          => $tc->notes ?? '',
                'is_vip'         => (bool) $isVip,
                'total_bookings' => $bookingCount,
                'total_spent'    => $spent,
                'source'         => $tc->source ?? 'MANUAL',
                'created_at'     => $tc->created_at?->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'count'   => $crmList->count(),
            'data'    => $crmList,
        ]);
    }

    /**
     * Look up a customer by Phone Number from server users / past bookings.
     */
    public function lookup(Request $request)
    {
        $tenantId = $this->getTenantId($request);
        $rawPhone = $request->input('phone', '');
        $clean = $this->cleanPhone($rawPhone);

        if (empty($clean) || strlen($clean) < 7) {
            return response()->json([
                'success' => false,
                'message' => 'Please provide a valid phone number (at least 7 digits).',
            ], 422);
        }

        // 1. Check if already in CRM directory
        $existingCrm = TenantCustomer::where('tenant_id', $tenantId)
            ->where('phone', 'like', "%{$clean}%")
            ->first();

        // 2. Check if registered user exists on the server platform
        $serverUser = User::where('mobile', 'like', "%{$clean}%")
            ->orWhere('email', 'like', "%{$clean}%")
            ->first();

        // 3. Check past bookings for this phone number
        $pastBookings = Booking::where('tenant_id', $tenantId)
            ->where(function ($q) use ($clean, $serverUser) {
                $q->where('customer_phone', 'like', "%{$clean}%");
                if ($serverUser) {
                    $q->orWhere('user_id', $serverUser->id);
                }
            })
            ->get();

        $bookingCount = $pastBookings->count();
        $totalSpent = (float) $pastBookings->whereIn('status', ['COMPLETED', 'CONFIRMED'])->sum('amount');
        $latestBooking = $pastBookings->sortByDesc('created_at')->first();

        $name = $existingCrm?->name ?? $serverUser?->name ?? $latestBooking?->customer_name ?? '';
        $email = $existingCrm?->email ?? $serverUser?->email ?? '';
        $isVip = $existingCrm?->is_vip || $bookingCount >= 5 || $totalSpent >= 2000;

        $found = ($serverUser !== null) || ($existingCrm !== null) || ($bookingCount > 0);

        return response()->json([
            'success'        => true,
            'found'          => $found,
            'already_in_crm' => ($existingCrm !== null),
            'crm_id'         => $existingCrm?->id,
            'customer'       => [
                'user_id'        => $serverUser?->id ?? $existingCrm?->user_id,
                'name'           => $name,
                'phone'          => $serverUser?->mobile ?? $rawPhone,
                'email'          => $email,
                'total_bookings' => $bookingCount,
                'total_spent'    => $totalSpent,
                'is_vip'         => (bool) $isVip,
                'notes'          => $existingCrm?->notes ?? '',
                'source'         => $serverUser ? 'SERVER_USER' : ($bookingCount > 0 ? 'PAST_BOOKINGS' : 'NEW'),
            ],
            'message'        => $found
                ? 'Customer details found and loaded successfully!'
                : 'Customer not found on server yet. You can pre-add this customer now.',
        ]);
    }

    /**
     * Add / Pre-add new Customer to CRM.
     */
    public function store(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $validated = $request->validate([
            'name'    => 'required|string|max:255',
            'phone'   => 'required|string|max:25',
            'email'   => 'nullable|email|max:255',
            'gender'  => 'nullable|string|max:20',
            'notes'   => 'nullable|string',
            'is_vip'  => 'nullable|boolean',
            'source'  => 'nullable|string',
        ]);

        $clean = $this->cleanPhone($validated['phone']);

        // Check if server user exists with this mobile
        $serverUser = User::where('mobile', 'like', "%{$clean}%")->first();

        // Calculate past bookings if any
        $pastBookings = Booking::where('tenant_id', $tenantId)
            ->where(function ($q) use ($clean, $serverUser) {
                $q->where('customer_phone', 'like', "%{$clean}%");
                if ($serverUser) {
                    $q->orWhere('user_id', $serverUser->id);
                }
            })
            ->get();

        $bookingCount = $pastBookings->count();
        $totalSpent = (float) $pastBookings->whereIn('status', ['COMPLETED', 'CONFIRMED'])->sum('amount');
        $isVip = ($request->boolean('is_vip')) || $bookingCount >= 5 || $totalSpent >= 2000;

        $customer = TenantCustomer::updateOrCreate(
            [
                'tenant_id' => $tenantId,
                'phone'     => $validated['phone'],
            ],
            [
                'user_id'        => $serverUser?->id,
                'name'           => $validated['name'],
                'email'          => $validated['email'] ?? $serverUser?->email,
                'gender'         => $validated['gender'] ?? null,
                'notes'          => $validated['notes'] ?? null,
                'is_vip'         => $isVip,
                'total_bookings' => $bookingCount,
                'total_spent'    => $totalSpent,
                'is_added'       => true,
                'source'         => $validated['source'] ?? ($serverUser ? 'SERVER_USER' : 'PRE_ADDED'),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Customer profile saved to CRM successfully!',
            'data'    => [
                'id'             => $customer->id,
                'user_id'        => $customer->user_id,
                'name'           => $customer->name,
                'phone'          => $customer->phone,
                'email'          => $customer->email ?? '',
                'gender'         => $customer->gender ?? '',
                'notes'          => $customer->notes ?? '',
                'is_vip'         => (bool) $customer->is_vip,
                'total_bookings' => $bookingCount,
                'total_spent'    => $totalSpent,
                'source'         => $customer->source,
            ],
        ], 201);
    }

    /**
     * Update existing Customer in CRM.
     */
    public function update(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $customer = TenantCustomer::where('tenant_id', $tenantId)->findOrFail($id);

        $validated = $request->validate([
            'name'   => 'sometimes|string|max:255',
            'phone'  => 'sometimes|string|max:25',
            'email'  => 'nullable|email|max:255',
            'gender' => 'nullable|string|max:20',
            'notes'  => 'nullable|string',
            'is_vip' => 'nullable|boolean',
        ]);

        if (isset($validated['phone'])) {
            $clean = $this->cleanPhone($validated['phone']);
            $serverUser = User::where('mobile', 'like', "%{$clean}%")->first();
            if ($serverUser) {
                $validated['user_id'] = $serverUser->id;
            }
        }

        $customer->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Customer updated successfully!',
            'data'    => $customer,
        ]);
    }

    /**
     * Get detailed booking history & profile for a specific customer.
     */
    public function showDetails(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $customer = TenantCustomer::where('tenant_id', $tenantId)->findOrFail($id);

        $months = (int) $request->input('months', 6);
        $startDate = $months > 0 ? now()->subMonths($months)->toDateString() : '2000-01-01';

        $cleanPhone = $customer->phone ? $this->cleanPhone($customer->phone) : '';

        $bookingsQuery = Booking::where('tenant_id', $tenantId)
            ->where(function ($q) use ($customer, $cleanPhone) {
                if ($customer->user_id) {
                    $q->where('user_id', $customer->user_id);
                }
                if ($cleanPhone) {
                    $q->orWhere('customer_phone', 'like', "%{$cleanPhone}%");
                }
            });

        $filteredBookings = (clone $bookingsQuery)
            ->whereDate('booking_date', '>=', $startDate)
            ->with(['service:id,name,price,duration_minutes', 'staff:id,name'])
            ->latest('booking_date')
            ->get();

        $allBookings = (clone $bookingsQuery)->get();
        $totalSpent = (float) $allBookings->whereIn('status', ['COMPLETED', 'CONFIRMED'])->sum('amount');
        $isVip = $customer->is_vip || $allBookings->count() >= 5 || $totalSpent >= 2000;

        return response()->json([
            'success'  => true,
            'customer' => [
                'id'             => $customer->id,
                'name'           => $customer->name,
                'email'          => $customer->email ?? 'No email',
                'mobile'         => $customer->phone ?? '+91 98765 43210',
                'gender'         => $customer->gender ?? 'Unspecified',
                'notes'          => $customer->notes ?? '',
                'is_vip'         => (bool) $isVip,
                'total_bookings' => $allBookings->count(),
                'total_spent'    => number_format($totalSpent, 2),
                'source'         => $customer->source ?? 'MANUAL',
            ],
            'filter_months' => $months,
            'history'       => $filteredBookings->map(fn($b) => [
                'id'           => $b->id,
                'service_name' => $b->service?->name ?? 'Custom Grooming',
                'staff_name'   => $b->staff?->name ?? 'Any Stylist',
                'amount'       => (float) $b->amount,
                'status'       => $b->status,
                'booking_date' => $b->booking_date ? (is_string($b->booking_date) ? $b->booking_date : $b->booking_date->toDateString()) : '',
                'start_time'   => $b->start_time ?? '10:00 AM',
            ]),
        ]);
    }

    /**
     * Remove customer from shop CRM.
     */
    public function destroy(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $customer = TenantCustomer::where('tenant_id', $tenantId)->findOrFail($id);
        $customer->delete();

        return response()->json([
            'success' => true,
            'message' => 'Customer removed from your CRM directory successfully.',
        ]);
    }

    /**
     * Get all past booking customers who are NOT currently in the CRM directory.
     */
    public function unaddedBookingClients(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $bookings = Booking::where('tenant_id', $tenantId)
            ->with(['customer', 'service', 'staff'])
            ->latest('created_at')
            ->get();

        $existingCrm = TenantCustomer::where('tenant_id', $tenantId)->get();

        $grouped = [];
        foreach ($bookings as $b) {
            $c = $b->customer;
            $phone = $c?->mobile ?? ($b->customer_phone ?? '');
            $clean = $phone ? $this->cleanPhone($phone) : '';
            if (empty($clean)) continue;

            $alreadyInCrm = $existingCrm->contains(function ($tc) use ($clean, $c) {
                $tcClean = $tc->phone ? $this->cleanPhone($tc->phone) : '';
                return ($tcClean === $clean) || ($c && $tc->user_id == $c->id);
            });

            // Only return customers who are NOT in CRM
            if (!$alreadyInCrm) {
                if (!isset($grouped[$clean])) {
                    $userBookings = $bookings->filter(function ($item) use ($clean, $c) {
                        $itemPhone = $item->customer?->mobile ?? ($item->customer_phone ?? '');
                        $itemClean = $itemPhone ? $this->cleanPhone($itemPhone) : '';
                        return ($itemClean === $clean) || ($c && $item->user_id == $c->id);
                    });

                    $grouped[$clean] = [
                        'user_id'        => $c?->id,
                        'name'           => $c?->name ?? $b->customer_name ?? 'Client',
                        'phone'          => $phone,
                        'email'          => $c?->email ?? '',
                        'last_service'   => $b->service?->name ?? 'Salon Service',
                        'total_bookings' => $userBookings->count(),
                        'total_spent'    => (float) $userBookings->whereIn('status', ['COMPLETED', 'CONFIRMED'])->sum('amount'),
                        'last_visit'     => $b->booking_date ? (is_string($b->booking_date) ? $b->booking_date : $b->booking_date->toDateString()) : '',
                    ];
                }
            }
        }

        return response()->json([
            'success' => true,
            'count'   => count($grouped),
            'data'    => array_values($grouped),
        ]);
    }

    /**
     * Batch add selected past booking clients to CRM.
     */
    public function batchAddBookingClients(Request $request)
    {
        $tenantId = $this->getTenantId($request);
        $clients = $request->input('clients', []);
        $addedCount = 0;

        foreach ($clients as $cData) {
            $name = $cData['name'] ?? 'Client';
            $phone = $cData['phone'] ?? '';
            if (empty($phone)) continue;

            $clean = $this->cleanPhone($phone);
            $serverUser = User::where('mobile', 'like', "%{$clean}%")->first();

            TenantCustomer::updateOrCreate(
                [
                    'tenant_id' => $tenantId,
                    'phone'     => $phone,
                ],
                [
                    'user_id'        => $serverUser?->id ?? ($cData['user_id'] ?? null),
                    'name'           => $name,
                    'email'          => $cData['email'] ?? $serverUser?->email,
                    'is_vip'         => !empty($cData['is_vip']),
                    'total_bookings' => (int) ($cData['total_bookings'] ?? 1),
                    'total_spent'    => (float) ($cData['total_spent'] ?? 0.0),
                    'source'         => 'PAST_BOOKINGS',
                ]
            );
            $addedCount++;
        }

        return response()->json([
            'success' => true,
            'message' => "Successfully added {$addedCount} customer(s) to your CRM directory!",
            'count'   => $addedCount,
        ]);
    }
}
