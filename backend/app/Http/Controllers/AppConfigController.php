<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\PlatformSetting;

class AppConfigController extends Controller
{
    /**
     * Returns the dynamic App Configuration for the Flutter App.
     */
    public function index(Request $request)
    {
        // Fetch theme settings from platform_settings table
        $themeSetting = PlatformSetting::where('key', 'app_theme')->first();
        $theme = $themeSetting ? (json_decode($themeSetting->value, true) ?? []) : [
            'primary_color' => '#4F46E5', // Indigo default
            'font_family' => 'Poppins',
            'button_border_radius' => 14,
            'show_revenue_card' => true,
            'app_logo' => null,
        ];

        if (!empty($theme['app_logo'])) {
            $theme['app_logo'] = str_starts_with($theme['app_logo'], 'http') 
                ? $theme['app_logo'] 
                : url($theme['app_logo']);
        } else {
            $theme['app_logo'] = null;
        }

        // Fetch dynamic API Base URL & API Secret from platform_settings table or fallback
        $apiBaseUrlSetting = PlatformSetting::where('key', 'api_base_url')->first();
        $apiSecretSetting = PlatformSetting::where('key', 'api_secret')->first();
        $billingEnabledSetting = PlatformSetting::where('key', 'billing_enabled')->first();
        $commissionSetting = PlatformSetting::where('key', 'booking_commission_fee')->first();
        $maintenanceModeSetting = PlatformSetting::where('key', 'maintenance_mode')->first();
        $maintenanceEtaSetting = PlatformSetting::where('key', 'maintenance_eta')->first();
        $maintenanceMsgSetting = PlatformSetting::where('key', 'maintenance_message')->first();

        $apiBaseUrl = $apiBaseUrlSetting ? $apiBaseUrlSetting->value : env('DYNAMIC_API_BASE_URL', 'http://10.21.170.176:8000/api/v1');
        $apiSecret = $apiSecretSetting ? $apiSecretSetting->value : env('DYNAMIC_API_SECRET', 'saas_secret_key_v1');
        $isBillingEnabled = $billingEnabledSetting ? in_array(strtolower(trim((string)$billingEnabledSetting->value)), ['true', '1', 'yes', 'on'], true) : true;
        $isMaintenance = $maintenanceModeSetting ? in_array(strtolower(trim((string)$maintenanceModeSetting->value)), ['true', '1', 'yes', 'on'], true) : false;

        return response()->json([
            'success' => true,
            'data' => [
                'theme' => $theme,
                'features' => [
                    'enable_offline_mode' => true,
                    'enable_booking_chat' => false,
                    'enable_billing' => $isBillingEnabled,
                ],
                'maintenance' => [
                    'enabled' => $isMaintenance,
                    'title' => 'System Maintenance Underway',
                    'message' => $maintenanceMsgSetting?->value ?? 'We are performing scheduled maintenance to enhance system performance. Please check back shortly.',
                    'eta' => $maintenanceEtaSetting?->value ?? '',
                ],
                'billing' => [
                    'enabled' => $isBillingEnabled,
                    'commission_per_booking' => (float)($commissionSetting?->value ?? 1.00),
                ],
                'api_config' => [
                    'api_base_url' => $apiBaseUrl,
                    'api_secret' => $apiSecret,
                ]
            ]
        ]);
    }

    /**
     * Store crash logs from the mobile app
     */
    public function logCrash(Request $request)
    {
        $validated = $request->validate([
            'error_message' => 'required|string',
            'stack_trace' => 'nullable|string',
            'app_version' => 'nullable|string',
            'os_version' => 'nullable|string',
            'device_model' => 'nullable|string',
            'user_id' => 'nullable|integer',
            'tenant_id' => 'nullable|integer',
        ]);

        $validated['ip_address'] = $request->ip();

        \App\Models\AppCrashLog::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Crash logged successfully'
        ]);
    }
}
