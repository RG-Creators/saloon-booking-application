<?php

namespace App\Http\Controllers;

use App\Models\User;
use Spatie\Permission\Models\Permission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminSubadminController extends Controller
{
    public function index()
    {
        // Load all subadmins and all available permissions
        $subadmins = User::role('SUBADMIN')->with('permissions')->get();
        $permissions = Permission::all();
        
        return view('admin.subadmins', compact('subadmins', 'permissions'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'permissions' => 'nullable|array',
            'permissions.*' => 'exists:permissions,name'
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $user->assignRole('SUBADMIN');

        if (!empty($validated['permissions'])) {
            $user->givePermissionTo($validated['permissions']);
        }

        // Reset permission cache
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        return back()->with('success', 'Subadmin created successfully.');
    }

    public function updatePermissions(Request $request, User $user)
    {
        if ($user->hasRole('SUPER_ADMIN')) {
            abort(403, 'Action Denied: SaaS Owner (Super Admin) permissions cannot be modified.');
        }

        if (!auth()->user()->hasRole('SUPER_ADMIN') && !auth()->user()->hasPermissionTo('manage subadmins')) {
            abort(403, 'Action Denied: Only SaaS Owner can manage subadmin permissions.');
        }

        $validated = $request->validate([
            'permissions' => 'nullable|array',
            'permissions.*' => 'exists:permissions,name'
        ]);

        // Sync permissions (removes old ones, adds new ones)
        $user->syncPermissions($validated['permissions'] ?? []);

        // Reset permission cache
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        return back()->with('success', "Permissions updated for {$user->name}.");
    }
}
