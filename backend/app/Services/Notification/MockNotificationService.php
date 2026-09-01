<?php

namespace App\Services\Notification;

use Illuminate\Support\Facades\Log;

class MockNotificationService implements NotificationServiceInterface
{
    // PENDING_USER_INPUT: Firebase JSON credentials required. This is a mock.

    public function sendPush(string $deviceToken, string $title, string $body, array $data = []): bool
    {
        Log::info("Mock FCM Push sent to {$deviceToken}: {$title}");
        return true;
    }

    public function sendToTopic(string $topic, string $title, string $body, array $data = []): bool
    {
        Log::info("Mock FCM Topic sent to {$topic}: {$title}");
        return true;
    }
}
