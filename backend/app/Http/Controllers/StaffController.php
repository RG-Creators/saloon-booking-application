<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use App\Models\Staff;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class StaffController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $staffRecord = Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)
            ->when($request->branch_id, function ($query, $branchId) {
                return $query->where('branch_id', $branchId);
            })
            ->with(['workingHours', 'services'])
            ->get();
            
        return response()->json(['success' => true, 'data' => $staff]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'branch_id' => 'required|integer',
            'name' => 'required|string|max:255',
            'mobile' => 'nullable|string',
            'email' => 'nullable|email',
            'photo' => 'nullable|string',
            'is_bookable' => 'boolean',
            'is_active' => 'boolean',
            'role' => 'nullable|string|max:100',
            'create_login' => 'boolean', // Should we create an app login for them?
            'password' => 'nullable|string|min:8',
            'service_ids' => 'nullable|array',
            'service_ids.*' => 'integer',
        ]);

        // Tenant Isolation
        Branch::where('id', $validated['branch_id'])->where('tenant_id', $request->user()->tenant_id)->firstOrFail();

        DB::beginTransaction();
        try {
            $userId = null;
            if ($request->create_login && (!empty($validated['email']) || !empty($validated['mobile']))) {
                $existingUser = null;
                if (!empty($validated['mobile'])) {
                    $existingUser = User::where('mobile', $validated['mobile'])->first();
                }
                if (!$existingUser && !empty($validated['email'])) {
                    $existingUser = User::where('email', $validated['email'])->first();
                }

                if ($existingUser) {
                    $userId = $existingUser->id;
                    if (!empty($validated['email'])) $existingUser->email = $validated['email'];
                    if (!empty($validated['mobile'])) $existingUser->mobile = $validated['mobile'];
                    $existingUser->save();
                } else {
                    $user = User::create([
                        'tenant_id' => $request->user()->tenant_id,
                        'name' => $validated['name'],
                        'email' => $validated['email'] ?? null,
                        'mobile' => $validated['mobile'] ?? null,
                        'password' => Hash::make($validated['password'] ?? 'password123'),
                    ]);
                    $userRole = in_array(strtoupper($validated['role'] ?? 'STAFF'), ['MANAGER', 'OWNER']) ? 'MANAGER' : 'STAFF';
                    try { $user->assignRole($userRole); } catch (\Exception $e) {}
                    $userId = $user->id;
                }
            }

            $staff = Staff::create([
                'branch_id' => $validated['branch_id'],
                'user_id' => $userId,
                'name' => $validated['name'],
                'mobile' => $validated['mobile'] ?? null,
                'email' => $validated['email'] ?? null,
                'photo' => $validated['photo'] ?? null,
                'is_bookable' => $validated['is_bookable'] ?? true,
                'is_active' => $validated['is_active'] ?? true,
                'role' => $validated['role'] ?? 'STAFF',
            ]);

            if ($request->has('service_ids')) {
                $staff->services()->sync($request->service_ids ?? []);
            }

            DB::commit();
            return response()->json(['success' => true, 'data' => $staff->load('services')], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to create staff: ' . $e->getMessage()], 500);
        }
    }

    public function show(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)
            ->with(['workingHours', 'services'])
            ->findOrFail($id);
            
        return response()->json(['success' => true, 'data' => $staff]);
    }

    /**
     * Toggle staff online/offline availability.
     */
    public function toggleOnline(Request $request)
    {
        $user = $request->user();
        $staff = Staff::where('user_id', $user->id)->first() ?? Staff::where('email', $user->email)->first();

        if (!$staff) {
            $staff = Staff::first();
        }

        if (!$staff) {
            return response()->json(['success' => false, 'message' => 'Staff profile not found.'], 404);
        }

        $isOnline = $request->has('is_online') ? (bool)$request->is_online : !$staff->is_bookable;
        $staff->update([
            'is_bookable' => $isOnline,
            'is_active' => $isOnline,
        ]);

        return response()->json([
            'success' => true,
            'is_online' => (bool)$staff->is_bookable,
            'message' => $isOnline ? 'Status updated to ONLINE. Ready for bookings!' : 'Status updated to OFFLINE. Unavailable for bookings.',
        ]);
    }

    /**
     * Get staff dashboard metrics and stats.
     */
    public function getStaffStats(Request $request)
    {
        $user = $request->user();
        $staff = Staff::where('user_id', $user->id)->first() ?? Staff::where('email', $user->email)->first();

        if (!$staff) {
            $staff = Staff::first();
        }

        $today = now()->toDateString();
        $tenantId = $user->tenant_id ?? $staff?->branch?->tenant_id ?? 1;
        $tenant = \App\Models\Tenant::find($tenantId);

        // Fetch today's bookings for this staff
        $query = \App\Models\Booking::where('staff_id', $staff->id ?? 1)
            ->whereDate('booking_date', $today)
            ->with(['user:id,name,mobile', 'service:id,name,price,duration_minutes']);

        // Check Tenant policy rules:
        // If owner approval required, hide PENDING bookings from staff dashboard
        if ($tenant && $tenant->notification_target === 'DISPATCH_TO_OWNER' && $tenant->booking_policy !== 'AUTO_ACCEPT') {
            $todayBookings = (clone $query)->where('status', '!=', 'PENDING')->get();
        } else {
            $todayBookings = $query->get();
        }

        $completedBookings = $todayBookings->where('status', 'COMPLETED');
        $customersServed = $completedBookings->count();
        $requestsReceived = $todayBookings->count();

        // Calculate hours worked today from completed booking durations
        $totalMinutes = 0;
        foreach ($completedBookings as $b) {
            $totalMinutes += $b->service->duration_minutes ?? 30;
        }
        $hours = floor($totalMinutes / 60);
        $mins = $totalMinutes % 60;
        $workedHoursStr = $hours > 0 ? "{$hours}h {$mins}m" : "{$mins} mins";
        if ($totalMinutes == 0) {
            $workedHoursStr = ($staff->is_bookable ?? true) ? "Active Today" : "Offline";
        }

        // Get Next Booking Today (nearest upcoming confirmed/pending slot)
        $nowTime = now()->format('H:i:s');
        $nextBooking = $todayBookings
            ->whereIn('status', ['CONFIRMED', 'PENDING', 'LOCKED'])
            ->filter(function ($b) use ($nowTime) {
                return $b->start_time >= $nowTime || $b->created_at >= now()->subMinutes(30);
            })
            ->sortBy('start_time')
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'staff_id' => $staff->id ?? 0,
                'staff_name' => $staff->name ?? $user->name,
                'is_online' => (bool)($staff->is_bookable ?? true),
                'worked_hours_today' => $workedHoursStr,
                'customers_served' => $customersServed,
                'requests_received' => $requestsReceived,
                'next_booking' => $nextBooking ? [
                    'id' => $nextBooking->id,
                    'customer_name' => $nextBooking->user->name ?? 'Guest Client',
                    'customer_phone' => $nextBooking->user->mobile ?? '+91 98765 43210',
                    'service_name' => $nextBooking->service->name ?? 'Salon Service',
                    'amount' => number_format($nextBooking->amount, 2),
                    'time_slot' => $nextBooking->start_time,
                    'status' => $nextBooking->status,
                ] : null,
            ]
        ]);
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();
        $tenantId = $user->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');

        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'mobile' => 'nullable|string', // Validation without unique initially, we check manually
            'email' => 'nullable|email',
            'is_bookable' => 'boolean',
            'is_active' => 'boolean',
            'role' => 'nullable|string|max:100',
            'service_ids' => 'nullable|array',
            'service_ids.*' => 'integer',
        ]);

        DB::beginTransaction();
        try {
            if (!$staff->user_id && (!empty($validated['email']) || !empty($validated['mobile']))) {
                // Check if a user with this mobile/email already exists
                $existingUser = null;
                if (!empty($validated['mobile'])) {
                    $existingUser = User::where('mobile', $validated['mobile'])->first();
                }
                if (!$existingUser && !empty($validated['email'])) {
                    $existingUser = User::where('email', $validated['email'])->first();
                }

                if ($existingUser) {
                    // Check if this existing user is attached to another staff in this tenant
                    $otherStaff = Staff::where('user_id', $existingUser->id)->where('id', '!=', $staff->id)->first();
                    if ($otherStaff) {
                        return response()->json(['success' => false, 'message' => 'Mobile or Email is already linked to another staff member (' . $otherStaff->name . ').'], 422);
                    }
                    $staffUser = $existingUser;
                    $staff->user_id = $staffUser->id;
                    if (isset($validated['name'])) $staffUser->name = $validated['name'];
                    if (isset($validated['email'])) $staffUser->email = $validated['email'];
                    if (isset($validated['mobile'])) $staffUser->mobile = $validated['mobile'];
                    $staffUser->save();
                } else {
                    $staffUser = User::create([
                        'tenant_id' => $tenantId,
                        'name' => $validated['name'] ?? $staff->name,
                        'email' => $validated['email'] ?? null,
                        'mobile' => $validated['mobile'] ?? null,
                        'password' => Hash::make('password123'),
                    ]);
                    $userRole = in_array(strtoupper($validated['role'] ?? 'STAFF'), ['MANAGER', 'OWNER']) ? 'MANAGER' : 'STAFF';
                    try { $staffUser->assignRole($userRole); } catch (\Exception $e) {}
                    $staff->user_id = $staffUser->id;
                }
            } elseif ($staff->user_id) {
                $staffUser = User::find($staff->user_id);
                if ($staffUser) {
                    if (isset($validated['email']) && $validated['email'] !== $staffUser->email) {
                        if (User::where('email', $validated['email'])->where('id', '!=', $staffUser->id)->exists()) {
                            return response()->json(['success' => false, 'message' => 'Email already in use by another user.'], 422);
                        }
                        $staffUser->email = $validated['email'];
                    }
                    if (isset($validated['mobile']) && $validated['mobile'] !== $staffUser->mobile) {
                        if (User::where('mobile', $validated['mobile'])->where('id', '!=', $staffUser->id)->exists()) {
                            return response()->json(['success' => false, 'message' => 'Mobile already in use by another user.'], 422);
                        }
                        $staffUser->mobile = $validated['mobile'];
                    }
                    if (isset($validated['name'])) {
                        $staffUser->name = $validated['name'];
                    }
                    $staffUser->save();

                    if (isset($validated['role'])) {
                        $userRole = in_array(strtoupper($validated['role']), ['MANAGER', 'OWNER']) ? 'MANAGER' : 'STAFF';
                        try { $staffUser->syncRoles([$userRole]); } catch (\Exception $e) {}
                    }
                }
            }

            if ($request->has('service_ids')) {
                $staff->services()->sync($request->service_ids ?? []);
            }

            $staff->update($validated);
            DB::commit();

            return response()->json(['success' => true, 'message' => 'Staff updated successfully.', 'data' => $staff->load(['services', 'user'])]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Update failed: ' . $e->getMessage()], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        DB::beginTransaction();
        try {
            if ($staff->user_id) {
                User::where('id', $staff->user_id)->delete();
            }
            $staff->delete();
            
            DB::commit();
            return response()->json(['success' => true, 'message' => 'Staff deleted successfully.']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to delete staff: ' . $e->getMessage()], 500);
        }
    }

    public function resetPassword(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'password' => 'required|string|min:8'
        ]);

        if (!$staff->user_id) {
            return response()->json(['success' => false, 'message' => 'This staff member does not have a login account.'], 400);
        }

        $staffUser = User::find($staff->user_id);
        if ($staffUser) {
            $staffUser->password = Hash::make($validated['password']);
            $staffUser->save();
            return response()->json(['success' => true, 'message' => 'Password reset successfully.']);
        }

        return response()->json(['success' => false, 'message' => 'Staff user not found.'], 404);
    }
}
