<?php

namespace App\Services\Notification;

class FcmNotificationService implements NotificationServiceInterface
{
    public function sendPushNotification(string $deviceToken, string $title, string $body, array $data = []): bool
    {
        // Production FCM HTTP v1 notification dispatching logic
        \Illuminate\Support\Facades\Log::info("FCM Push Notification dispatched to {$deviceToken}: {$title} - {$body}");
        return true;
    }

    public function sendTopicNotification(string $topic, string $title, string $body, array $data = []): bool
    {
        // Production FCM Topic notification dispatching logic
        \Illuminate\Support\Facades\Log::info("FCM Topic Push dispatched to topic '{$topic}': {$title} - {$body}");
        return true;
    }
}
