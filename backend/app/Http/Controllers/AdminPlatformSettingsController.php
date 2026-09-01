<?php

namespace App\Http\Controllers;

use App\Models\PlatformSetting;
use App\Models\FeatureFlag;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class AdminPlatformSettingsController extends Controller
{
    /**
     * Display Platform Settings & Feature Flags.
     */
    public function index()
    {
        // 1. Ensure essential Platform Settings exist
        PlatformSetting::firstOrCreate(['key' => 'api_base_url'], ['value' => 'http://10.21.170.176:8000/api/v1', 'type' => 'STRING']);
        PlatformSetting::firstOrCreate(['key' => 'api_secret'], ['value' => 'saas_secret_key_v1', 'type' => 'STRING']);
        PlatformSetting::firstOrCreate(['key' => 'maintenance_mode'], ['value' => 'false', 'type' => 'BOOLEAN']);
        PlatformSetting::firstOrCreate(['key' => 'maintenance_eta'], ['value' => '', 'type' => 'STRING']);
        PlatformSetting::firstOrCreate(['key' => 'maintenance_message'], ['value' => 'We are performing scheduled maintenance to enhance system performance. Please check back shortly.', 'type' => 'STRING']);
        PlatformSetting::firstOrCreate(['key' => 'billing_enabled'], ['value' => 'true', 'type' => 'BOOLEAN']);
        PlatformSetting::firstOrCreate(['key' => 'booking_commission_fee'], ['value' => '1.00', 'type' => 'NUMBER']);
        PlatformSetting::firstOrCreate(['key' => 'billing_due_threshold'], ['value' => '500', 'type' => 'NUMBER']);
        PlatformSetting::firstOrCreate(['key' => 'app_announcement'], ['value' => '', 'type' => 'STRING']);
        
        // App Theme default JSON
        PlatformSetting::firstOrCreate(['key' => 'app_theme'], [
            'value' => json_encode([
                'primary_color' => '#4F46E5',
                'font_family' => 'Poppins',
                'button_border_radius' => 14,
                'show_revenue_card' => true,
            ]),
            'type' => 'JSON'
        ]);

        // 2. Ensure default Feature Flags exist for Non-Tech Control
        $defaultFlags = [
            ['feature_name' => 'enable_offline_mode', 'rollout_percentage' => 100, 'enabled' => true],
            ['feature_name' => 'enable_booking_chat', 'rollout_percentage' => 100, 'enabled' => false],
            ['feature_name' => 'enable_multi_branch', 'rollout_percentage' => 100, 'enabled' => true],
            ['feature_name' => 'enable_customer_reviews', 'rollout_percentage' => 100, 'enabled' => true],
            ['feature_name' => 'enable_auto_slot_locking', 'rollout_percentage' => 100, 'enabled' => true],
            ['feature_name' => 'enable_combo_packages', 'rollout_percentage' => 100, 'enabled' => true],
        ];

        foreach ($defaultFlags as $f) {
            FeatureFlag::firstOrCreate(['feature_name' => $f['feature_name']], $f);
        }

        $settings = PlatformSetting::all()->keyBy('key');
        $featureFlags = FeatureFlag::all();

        $themeData = [];
        if (isset($settings['app_theme'])) {
            $themeData = json_decode($settings['app_theme']->value, true) ?? [];
        }

        return view('admin.settings', compact('settings', 'featureFlags', 'themeData'));
    }

    /**
     * Update API Base URL & Security Secret
     */
    public function updateApiConfig(Request $request)
    {
        $validated = $request->validate([
            'api_base_url' => 'required|url',
            'api_secret' => 'required|string|min:4|max:100',
            'maintenance_mode' => 'nullable|string|in:true,false',
            'maintenance_eta' => 'nullable|string|max:100',
            'maintenance_message' => 'nullable|string|max:500',
            'notify_users' => 'nullable|boolean',
            'app_announcement' => 'nullable|string|max:255',
        ]);

        $isMaintenanceOn = $request->input('maintenance_mode', 'false') === 'true';
        $eta = trim($request->input('maintenance_eta', ''));
        $msg = trim($request->input('maintenance_message', 'We are performing scheduled maintenance to enhance system performance. Please check back shortly.'));

        PlatformSetting::updateOrCreate(['key' => 'api_base_url'], ['value' => $validated['api_base_url'], 'type' => 'STRING']);
        PlatformSetting::updateOrCreate(['key' => 'api_secret'], ['value' => $validated['api_secret'], 'type' => 'STRING']);
        PlatformSetting::updateOrCreate(['key' => 'maintenance_mode'], ['value' => $isMaintenanceOn ? 'true' : 'false', 'type' => 'BOOLEAN']);
        PlatformSetting::updateOrCreate(['key' => 'maintenance_eta'], ['value' => $eta, 'type' => 'STRING']);
        PlatformSetting::updateOrCreate(['key' => 'maintenance_message'], ['value' => $msg, 'type' => 'STRING']);
        PlatformSetting::updateOrCreate(['key' => 'app_announcement'], ['value' => $request->input('app_announcement', ''), 'type' => 'STRING']);

        // Broadcast Push Notification if requested
        $notifStatus = '';
        if ($isMaintenanceOn && $request->boolean('notify_users')) {
            $notifTitle = '🚨 Scheduled Maintenance Underway';
            $notifBody = $eta ? "System maintenance has started. Expected completion: {$eta}. {$msg}" : "System maintenance has started. {$msg}";

            $users = \App\Models\User::all();
            foreach ($users as $u) {
                \App\Models\UserNotification::create([
                    'user_id' => $u->id,
                    'tenant_id' => $u->tenant_id,
                    'title' => $notifTitle,
                    'body' => $notifBody,
                    'type' => 'MAINTENANCE_ALERT',
                    'is_read' => false,
                ]);

                if (!empty($u->fcm_token)) {
                    \App\Services\FcmService::send($u->fcm_token, $notifTitle, $notifBody, [
                        'type' => 'MAINTENANCE_ALERT',
                        'maintenance' => 'true',
                        'eta' => $eta,
                    ]);
                }
            }
            $notifStatus = ' Broadcast notification dispatched to all registered users.';
        }

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Updated API & Server Config',
            'description' => "Updated API settings. Maintenance: " . ($isMaintenanceOn ? 'ON' : 'OFF') . " (ETA: {$eta})." . $notifStatus,
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', 'API & Server Configuration updated successfully.' . $notifStatus);
    }

    /**
     * Update App Branding & UI Theme
     */
    public function updateAppTheme(Request $request)
    {
        $validated = $request->validate([
            'primary_color' => 'required|string|regex:/^#[a-fA-F0-9]{6}$/',
            'font_family' => 'required|string|in:Poppins,Inter,Plus Jakarta Sans,Roboto',
            'button_border_radius' => 'required|numeric|min:4|max:32',
            'show_revenue_card' => 'nullable|boolean',
            'app_logo' => 'nullable|file|mimes:png,jpg,jpeg,svg,webp,gif|max:5120',
            'remove_logo' => 'nullable|boolean',
        ]);

        $setting = PlatformSetting::where('key', 'app_theme')->first();
        $themeArray = $setting ? (json_decode($setting->value, true) ?? []) : [];

        $themeArray['primary_color'] = $validated['primary_color'];
        $themeArray['font_family'] = $validated['font_family'];
        $themeArray['button_border_radius'] = (float)$validated['button_border_radius'];
        $themeArray['show_revenue_card'] = $request->has('show_revenue_card');

        if ($request->boolean('remove_logo')) {
            if (!empty($themeArray['app_logo'])) {
                $oldPath = public_path(ltrim(parse_url($themeArray['app_logo'], PHP_URL_PATH), '/'));
                if (file_exists($oldPath) && is_file($oldPath)) {
                    @unlink($oldPath);
                }
            }
            $themeArray['app_logo'] = null;
        } elseif ($request->hasFile('app_logo')) {
            $file = $request->file('app_logo');
            $fileName = 'app_logo_' . time() . '.' . $file->getClientOriginalExtension();
            $destDir = public_path('uploads/branding');
            if (!file_exists($destDir)) {
                mkdir($destDir, 0755, true);
            }
            $file->move($destDir, $fileName);
            $themeArray['app_logo'] = '/uploads/branding/' . $fileName;
        }

        PlatformSetting::updateOrCreate(
            ['key' => 'app_theme'],
            ['value' => json_encode($themeArray), 'type' => 'JSON']
        );

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Updated App UI Theme & Branding',
            'description' => "Updated App Primary Color to {$validated['primary_color']}, Font to {$validated['font_family']}" . ($request->hasFile('app_logo') ? ', and uploaded custom app logo' : ($request->boolean('remove_logo') ? ', and reset logo to default Flutter icon' : '')) . ".",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', 'Mobile App UI Theme & Branding updated successfully.');
    }

    /**
     * Update individual Platform Setting.
     */
    public function updateSetting(Request $request, PlatformSetting $setting)
    {
        $validated = $request->validate([
            'value' => 'required|string'
        ]);

        $setting->update(['value' => $validated['value']]);

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Updated Platform Setting',
            'description' => "Updated setting '{$setting->key}' to '{$validated['value']}'.",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Setting '{$setting->key}' updated successfully.");
    }

    /**
     * Toggle Feature Flag status.
     */
    public function toggleFeatureFlag(Request $request, FeatureFlag $flag)
    {
        $flag->update(['enabled' => !$flag->enabled]);

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Toggled Feature Flag',
            'description' => "Toggled feature flag '{$flag->feature_name}' to " . ($flag->enabled ? 'ON' : 'OFF') . ".",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Feature flag '{$flag->feature_name}' updated to " . ($flag->enabled ? 'ON' : 'OFF') . ".");
    }

    /**
     * Create new Feature Flag.
     */
    public function storeFeatureFlag(Request $request)
    {
        $validated = $request->validate([
            'feature_name' => 'required|string|unique:feature_flags,feature_name',
            'rollout_percentage' => 'required|integer|min:0|max:100',
            'enabled' => 'nullable|boolean'
        ]);

        FeatureFlag::create([
            'feature_name' => $validated['feature_name'],
            'rollout_percentage' => $validated['rollout_percentage'],
            'enabled' => $request->has('enabled') ? (bool)$request->enabled : true,
        ]);

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Created Feature Flag',
            'description' => "Created feature flag '{$validated['feature_name']}'.",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "Feature flag '{$validated['feature_name']}' created successfully.");
    }

    /**
     * Toggle SaaS Billing Engine Status (Enabled / Disabled).
     */
    public function toggleBilling(Request $request)
    {
        $setting = PlatformSetting::firstOrCreate(['key' => 'billing_enabled'], ['value' => 'true', 'type' => 'BOOLEAN']);
        $newValue = ($setting->value === 'true' || $setting->value === '1') ? 'false' : 'true';
        $setting->update(['value' => $newValue]);

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Toggled SaaS Billing Engine',
            'description' => "Changed SaaS billing engine status to " . ($newValue === 'true' ? 'ENABLED' : 'DISABLED') . ".",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "SaaS Billing Engine has been " . ($newValue === 'true' ? 'ENABLED' : 'DISABLED') . ".");
    }
}
