<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use App\Models\User;
use App\Models\Branch;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminWebController extends Controller
{
    /**
     * Display the Super Admin Dashboard.
     */
    public function dashboard(Request $request)
    {
        $stats = [
            'total_tenants' => Tenant::count(),
            'active_branches' => Branch::count(),
            'total_users' => User::count(),
            'total_bookings' => Booking::count(),
        ];

        $recentTenants = Tenant::orderBy('created_at', 'desc')->take(5)->get();

        return view('admin.dashboard', compact('stats', 'recentTenants'));
    }

    /**
     * Display all tenants.
     */
    public function tenants()
    {
        $tenants = Tenant::paginate(15);
        return view('admin.tenants', compact('tenants'));
    }

    public function updateTenantStatus(Request $request, Tenant $tenant)
    {
        $validated = $request->validate([
            'status' => 'required|in:VERIFIED,REJECTED,SUSPENDED,PENDING'
        ]);

        $user = Auth::user();

        // Check permissions for subadmins
        if (!$user->hasRole('SUPER_ADMIN') && !$user->hasPermissionTo('manage shops')) {
            abort(403, 'You do not have permission to manage shops.');
        }

        $tenant->update(['status' => $validated['status']]);

        // If suspended, we could also ban the owner user automatically.
        if ($validated['status'] === 'SUSPENDED' || $validated['status'] === 'REJECTED') {
            User::where('tenant_id', $tenant->id)->update([
                'is_banned' => true,
                'banned_reason' => 'Shop has been ' . strtolower($validated['status']) . ' by administration.'
            ]);
        } elseif ($validated['status'] === 'VERIFIED') {
            User::where('tenant_id', $tenant->id)->update([
                'is_banned' => false,
                'banned_reason' => null
            ]);
        }

        \App\Models\ActivityLog::create([
            'user_id' => $user->id,
            'action' => "Changed Shop Status to {$validated['status']}",
            'description' => "Updated status for shop ID {$tenant->id} ({$tenant->business_name}).",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Shop status updated to {$validated['status']}");
    }
}
