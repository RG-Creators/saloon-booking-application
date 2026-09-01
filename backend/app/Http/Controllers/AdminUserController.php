<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    public function index(Request $request)
    {
        $roleFilter = $request->query('role');
        $searchQuery = $request->query('q');

        $usersQuery = User::with(['roles', 'tenant']);

        if ($roleFilter) {
            $usersQuery->whereHas('roles', function ($q) use ($roleFilter) {
                $q->where('name', $roleFilter);
            });
        }

        if ($searchQuery) {
            $usersQuery->where(function ($q) use ($searchQuery) {
                $q->where('name', 'LIKE', "%{$searchQuery}%")
                  ->orWhere('email', 'LIKE', "%{$searchQuery}%");
            });
        }

        $users = $usersQuery->latest()->paginate(15);
        return view('admin.users', compact('users', 'roleFilter', 'searchQuery'));
    }

    public function toggleBlock(Request $request, User $user)
    {
        $authUser = auth()->user();

        // 1. SaaS Owner (SUPER_ADMIN) is top-most and can NEVER be blocked by anyone
        if ($user->hasRole('SUPER_ADMIN')) {
            abort(403, 'Action Denied: SaaS Owner is the top-most authority and cannot be blocked.');
        }

        // 2. Subadmins (Level 2) cannot block/unblock SaaS Owner or other Subadmins
        if ($authUser->hasRole('SUBADMIN') && ($user->hasRole('SUPER_ADMIN') || $user->hasRole('SUBADMIN'))) {
            abort(403, 'Action Denied: Subadmins cannot block or modify SaaS Owner or Subadmin accounts.');
        }

        $isBanned = !$user->is_banned;
        
        $user->update([
            'is_banned' => $isBanned,
            'banned_reason' => $isBanned ? 'Manually blocked by administration.' : null
        ]);

        \App\Models\ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => $isBanned ? 'Blocked User' : 'Unblocked User',
            'description' => ($isBanned ? 'Blocked' : 'Unblocked') . " user {$user->email} (ID: {$user->id}).",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', 'User ' . ($isBanned ? 'blocked' : 'unblocked') . ' successfully.');
    }
}
