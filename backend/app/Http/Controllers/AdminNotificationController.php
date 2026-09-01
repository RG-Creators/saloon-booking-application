<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Tenant;
use App\Models\ActivityLog;
use App\Models\UserNotification;
use App\Services\FcmService;

class AdminNotificationController extends Controller
{
    public function index()
    {
        $shops = Tenant::with(['users' => function ($q) {
            $q->whereHas('roles', function ($r) {
                $r->whereIn('name', ['OWNER', 'STAFF']);
            });
        }])->get();

        $owners = User::whereHas('roles', function ($q) {
            $q->whereIn('name', ['OWNER', 'STAFF']);
        })->with('tenant')->get();

        $logs = ActivityLog::where('action', 'LIKE', '%Push Notification%')
            ->latest()
            ->take(10)
            ->get();

        return view('admin.notifications', compact('shops', 'owners', 'logs'));
    }

    public function send(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'target_type' => 'required|in:BROADCAST,SPECIFIC_OWNER',
            'target_owner_id' => 'nullable|exists:users,id',
            'target_role' => 'nullable|in:ALL,OWNER,STAFF,CUSTOMER',
        ]);

        if ($validated['target_type'] === 'SPECIFIC_OWNER') {
            if (!$request->target_owner_id) {
                return back()->with('error', 'Please select a target user to send the notification to.');
            }

            $user = User::with('tenant')->findOrFail($request->target_owner_id);
            $shopName = $user->tenant->business_name ?? 'The Shop';

            // 1. ALWAYS Store Notification in DB (Guarantees Offline Delivery on Login)
            UserNotification::create([
                'user_id' => $user->id,
                'tenant_id' => $user->tenant_id,
                'title' => $validated['title'],
                'body' => $validated['message'],
                'type' => 'ADMIN_ALERT',
                'data' => [
                    'shop_id' => (string)($user->tenant_id ?? 0),
                    'target_user_id' => (string)$user->id,
                    'shop_name' => $shopName,
                ],
                'is_read' => false,
            ]);

            // 2. Dispatch FCM Push Notification if device token active
            $fcmStatus = 'Queued in User Database for Offline Delivery';
            if (!empty($user->fcm_token)) {
                $result = FcmService::send(
                    $user->fcm_token,
                    $validated['title'],
                    $validated['message'],
                    [
                        'shop_id' => (string)($user->tenant_id ?? 0),
                        'target_user_id' => (string)$user->id,
                        'target_tenant_id' => (string)($user->tenant_id ?? 0),
                        'target_user_name' => (string)$user->name,
                        'shop_name' => (string)$shopName,
                        'type' => 'DIRECT_OWNER_ALERT'
                    ]
                );
                $fcmStatus = $result['message'];
            }

            ActivityLog::create([
                'user_id' => auth()->id(),
                'action' => 'Sent Targeted Push Notification',
                'description' => "Sent notification '{$validated['title']}' to {$user->name} ({$shopName}). Status: {$fcmStatus}",
                'ip_address' => $request->ip()
            ]);

            return back()->with('success', "⚡ Notification queued & dispatched to '{$user->name}' ({$shopName})! Status: {$fcmStatus}");
        }

        // Broadcast Mode
        $query = User::query();
        if (($validated['target_role'] ?? 'ALL') !== 'ALL') {
            $query->whereHas('roles', function ($q) use ($validated) {
                $q->where('name', $validated['target_role']);
            });
        }
        $targetUsers = $query->get();
        $dispatchedCount = 0;

        foreach ($targetUsers as $targetUser) {
            // Save to DB for each user
            UserNotification::create([
                'user_id' => $targetUser->id,
                'tenant_id' => $targetUser->tenant_id,
                'title' => $validated['title'],
                'body' => $validated['message'],
                'type' => 'BROADCAST_ALERT',
                'is_read' => false,
            ]);

            if (!empty($targetUser->fcm_token)) {
                $res = FcmService::send(
                    $targetUser->fcm_token,
                    $validated['title'],
                    $validated['message'],
                    ['type' => 'SYSTEM_BROADCAST', 'target_user_id' => (string)$targetUser->id]
                );
                if ($res['success']) $dispatchedCount++;
            }
        }

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Sent Broadcast Push Notification',
            'description' => "Broadcasted '{$validated['title']}' to {$validated['target_role']} (stored for {$targetUsers->count()} users, live push sent to {$dispatchedCount} devices).",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Broadcast queued for {$targetUsers->count()} users (live push sent to {$dispatchedCount} devices).");
    }
}
