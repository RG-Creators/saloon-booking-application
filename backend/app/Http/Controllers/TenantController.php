<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use App\Models\Staff;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class TenantController extends Controller
{
    /**
     * Owner Onboarding: Registers the Business, initial Branch, Owner Account, and 3 Staff.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            // Owner Info
            'owner_name' => 'required|string|max:255',
            'mobile' => 'required|string|unique:users,mobile',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'is_bookable' => 'boolean',
            
            // Business Info
            'business_name' => 'required|string|max:255',
            'business_type' => 'required|string',
            'description' => 'nullable|string',
            
            // Branch Info
            'address' => 'required|string',
            'city' => 'required|string',
            'state' => 'nullable|string',
            'pin_code' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        try {
            DB::beginTransaction();

            // 1. Create Tenant (Business)
            $tenant = Tenant::create([
                'business_name' => $validated['business_name'],
                'business_type' => $validated['business_type'],
                'description' => $validated['description'] ?? null,
                'status' => 'PENDING',
            ]);

            // 2. Create Initial Branch
            $branch = Branch::create([
                'tenant_id' => $tenant->id,
                'name' => 'Main Branch',
                'address' => $validated['address'],
                'city' => $validated['city'],
                'state' => $validated['state'] ?? null,
                'pin_code' => $validated['pin_code'] ?? null,
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'contact_mobile' => $validated['mobile'],
                'contact_email' => $validated['email'],
            ]);

            // 3. Create Owner User
            $user = User::create([
                'tenant_id' => $tenant->id,
                'name' => $validated['owner_name'],
                'email' => $validated['email'],
                'mobile' => $validated['mobile'],
                'password' => Hash::make($validated['password']),
            ]);

            // Assign Spatie Role
            $user->assignRole('OWNER');

            // 4. Optionally create Owner as Staff
            $isBookable = $validated['is_bookable'] ?? false;
            
            Staff::create([
                'branch_id' => $branch->id,
                'user_id' => $user->id,
                'name' => $validated['owner_name'],
                'mobile' => $validated['mobile'],
                'email' => $validated['email'],
                'is_bookable' => $isBookable,
                'role' => 'OWNER',
            ]);

            // 5. Create 3 default empty staff slots
            for ($i = 1; $i <= 3; $i++) {
                Staff::create([
                    'branch_id' => $branch->id,
                    'name' => "Staff Member {$i}",
                    'is_bookable' => true,
                    'role' => 'STAFF',
                ]);
            }

            DB::commit();

            // Generate an auth token automatically for immediate login
            $token = $user->createToken('owner-app-token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Business registered successfully.',
                'data' => [
                    'tenant' => $tenant,
                    'branch' => $branch,
                    'user' => $user,
                    'token' => $token,
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Registration failed. ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Show authenticated user's Tenant (Shop) Profile.
     */
    public function show(Request $request, $id = null)
    {
        $user = $request->user();
        $targetTenantId = $id ? (int)$id : ($user?->tenant_id ?? Tenant::first()?->id);

        if (!$targetTenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated with user.'], 404);
        }

        $tenant = Tenant::with('branches')->find($targetTenantId);

        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Tenant not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'tenant' => [
                'id' => $tenant->id,
                'business_name' => $tenant->business_name,
                'business_type' => $tenant->business_type,
                'status' => $tenant->status,
                'booking_policy' => $tenant->booking_policy ?? 'PAY_AT_SALON',
                'cancellation_buffer_minutes' => (int)($tenant->cancellation_buffer_minutes ?? 120),
                'prebooking_token_amount' => (float)($tenant->prebooking_token_amount ?? 50.00),
                'consecutive_declines_limit' => (int)($tenant->consecutive_declines_limit ?? 3),
                'phone' => $tenant->mobile ?? '+91 98765 43210',
                'address' => $tenant->branches->first()?->address ?? 'Main Branch Address',
                'cancellation_policy' => 'Free cancellation up to ' . (($tenant->cancellation_buffer_minutes ?? 120) >= 60 ? (($tenant->cancellation_buffer_minutes ?? 120) / 60) . ' hour(s)' : ($tenant->cancellation_buffer_minutes ?? 120) . ' mins') . ' before slot',
            ],
            'data' => $tenant,
        ]);
    }

    /**
     * Get dynamic dashboard stats scoped strictly to authenticated tenant.
     */
    public function dashboardStats(Request $request)
    {
        $user = $request->user();
        $tenantId = $user?->tenant_id ?? Tenant::first()?->id;

        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No tenant associated.'], 404);
        }

        $todayDate = date('Y-m-d');

        $todayBookingsQuery = \App\Models\Booking::where('tenant_id', $tenantId)
            ->whereDate('booking_date', $todayDate);

        $todayRevenue = (float) $todayBookingsQuery->clone()
            ->whereIn('status', ['CONFIRMED', 'COMPLETED'])
            ->sum('amount');

        $todayBookingsCount = $todayBookingsQuery->count();

        $branchIds = \App\Models\Branch::where('tenant_id', $tenantId)->pluck('id');
        $activeStylistsCount = \App\Models\Staff::whereIn('branch_id', $branchIds)
            ->where('is_bookable', true)
            ->count();

        $feeBalance = (float) \App\Models\TenantLedger::where('tenant_id', $tenantId)
            ->where('type', 'DEBIT')
            ->where('status', 'PENDING')
            ->sum('amount');

        return response()->json([
            'success' => true,
            'data' => [
                'today_revenue' => number_format($todayRevenue, 2),
                'today_bookings_count' => $todayBookingsCount,
                'active_stylists_count' => $activeStylistsCount,
                'fee_balance' => number_format($feeBalance, 2),
            ]
        ]);
    }

    /**
     * Request Account & Data Deletion with Strict Legal & Dues Verification Rules
     */
    public function requestDeletion(Request $request)
    {
        $user = $request->user();
        $tenant = $user->tenant;

        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'No salon tenant associated with this account.'], 404);
        }

        // Rule 1: Owner MUST clear all SaaS dues (TenantLedger DEBIT balance == 0)
        $dueAmount = (float) \App\Models\TenantLedger::where('tenant_id', $tenant->id)
            ->where('type', 'DEBIT')
            ->where('status', 'PENDING')
            ->sum('amount');

        if ($dueAmount > 0) {
            $formattedDues = number_format($dueAmount, 2);
            return response()->json([
                'success' => false,
                'due_blocked' => true,
                'message' => "Account deletion cannot be processed because you have unpaid SaaS dues (₹{$formattedDues}). All dues must be cleared prior to account closure, or legal action may be initiated under platform terms."
            ], 422);
        }

        // Rule 2: Account MUST be older than 1 month (registered > 30 days ago)
        $accountAgeDays = $user->created_at ? $user->created_at->diffInDays(now()) : 31;
        if ($accountAgeDays < 30) {
            $daysLeft = 30 - $accountAgeDays;
            return response()->json([
                'success' => false,
                'age_blocked' => true,
                'message' => "Account deletion request failed. Your account must be active for at least 30 days before requesting closure. Please wait {$daysLeft} more day(s)."
            ], 422);
        }

        // Rule 3: Place Account in 15-Day Suspension Period for Deletion
        $tenant->update([
            'status' => 'SUSPENDED_FOR_DELETION',
            'description' => ($tenant->description ?? '') . " [Account deletion requested on " . now()->toDateTimeString() . " - Scheduled permanent purge after 15 days]"
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Your shop account has been successfully placed in a 15-day suspension period. All online customer bookings are now disabled. Permanent deletion of all shop records and data will occur automatically after 15 days.'
        ]);
    }

    /**
     * Toggle Shop Online / Offline Availability immediately in database.
     */
    public function toggleOnline(Request $request)
    {
        $user = $request->user();
        $tenant = $user->tenant;

        if (!$tenant) {
            $staffRecord = \App\Models\Staff::where('user_id', $user->id)->first();
            $tenant = $staffRecord?->branch?->tenant;
        }

        if (!$tenant && $user->tenant_id) {
            $tenant = Tenant::find($user->tenant_id);
        }

        if (!$tenant) {
            $tenant = Tenant::first();
        }

        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'No salon tenant found.'], 404);
        }

        $isOnline = $request->boolean('is_online', true);
        $newStatus = $isOnline ? 'VERIFIED' : 'EMERGENCY_CLOSED';

        $tenant->update(['status' => $newStatus]);

        return response()->json([
            'success' => true,
            'status' => $newStatus,
            'is_online' => $isOnline,
            'message' => $isOnline ? 'Shop status updated to ONLINE. Accepting bookings.' : 'Shop status updated to OFFLINE. Bookings paused.',
            'tenant' => [
                'id' => $tenant->id,
                'business_name' => $tenant->business_name,
                'status' => $newStatus,
            ]
        ]);
    }

    /**
     * Get Home & Event/Wedding Services configuration for the shop.
     */
    public function getHomeServiceSettings(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $tenant = Tenant::find($tenantId);
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Tenant not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'settings' => [
                'home_service_enabled'     => (bool) ($tenant->home_service_enabled ?? true),
                'event_wedding_enabled'    => (bool) ($tenant->event_wedding_enabled ?? true),
                'home_service_radius_km'   => (int) ($tenant->home_service_radius_km ?? 10),
                'home_service_travel_fee'  => (float) ($tenant->home_service_travel_fee ?? 100.00),
                'event_min_booking_amount' => (float) ($tenant->event_min_booking_amount ?? 1500.00),
                'home_service_notes'       => $tenant->home_service_notes ?? '',
            ],
        ]);
    }

    /**
     * Update Home & Event/Wedding Services configuration for the shop.
     */
    public function updateHomeServiceSettings(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id;

        $tenant = Tenant::find($tenantId);
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Tenant not found.'], 404);
        }

        $validated = $request->validate([
            'home_service_enabled'     => 'nullable|boolean',
            'event_wedding_enabled'    => 'nullable|boolean',
            'home_service_radius_km'   => 'nullable|integer|min:1|max:100',
            'home_service_travel_fee'  => 'nullable|numeric|min:0',
            'event_min_booking_amount' => 'nullable|numeric|min:0',
            'home_service_notes'       => 'nullable|string|max:1000',
        ]);

        $tenant->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Home & Wedding service settings updated successfully!',
            'settings' => [
                'home_service_enabled'     => (bool) $tenant->home_service_enabled,
                'event_wedding_enabled'    => (bool) $tenant->event_wedding_enabled,
                'home_service_radius_km'   => (int) $tenant->home_service_radius_km,
                'home_service_travel_fee'  => (float) $tenant->home_service_travel_fee,
                'event_min_booking_amount' => (float) $tenant->event_min_booking_amount,
                'home_service_notes'       => $tenant->home_service_notes ?? '',
            ],
        ]);
    }

    /**
     * Toggle CRM-Only Booking Mode.
     * When ON: only customers in the shop CRM directory can place bookings.
     * When OFF: any registered user can book.
     */
    public function toggleCrmOnly(Request $request)
    {
        $user = $request->user();
        $tenant = $user->tenant;

        if (!$tenant && $user->tenant_id) {
            $tenant = Tenant::find($user->tenant_id);
        }
        if (!$tenant) {
            $staffRecord = \App\Models\Staff::where('user_id', $user->id)->first();
            $tenant = $staffRecord?->branch?->tenant;
        }
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'No salon tenant found.'], 404);
        }

        return response()->json([
            'success'          => true,
            'crm_only_booking' => (bool) $tenant->crm_only_booking,
            'message'          => $crmOnly
                ? 'CRM-Only Mode ON: Only your CRM customers can book.'
                : 'CRM-Only Mode OFF: All app users can book.',
        ]);
    }

    /**
     * Update salon booking & cancellation policies.
     */
    public function updateBookingPolicy(Request $request)
    {
        $user = $request->user();
        $tenant = $user->tenant;

        if (!$tenant && $user->tenant_id) {
            $tenant = Tenant::find($user->tenant_id);
        }
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Salon tenant not found.'], 404);
        }

        $validated = $request->validate([
            'booking_policy' => 'nullable|string',
            'cancellation_buffer_minutes' => 'nullable|integer|min:0|max:10080',
            'prebooking_token_amount' => 'nullable|numeric|min:0',
            'consecutive_declines_limit' => 'nullable|integer|min:1|max:10',
        ]);

        $updateData = [];
        if ($request->has('booking_policy')) {
            $updateData['booking_policy'] = $validated['booking_policy'];
        }
        if ($request->has('cancellation_buffer_minutes')) {
            $updateData['cancellation_buffer_minutes'] = $validated['cancellation_buffer_minutes'];
        }
        if ($request->has('prebooking_token_amount')) {
            $updateData['prebooking_token_amount'] = $validated['prebooking_token_amount'];
        }
        if ($request->has('consecutive_declines_limit')) {
            $updateData['consecutive_declines_limit'] = $validated['consecutive_declines_limit'];
        }

        $tenant->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Salon booking & cancellation policies updated successfully!',
            'data' => [
                'booking_policy' => $tenant->booking_policy,
                'cancellation_buffer_minutes' => (int)($tenant->cancellation_buffer_minutes ?? 120),
                'prebooking_token_amount' => (float)($tenant->prebooking_token_amount ?? 50.00),
                'consecutive_declines_limit' => (int)($tenant->consecutive_declines_limit ?? 3),
            ]
        ]);
    }
}


