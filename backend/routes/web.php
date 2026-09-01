<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminWebController;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\AdminBillingController;
use App\Http\Controllers\AdminPlatformSettingsController;
use App\Http\Controllers\AdminSubadminController;
use App\Http\Controllers\AdminNotificationController;
use App\Http\Controllers\AdminLogController;
use App\Http\Controllers\OwnerWebController;
use App\Http\Controllers\StaffWebController;
use App\Http\Controllers\CustomerWebController;
use App\Http\Controllers\Auth\WebAuthController;

// Landing Page & Subdomain Routing
Route::get('/', function (\Illuminate\Http\Request $request) {
    $host = $request->getHost();
    if (str_starts_with($host, 'superadmin.') || str_starts_with($host, 'admin.')) {
        return app(\App\Http\Controllers\Auth\WebAuthController::class)->showLoginForm();
    }
    return view('welcome');
})->name('landing');

// Direct superadmin access
Route::get('/superadmin', [WebAuthController::class, 'showLoginForm'])->name('superadmin.login');

// Community Contribution & Backing Routes (Razorpay)
Route::post('/contribute/create-order', [\App\Http\Controllers\ContributionController::class, 'createOrder'])->name('contribute.order');
Route::post('/contribute/verify', [\App\Http\Controllers\ContributionController::class, 'verifyPayment'])->name('contribute.verify');

// Authentication Routes
Route::get('/login', [WebAuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [WebAuthController::class, 'login'])->name('login.submit');
Route::post('/register-shop', [WebAuthController::class, 'registerShop'])->name('register.shop');
Route::post('/register-customer', [WebAuthController::class, 'registerCustomer'])->name('register.customer');
Route::post('/logout', [WebAuthController::class, 'logout'])->name('logout');
Route::get('/location/detect', [\App\Http\Controllers\LocationController::class, 'detect'])->name('location.detect');

// Protected Admin Routes
Route::middleware(['auth', 'role:SUPER_ADMIN|SUBADMIN'])->prefix('admin')->group(function () {
    Route::get('/', [AdminWebController::class, 'dashboard'])->name('admin.dashboard'); // Dashboard is accessible to all admins

    // Tenants (Shops)
    Route::middleware('permission:manage shops')->group(function () {
        Route::get('/tenants', [AdminWebController::class, 'tenants'])->name('admin.tenants');
        Route::post('/tenants/{tenant}/status', [AdminWebController::class, 'updateTenantStatus'])->name('admin.tenants.status');
    });

    // Users
    Route::middleware('permission:manage users')->group(function () {
        Route::get('/users', [AdminUserController::class, 'index'])->name('admin.users');
        Route::post('/users/{user}/block', [AdminUserController::class, 'toggleBlock'])->name('admin.users.block');
    });
    
    // Subadmins
    Route::middleware('permission:manage subadmins')->group(function () {
        Route::get('/subadmins', [AdminSubadminController::class, 'index'])->name('admin.subadmins');
        Route::post('/subadmins', [AdminSubadminController::class, 'store'])->name('admin.subadmins.store');
        Route::post('/subadmins/{user}/permissions', [AdminSubadminController::class, 'updatePermissions'])->name('admin.subadmins.permissions');
    });

    // Notifications
    Route::middleware('permission:send notifications')->group(function () {
        Route::get('/notifications', [AdminNotificationController::class, 'index'])->name('admin.notifications');
        Route::post('/notifications/send', [AdminNotificationController::class, 'send'])->name('admin.notifications.send');
    });

    // Audit Logs & Crash / IP Tracker
    Route::middleware('permission:view audit logs')->group(function () {
        Route::get('/logs', [AdminLogController::class, 'index'])->name('admin.logs');
        Route::get('/crash-logs', [AdminLogController::class, 'crashLogs'])->name('admin.crash-logs');
        Route::post('/ip/block', [AdminLogController::class, 'blockIp'])->name('admin.ip.block');
        Route::post('/ip/unblock', [AdminLogController::class, 'unblockIp'])->name('admin.ip.unblock');
    });

    // Billing
    Route::middleware('permission:manage billing')->group(function () {
        Route::get('/billing', [AdminBillingController::class, 'index'])->name('admin.billing');
        Route::get('/billing/live-data', [AdminBillingController::class, 'liveData'])->name('admin.billing.live-data');
        Route::post('/billing/toggle', [AdminBillingController::class, 'toggle'])->name('admin.billing.toggle');
        Route::post('/billing/add-dues', [AdminBillingController::class, 'addDues'])->name('admin.billing.add-dues');
    });

    // Settings
    Route::middleware('permission:manage settings')->group(function () {
        Route::get('/settings', [AdminPlatformSettingsController::class, 'index'])->name('admin.settings');
        Route::post('/settings/api-config', [AdminPlatformSettingsController::class, 'updateApiConfig'])->name('admin.settings.api');
        Route::post('/settings/theme-config', [AdminPlatformSettingsController::class, 'updateAppTheme'])->name('admin.settings.theme');
        Route::post('/settings/billing/toggle', [AdminPlatformSettingsController::class, 'toggleBilling'])->name('admin.settings.billing.toggle');
        Route::post('/settings/{setting}', [AdminPlatformSettingsController::class, 'updateSetting'])->name('admin.settings.update');
        Route::post('/settings/flags/{flag}/toggle', [AdminPlatformSettingsController::class, 'toggleFeatureFlag'])->name('admin.settings.flags.toggle');
        Route::post('/settings/flags', [AdminPlatformSettingsController::class, 'storeFeatureFlag'])->name('admin.settings.flags.store');
    });
});

// Protected Owner Routes
Route::middleware(['auth', 'role:OWNER'])->prefix('owner')->group(function () {
    Route::get('/dashboard', [OwnerWebController::class, 'dashboard'])->name('owner.dashboard');
    Route::get('/services', [OwnerWebController::class, 'services'])->name('owner.services');
    Route::post('/services', [OwnerWebController::class, 'storeService'])->name('owner.services.store');
    Route::get('/combos', [OwnerWebController::class, 'combos'])->name('owner.combos');
    Route::post('/combos', [OwnerWebController::class, 'storeCombo'])->name('owner.combos.store');
    Route::get('/staff', [OwnerWebController::class, 'staff'])->name('owner.staff');
    Route::post('/staff', [OwnerWebController::class, 'storeStaff'])->name('owner.staff.store');
    Route::get('/schedules', [OwnerWebController::class, 'schedules'])->name('owner.schedules');
    Route::post('/schedules/branch', [OwnerWebController::class, 'updateBranchHours'])->name('owner.branch.hours.update');
    Route::post('/schedules', [OwnerWebController::class, 'updateStaffHours'])->name('owner.schedules.update');
    Route::get('/appointments', [OwnerWebController::class, 'appointments'])->name('owner.appointments');
    Route::post('/appointments/{booking}/status', [OwnerWebController::class, 'updateAppointmentStatus'])->name('owner.appointments.status');
    Route::post('/appointments/{booking}/approve', [OwnerWebController::class, 'approveBooking'])->name('owner.appointments.approve');
    Route::post('/appointments/{booking}/decline', [OwnerWebController::class, 'declineBooking'])->name('owner.appointments.decline');
    Route::post('/lock-slot', [OwnerWebController::class, 'lockSlot'])->name('owner.slots.lock');
    Route::get('/billing', [OwnerWebController::class, 'billing'])->name('owner.billing');
    Route::get('/billing/live-data', [OwnerWebController::class, 'liveData'])->name('owner.billing.live-data');
    Route::post('/billing/settle', [OwnerWebController::class, 'settleLedger'])->name('owner.billing.settle');
    Route::post('/policy', [OwnerWebController::class, 'updateBookingPolicy'])->name('owner.policy.update');
    Route::get('/api/unread-booking', [OwnerWebController::class, 'getUnreadBookingAlert'])->name('owner.api.unread_booking');
    Route::get('/customers', [OwnerWebController::class, 'customers'])->name('owner.customers');
    Route::post('/customers/add', [OwnerWebController::class, 'addCrmCustomer'])->name('owner.customers.add');
    Route::post('/customers/{customer}/toggle', [OwnerWebController::class, 'toggleCrmCustomer'])->name('owner.customers.toggle');
    Route::get('/marketing', [OwnerWebController::class, 'marketing'])->name('owner.marketing');
    Route::post('/marketing/send', [OwnerWebController::class, 'sendCampaign'])->name('owner.marketing.send');
});

// Protected Staff Routes
Route::middleware(['auth', 'role:STAFF'])->prefix('staff')->group(function () {
    Route::get('/dashboard', [StaffWebController::class, 'dashboard'])->name('staff.dashboard');
    Route::post('/appointments/{booking}/status', [StaffWebController::class, 'updateStatus'])->name('staff.appointments.update');
    Route::get('/api/unread-booking', [StaffWebController::class, 'getUnreadBookingAlert'])->name('staff.api.unread_booking');
});

// Protected Customer Routes
Route::middleware(['auth', 'role:CUSTOMER'])->group(function () {
    Route::get('/customer/dashboard', [CustomerWebController::class, 'dashboard'])->name('customer.dashboard');
    Route::get('/customer/explore', [CustomerWebController::class, 'explore'])->name('customer.explore');
    Route::get('/customer/bookings', [CustomerWebController::class, 'bookings'])->name('customer.bookings');
    Route::post('/customer/book', [CustomerWebController::class, 'storeBooking'])->name('customer.book.store');
    Route::get('/customer/api/slots', [CustomerWebController::class, 'getAvailableSlots'])->name('customer.api.slots');
});
