<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DiscoveryController;
use App\Http\Controllers\TenantController;
use App\Http\Controllers\BranchController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\StaffController;
use App\Http\Controllers\AvailabilityController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\CrmController;
use App\Http\Controllers\CampaignController;
use App\Http\Controllers\PromotionController;
use App\Http\Controllers\LocationController;
use App\Http\Controllers\AppConfigController;

/*
|--------------------------------------------------------------------------
| REST API Routes (Phases 1 - 10)
|--------------------------------------------------------------------------
*/

// --- PUBLIC AUTH ROUTES (Rate limited to 10 req/min) ---
Route::middleware('throttle:10,1')->prefix('v1/auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/register-shop', [AuthController::class, 'registerShop']);
});

// --- PUBLIC DISCOVERY ROUTES (Rate limited to 60 req/min) ---
Route::middleware('throttle:60,1')->prefix('v1/discovery')->group(function () {
    Route::get('/nearby', [DiscoveryController::class, 'nearby']);
    Route::get('/search', [DiscoveryController::class, 'search']);
    Route::get('/shops/{id}', [DiscoveryController::class, 'shopDetails']);
    Route::get('/shops/{id}/services', [DiscoveryController::class, 'services']);
});

// --- PAYMENT WEBHOOK (Idempotent Payment Handler) ---
Route::post('v1/payments/webhook', [PaymentController::class, 'webhook']);

// --- PUBLIC BILLING STATUS (Mobile App Polling - No Auth Required) ---
Route::get('v1/billing/status', [\App\Http\Controllers\AdminBillingController::class, 'billingStatus']);

// --- SERVER DRIVEN UI & APP MONITORING (Public) ---
Route::get('v1/app-config', [\App\Http\Controllers\AppConfigController::class, 'index']);
Route::post('v1/logs/crash', [\App\Http\Controllers\AppConfigController::class, 'logCrash']);

// --- LOCATION PROXY ROUTES (Public) ---
Route::get('v1/location/states', [\App\Http\Controllers\LocationProxyController::class, 'states']);
Route::get('v1/location/cities/{state}', [\App\Http\Controllers\LocationProxyController::class, 'cities']);
Route::get('v1/location/pincode/{city}', [\App\Http\Controllers\LocationProxyController::class, 'pincode']);
Route::get('v1/location/detect', [\App\Http\Controllers\LocationController::class, 'detect']);

// --- AUTHENTICATED REST API ROUTES (Sanctum Token Protected) ---
Route::middleware(['auth:sanctum', 'throttle:60,1'])->prefix('v1')->group(function () {
    
    // Auth profile & logout & FCM token
    Route::get('/auth/user', [AuthController::class, 'userProfile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/fcm-token', [AuthController::class, 'updateFcmToken']);

    // In-App & Stored Offline Notifications
    Route::get('/notifications', [\App\Http\Controllers\NotificationController::class, 'index']);
    Route::post('/notifications/read', [\App\Http\Controllers\NotificationController::class, 'markRead']);

    // --- Business Management (Owner/Staff) ---
    Route::prefix('business')->group(function () {
        Route::post('/onboard', [TenantController::class, 'store']);
        Route::get('/profile', [TenantController::class, 'show']);
        Route::get('/dashboard-stats', [TenantController::class, 'dashboardStats']);
        Route::post('/policy', [\App\Http\Controllers\OwnerWebController::class, 'updateBookingPolicy']);
        Route::get('/combos', [\App\Http\Controllers\OwnerWebController::class, 'getApiCombos']);
        Route::post('/combos', [\App\Http\Controllers\OwnerWebController::class, 'storeApiCombo']);
        Route::put('/combos/{id}', [\App\Http\Controllers\OwnerWebController::class, 'updateApiCombo']);
        Route::delete('/combos/{id}', [\App\Http\Controllers\OwnerWebController::class, 'deleteApiCombo']);
        Route::post('/combos/{id}/toggle', [\App\Http\Controllers\OwnerWebController::class, 'toggleApiCombo']);
        Route::get('/customers', [\App\Http\Controllers\CrmController::class, 'index']);
        Route::get('/customers/unadded-booking-clients', [\App\Http\Controllers\CrmController::class, 'unaddedBookingClients']);
        Route::post('/customers/batch-add-bookings', [\App\Http\Controllers\CrmController::class, 'batchAddBookingClients']);
        Route::post('/customers/lookup', [\App\Http\Controllers\CrmController::class, 'lookup']);
        Route::post('/customers', [\App\Http\Controllers\CrmController::class, 'store']);
        Route::put('/customers/{id}', [\App\Http\Controllers\CrmController::class, 'update']);
        Route::delete('/customers/{id}', [\App\Http\Controllers\CrmController::class, 'destroy']);
        Route::get('/customers/{id}/details', [\App\Http\Controllers\CrmController::class, 'showDetails']);
        Route::get('/promotions', [\App\Http\Controllers\PromotionController::class, 'index']);
        Route::post('/promotions/discounts', [\App\Http\Controllers\PromotionController::class, 'storeDiscount']);
        Route::put('/promotions/discounts/{id}', [\App\Http\Controllers\PromotionController::class, 'updateDiscount']);
        Route::post('/promotions/discounts/{id}/toggle', [\App\Http\Controllers\PromotionController::class, 'toggleDiscount']);
        Route::delete('/promotions/discounts/{id}', [\App\Http\Controllers\PromotionController::class, 'destroyDiscount']);
        Route::post('/promotions/surge-rules', [\App\Http\Controllers\PromotionController::class, 'storeSurgeRule']);
        Route::put('/promotions/surge-rules/{id}', [\App\Http\Controllers\PromotionController::class, 'updateSurgeRule']);
        Route::post('/promotions/surge-rules/{id}/toggle', [\App\Http\Controllers\PromotionController::class, 'toggleSurgeRule']);
        Route::delete('/promotions/surge-rules/{id}', [\App\Http\Controllers\PromotionController::class, 'destroySurgeRule']);
        Route::get('/today-slots', [BookingController::class, 'todaySlots']);
        
        Route::get('/bookings', [BookingController::class, 'ownerBookings']);
        Route::post('/bookings/{id}/respond', [BookingController::class, 'respondBooking']);
        Route::get('/unread-booking', [\App\Http\Controllers\OwnerWebController::class, 'getUnreadBookingAlert']);

        // Home & Event / Wedding Services Configuration
        Route::get('/home-service-settings', [TenantController::class, 'getHomeServiceSettings']);
        Route::post('/home-service-settings', [TenantController::class, 'updateHomeServiceSettings']);

        // ₹1 SaaS Commission Ledger & Razorpay Settlement
        Route::get('/ledger', [\App\Http\Controllers\TenantLedgerController::class, 'index']);
        Route::post('/ledger/order', [\App\Http\Controllers\TenantLedgerController::class, 'createOrder']);
        Route::post('/ledger/verify', [\App\Http\Controllers\TenantLedgerController::class, 'verifyPayment']);
        Route::post('/ledger/add-test-dues', [\App\Http\Controllers\TenantLedgerController::class, 'addTestDues']);
        Route::get('/ledger/{id}/invoice', [\App\Http\Controllers\TenantLedgerController::class, 'downloadInvoice']);

        Route::apiResource('branches', BranchController::class);
        Route::post('/branches/{id}/toggle', [BranchController::class, 'toggleActive']);
        Route::get('/branches/{id}/hours', [BranchController::class, 'hours']);
        Route::put('/branches/{id}/hours', [BranchController::class, 'updateHours']);
        Route::apiResource('services', ServiceController::class);
        Route::post('/staff/toggle-online', [StaffController::class, 'toggleOnline']);
        Route::post('/toggle-online', [TenantController::class, 'toggleOnline']);
        Route::post('/toggle-crm-only', [TenantController::class, 'toggleCrmOnly']);
        Route::post('/booking-policy', [TenantController::class, 'updateBookingPolicy']);
        Route::apiResource('staff', StaffController::class);
        Route::post('/staff/{id}/reset-password', [StaffController::class, 'resetPassword']);
        Route::post('/account/request-deletion', [TenantController::class, 'requestDeletion']);
    });

    Route::get('/location/detect', [LocationController::class, 'detect']);

    // --- Booking Engine ---
    Route::prefix('booking')->group(function () {
        Route::post('/slots/check', [AvailabilityController::class, 'check']);
        Route::post('/lock', [BookingController::class, 'lockSlot']);
        Route::post('/confirm', [BookingController::class, 'confirm']);
    });

    // --- Customer App Bookings & Management ---
    Route::prefix('customer')->group(function () {
        Route::get('/bookings', [BookingController::class, 'customerBookings']);
        Route::post('/bookings/{id}/cancel', [BookingController::class, 'customerCancelBooking']);
    });

    // --- Owner Marketing & CRM ---
    Route::prefix('marketing')->group(function () {
        Route::get('/crm/customers', [CrmController::class, 'index']);
        Route::get('/crm/customers/{id}/details', [CrmController::class, 'showDetails']);
        Route::delete('/crm/customers/{id}', [CrmController::class, 'destroy']);
        Route::post('/campaigns', [CampaignController::class, 'store']);
        Route::post('/promotions/last-minute', [PromotionController::class, 'createLastMinute']);
    });
});

