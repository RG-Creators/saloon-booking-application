<?php

namespace App\Http\Controllers;

use App\Models\UserNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get stored notifications for the authenticated user (Owner or Staff).
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $unreadOnly = filter_var($request->query('unread_only', false), FILTER_VALIDATE_BOOLEAN);

        $query = UserNotification::where('user_id', $userId);

        if ($unreadOnly) {
            $query->where('is_read', false);
        }

        $notifications = $query->latest()
            ->take(50)
            ->get();

        $unreadCount = UserNotification::where('user_id', $userId)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'success' => true,
            'unread_count' => $unreadCount,
            'data' => $notifications,
        ]);
    }

    /**
     * Mark notification(s) as read.
     */
    public function markRead(Request $request)
    {
        $userId = $request->user()->id;

        if ($request->notification_id) {
            UserNotification::where('user_id', $userId)
                ->where('id', $request->notification_id)
                ->update(['is_read' => true]);
        } else {
            UserNotification::where('user_id', $userId)
                ->update(['is_read' => true]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifications marked as read.'
        ]);
    }
}
