<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Tenant;
use App\Models\Branch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Authenticate user & issue Sanctum Bearer Token.
     */
    public function login(Request $request)
    {
        // 🛡️ SECURITY 1: Input Sanitization & Normalization
        $rawInput = trim(strip_tags($request->input('email', '')));
        $isEmail = filter_var($rawInput, FILTER_VALIDATE_EMAIL);

        $cleanInput = $isEmail ? strtolower($rawInput) : preg_replace('/[^\d]/', '', $rawInput);
        $request->merge(['email' => $cleanInput]);

        $validated = $request->validate([
            'email' => $isEmail ? 'required|email' : ['required', 'string', 'regex:/^\d{10,11}$/'],
            'password' => 'required|string|min:4|max:100',
            'device_name' => 'nullable|string|max:100',
            'fcm_token' => 'nullable|string|max:255',
            'app_type' => 'nullable|string|in:partner,customer,web',
        ], [
            'email.regex' => 'The phone number must be 10 or 11 digits.',
        ]);

        // 🛡️ SECURITY 2: Account Lockout & Brute-Force Rate Limiting (Max 5 attempts per 5 mins per IP + account)
        $throttleKey = 'login_lockout:' . Str::lower($cleanInput) . '|' . $request->ip();
        if (\Illuminate\Support\Facades\RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = \Illuminate\Support\Facades\RateLimiter::availableIn($throttleKey);
            return response()->json([
                'success' => false,
                'message' => "Too many failed login attempts. Please wait {$seconds} seconds before trying again.",
                'retry_after' => $seconds,
            ], 429);
        }

        $loginField = $isEmail ? 'email' : 'mobile';
        $user = User::where($loginField, $cleanInput)->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            \Illuminate\Support\Facades\RateLimiter::hit($throttleKey, 300); // 5 min lockout decay
            return response()->json([
                'success' => false,
                'message' => 'The provided credentials do not match our records.'
            ], 401);
        }

        // Clear rate limiter on successful authentication
        \Illuminate\Support\Facades\RateLimiter::clear($throttleKey);

        // STRICT RBAC APP BOUNDARY CHECKS
        $appType = $request->input('app_type', 'partner');
        $userRoles = $user->getRoleNames()->toArray();
        $isSuperAdmin = in_array('SUPERADMIN', $userRoles) || in_array('SUPER_ADMIN', $userRoles) || in_array('SUBADMIN', $userRoles) || $user->hasRole('SUPERADMIN') || $user->hasRole('SUPER_ADMIN') || $user->hasRole('SUBADMIN');
        $isCustomer = in_array('CUSTOMER', $userRoles) && !in_array('OWNER', $userRoles) && !in_array('STAFF', $userRoles) && !in_array('MANAGER', $userRoles);

        if ($appType === 'partner') {
            if ($isSuperAdmin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Superadmin and Subadmin accounts can only log in through the Web Console.',
                    'role_error' => 'ADMIN_WEB_ONLY'
                ], 403);
            }

            if ($isCustomer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer accounts cannot access the Partner App. Please use the Customer App.',
                    'role_error' => 'CUSTOMER_APP_ONLY'
                ], 403);
            }

            $isStaffMember = \App\Models\Staff::where('user_id', $user->id)->exists();
            if (!$user->tenant_id && !$isStaffMember) {
                return response()->json([
                    'success' => false,
                    'message' => 'No salon business associated with this account. Please register your shop first.',
                    'role_error' => 'NO_TENANT_LINKED'
                ], 403);
            }

            if ($user->tenant && $user->tenant->status === 'PENDING_VERIFICATION') {
                return response()->json([
                    'success' => false,
                    'message' => 'Your shop registration is still pending verification. Our team will contact you shortly.',
                    'status' => 'PENDING_VERIFICATION'
                ], 403);
            }
        } elseif ($appType === 'customer') {
            if ($isSuperAdmin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Superadmin and Subadmin accounts cannot access the Customer App.',
                    'role_error' => 'ADMIN_WEB_ONLY'
                ], 403);
            }
        }

        if ($user->is_banned) {
            return response()->json([
                'success' => false,
                'message' => 'Account is suspended.',
                'banned_reason' => $user->banned_reason ?? 'Policy Violation'
            ], 403);
        }

        // Record login IP & terms acceptance declaration
        $user->update([
            'last_login_ip' => $request->ip(),
            'terms_accepted_at' => now(),
            'terms_accepted_ip' => $request->ip(),
        ]);

        // STRICT DEVICE TOKEN ISOLATION: Unbind this device token from all other users first
        if (!empty($validated['fcm_token'])) {
            User::where('fcm_token', $validated['fcm_token'])
                ->where('id', '!=', $user->id)
                ->update(['fcm_token' => null]);

            $user->update(['fcm_token' => $validated['fcm_token']]);
        }

        $deviceName = $validated['device_name'] ?? 'Mobile Device';
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Authentication successful.',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'roles' => $user->getRoleNames(),
                'tenant_id' => $user->tenant_id,
                'fcm_token' => $user->fcm_token,
            ]
        ]);
    }

    /**
     * Update FCM device token for authenticated user.
     */
    public function updateFcmToken(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        if ($user) {
            // Unbind from all other users so only current user holds this device token
            User::where('fcm_token', $validated['fcm_token'])
                ->where('id', '!=', $user->id)
                ->update(['fcm_token' => null]);

            $user->update(['fcm_token' => $validated['fcm_token']]);
        }

        return response()->json([
            'success' => true,
            'message' => 'FCM device token registered successfully to ' . ($user->name ?? 'user') . '.'
        ]);
    }

    /**
     * Register a new Customer account.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'mobile' => 'nullable|string|max:20',
            'password' => 'required|string|min:8',
            'fcm_token' => 'nullable|string',
        ]);

        if (!empty($validated['fcm_token'])) {
            User::where('fcm_token', $validated['fcm_token'])->update(['fcm_token' => null]);
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'mobile' => $validated['mobile'] ?? null,
            'password' => Hash::make($validated['password']),
            'fcm_token' => $validated['fcm_token'] ?? null,
            'last_login_ip' => $request->ip(),
            'terms_accepted_at' => now(),
            'terms_accepted_ip' => $request->ip(),
        ]);

        $user->assignRole('CUSTOMER');

        // 🔗 AUTO CRM LINKING: If owner pre-added this customer by phone or email, auto-link to their new account!
        if (!empty($user->mobile)) {
            $digits = preg_replace('/[^\d]/', '', $user->mobile);
            $clean = strlen($digits) > 10 ? substr($digits, -10) : $digits;
            if ($clean) {
                \App\Models\TenantCustomer::where('phone', 'like', "%{$clean}%")
                    ->orWhere('email', $user->email)
                    ->update([
                        'user_id' => $user->id,
                        'name' => $user->name,
                    ]);
            }
        }

        $token = $user->createToken('Mobile Application')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully.',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'mobile' => $user->mobile,
                'roles' => $user->getRoleNames(),
                'terms_accepted_at' => $user->terms_accepted_at?->toIso8601String(),
            ]
        ], 201);
    }

    /**
     * Register a new Shop / Salon Partner (Pending 30-min Verification).
     */
    public function registerShop(Request $request)
    {
        // 1. Strict Validation & Sanitization
        $validated = $request->validate([
            'owner_name' => 'required|string|max:150',
            'contact_number' => ['required', 'string', 'regex:/^[6-9]\d{9}$/'],
            'email' => 'nullable|email|max:150',
            'password' => 'required|string|min:6',
            'shop_name' => 'required|string|max:150',
            'shop_slug' => 'nullable|string|max:150',
            'state' => 'required|string|max:100',
            'city' => 'required|string|max:100',
            'pincode' => 'required|string|regex:/^\d{6}$/',
            'address' => 'required|string|max:500',
            'fcm_token' => 'nullable|string',
        ]);

        // Sanitization
        $cleanMobile = preg_replace('/[^0-9]/', '', $validated['contact_number']);
        $cleanOwnerName = trim(strip_tags($validated['owner_name']));
        $cleanShopName = trim(strip_tags($validated['shop_name']));
        $cleanSlug = Str::slug($validated['shop_slug'] ?? $cleanShopName);
        $cleanEmail = !empty($validated['email']) ? strtolower(trim(strip_tags($validated['email']))) : null;
        $cleanState = trim(strip_tags($validated['state']));
        $cleanCity = trim(strip_tags($validated['city']));
        $cleanPincode = trim(strip_tags($validated['pincode']));
        $cleanAddress = trim(strip_tags($validated['address']));

        // 2. Security Check: Prevent Duplicate Mobile or Email
        if (User::where('mobile', $cleanMobile)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'This contact number is already registered with a shop. Please sign in or use a different number.'
            ], 422);
        }

        if ($cleanEmail && User::where('email', $cleanEmail)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'This email address is already registered. Please sign in or use a different email.'
            ], 422);
        }

        // 3. Create Tenant in PENDING_VERIFICATION status
        $tenant = Tenant::create([
            'business_name' => $cleanShopName,
            'business_type' => 'Grooming Salon',
            'status' => 'PENDING_VERIFICATION',
            'booking_policy' => 'PAY_AT_SALON',
        ]);

        // 4. Create Main Branch Location
        try {
            Branch::create([
                'tenant_id' => $tenant->id,
                'name' => $cleanShopName . ' - Main Branch',
                'address' => $cleanAddress,
                'city' => $cleanCity,
                'state' => $cleanState,
                'pin_code' => $cleanPincode,
                'contact_mobile' => $cleanMobile,
                'contact_email' => $cleanEmail,
            ]);
        } catch (\Exception $e) {}

        // Unbind FCM token if passed
        if (!empty($validated['fcm_token'])) {
            User::where('fcm_token', $validated['fcm_token'])->update(['fcm_token' => null]);
        }

        // 5. Create Owner User Account
        $user = User::create([
            'name' => $cleanOwnerName,
            'email' => $cleanEmail ?? strtolower($cleanSlug) . '.' . time() . '@bookify.partner',
            'mobile' => $cleanMobile,
            'password' => Hash::make($validated['password']),
            'tenant_id' => $tenant->id,
            'city' => $cleanCity,
            'pin_code' => $cleanPincode,
            'fcm_token' => $validated['fcm_token'] ?? null,
            'last_login_ip' => $request->ip(),
            'terms_accepted_at' => now(),
            'terms_accepted_ip' => $request->ip(),
        ]);

        if (method_exists($user, 'assignRole')) {
            try { $user->assignRole('OWNER'); } catch (\Exception $e) {}
        }

        // 6. Return Clean Success Response
        return response()->json([
            'success' => true,
            'message' => 'Shop registration request submitted! Please wait 30 minutes, our verification team will call you at ' . $cleanMobile . '.',
            'tenant_id' => $tenant->id,
            'contact_number' => $cleanMobile,
            'verification_window_minutes' => 30
        ], 201);
    }

    /**
     * Revoke current access token and unbind FCM token on logout.
     */
    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $user->update(['fcm_token' => null]); // Clear FCM token on logout
            $user->currentAccessToken()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.'
        ]);
    }

    /**
     * Get authenticated user profile.
     */
    public function userProfile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'roles' => $user->getRoleNames(),
                'permissions' => $user->getAllPermissions()->pluck('name'),
                'tenant_id' => $user->tenant_id,
                'last_login_ip' => $user->last_login_ip,
                'fcm_token' => $user->fcm_token
            ]
        ]);
    }
}
