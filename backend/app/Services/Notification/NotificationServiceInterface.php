<?php

namespace App\Services\Notification;

interface NotificationServiceInterface
{
    /**
     * Send a push notification.
     */
    public function sendPush(string $deviceToken, string $title, string $body, array $data = []): bool;

    /**
     * Send a notification to a topic.
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = []): bool;
}
