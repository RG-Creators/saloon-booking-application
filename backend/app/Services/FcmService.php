<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * Send FCM Push Notification via Google HTTP v1 API
     */
    public static function send(string $deviceToken, string $title, string $body, array $extraData = []): array
    {
        $serviceAccountPath = storage_path('app/firebase-service-account.json');

        if (!file_exists($serviceAccountPath)) {
            return [
                'success' => false,
                'message' => 'firebase-service-account.json missing at storage/app/firebase-service-account.json',
            ];
        }

        try {
            $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            $projectId = $serviceAccount['project_id'] ?? 'pushforparlour';
            $clientEmail = $serviceAccount['client_email'] ?? '';
            $privateKey = $serviceAccount['private_key'] ?? '';

            if (empty($clientEmail) || empty($privateKey)) {
                return ['success' => false, 'message' => 'Invalid service account credentials.'];
            }

            // 1. Generate OAuth2 Access Token using Google Service Account JWT Assertion
            $accessToken = self::getGoogleAccessToken($clientEmail, $privateKey);
            if (!$accessToken) {
                return ['success' => false, 'message' => 'Failed to obtain Google OAuth2 access token. Check cURL SSL or network.'];
            }

            // 2. Build FCM HTTP v1 payload with MAX PRIORITY for Background Delivery & System Banners
            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            $payload = [
                'message' => [
                    'token' => $deviceToken,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => array_merge([
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'title' => $title,
                        'body' => $body,
                    ], $extraData),
                    'android' => [
                        'priority' => 'HIGH',
                        'direct_boot_ok' => true,
                        'notification' => [
                            'sound' => 'default',
                            'channel_id' => 'high_importance_channel',
                            'default_sound' => true,
                            'default_vibrate_timings' => true,
                            'notification_priority' => 'PRIORITY_MAX',
                            'visibility' => 'PUBLIC',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        ],
                    ],
                ],
            ];

            // 3. Dispatch POST to FCM HTTP v1 endpoint
            $response = Http::withoutVerifying()->withHeaders([
                'Authorization' => 'Bearer ' . $accessToken,
                'Content-Type' => 'application/json',
            ])->post($url, $payload);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'message' => 'FCM V1 Notification dispatched successfully! Message ID: ' . ($response->json('name') ?? 'OK'),
                    'response' => $response->json(),
                ];
            } else {
                Log::error('FCM Send Error: ' . $response->body());
                return [
                    'success' => false,
                    'message' => 'FCM API Error (' . $response->status() . '): ' . ($response->json('error.message') ?? $response->body()),
                ];
            }
        } catch (\Exception $e) {
            Log::error('FCM Exception: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'FCM Exception: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Generate OAuth2 Access Token for Google APIs using RSA SHA256 signed JWT
     */
    private static function getGoogleAccessToken(string $clientEmail, string $privateKey): ?string
    {
        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claimSet = [
            'iss' => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $now + 3600,
            'iat' => $now,
        ];

        $base64UrlHeader = self::base64UrlEncode(json_encode($header));
        $base64UrlClaimSet = self::base64UrlEncode(json_encode($claimSet));
        $signatureInput = $base64UrlHeader . '.' . $base64UrlClaimSet;

        $signature = '';
        $success = openssl_sign($signatureInput, $signature, $privateKey, 'SHA256');

        if (!$success) {
            return null;
        }

        $jwt = $signatureInput . '.' . self::base64UrlEncode($signature);

        $response = Http::withoutVerifying()->asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if ($response->successful()) {
            return $response->json('access_token');
        }

        Log::error('Google OAuth Token Error: ' . $response->body());
        return null;
    }

    private static function base64UrlEncode(string $data): string
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }
}
