<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class WebAuthController extends Controller
{
    public function showLoginForm()
    {
        if (Auth::check()) {
            return $this->redirectBasedOnRole(Auth::user());
        }
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $user = Auth::user();

            if ($user->is_banned) {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'Your account has been suspended. Reason: ' . ($user->banned_reason ?? 'Policy Violation')
                ])->onlyInput('email');
            }

            // Track IP & Terms Declaration
            $user->update([
                'last_login_ip' => $request->ip(),
                'terms_accepted_at' => now(),
                'terms_accepted_ip' => $request->ip(),
            ]);

            $request->session()->regenerate();
            return $this->redirectBasedOnRole($user);
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        
        return redirect('/login');
    }

    /**
     * Handle Shop Owner Registration / Application Request.
     */
    public function registerShop(Request $request)
    {
        $validated = $request->validate([
            'business_name' => 'required|string|max:255',
            'business_type' => 'required|string|max:100',
            'owner_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'city' => 'required|string|max:100',
            'address' => 'required|string|max:255',
            'shop_image' => 'nullable|file|image|max:5120',
            'shop_image_url' => 'nullable|url'
        ]);

        $imagePath = null;
        if ($request->hasFile('shop_image')) {
            $path = $request->file('shop_image')->store('shop_verifications', 'public');
            $imagePath = '/storage/' . $path;
        } elseif (!empty($validated['shop_image_url'])) {
            $imagePath = $validated['shop_image_url'];
        } else {
            // Default placeholder shop image for verification demo
            $imagePath = 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=600&q=80';
        }

        // Create Tenant in PENDING status for Super Admin review
        $tenant = \App\Models\Tenant::create([
            'business_name' => $validated['business_name'],
            'business_type' => $validated['business_type'],
            'status' => 'PENDING',
            'verification_image' => $imagePath
        ]);

        // Create Branch
        \App\Models\Branch::create([
            'tenant_id' => $tenant->id,
            'name' => $validated['business_name'] . ' Main Branch',
            'address' => $validated['address'],
            'city' => $validated['city']
        ]);

        // Create Owner User
        $owner = \App\Models\User::create([
            'tenant_id' => $tenant->id,
            'name' => $validated['owner_name'],
            'email' => $validated['email'],
            'password' => \Illuminate\Support\Facades\Hash::make($validated['password']),
            'last_login_ip' => $request->ip(),
            'terms_accepted_at' => now(),
            'terms_accepted_ip' => $request->ip(),
        ]);

        $owner->assignRole('OWNER');

        \App\Models\ActivityLog::create([
            'user_id' => $owner->id,
            'action' => 'Submitted Shop Application',
            'description' => "Shop owner application submitted for {$tenant->business_name} (Status: PENDING).",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success_registration', "Shop registration submitted successfully! Your shop verification image has been uploaded and sent to the SaaS Super Admin team for review.");
    }

    /**
     * Handle Customer Registration Request with PIN code & city.
     */
    public function registerCustomer(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'mobile' => 'required|string|max:20|unique:users,mobile',
            'pin_code' => 'required|string|max:10',
            'city' => 'required|string|max:100',
            'password' => 'required|string|min:8',
        ]);

        $customer = \App\Models\User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'mobile' => $validated['mobile'],
            'pin_code' => $validated['pin_code'],
            'city' => $validated['city'],
            'password' => \Illuminate\Support\Facades\Hash::make($validated['password']),
            'last_login_ip' => $request->ip(),
            'terms_accepted_at' => now(),
            'terms_accepted_ip' => $request->ip(),
        ]);

        $customer->assignRole('CUSTOMER');

        \Illuminate\Support\Facades\Auth::login($customer);

        return redirect()->route('customer.dashboard')->with('success', "Welcome to Glamora, {$customer->name}! Explore nearby salons around PIN code {$customer->pin_code}.");
    }

    private function redirectBasedOnRole($user)
    {
        if ($user->hasRole('SUPER_ADMIN') || $user->hasRole('SUBADMIN')) {
            return redirect()->route('admin.dashboard');
        } elseif ($user->hasRole('OWNER')) {
            return redirect()->route('owner.dashboard');
        } elseif ($user->hasRole('STAFF')) {
            return redirect()->route('staff.dashboard');
        } elseif ($user->hasRole('CUSTOMER')) {
            return redirect()->route('customer.dashboard');
        }

        return redirect('/');
    }
}
