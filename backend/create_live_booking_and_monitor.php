<?php

require 'D:/SaaS_booking/backend/vendor/autoload.php';
$app = require_once 'D:/SaaS_booking/backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Tenant;
use App\Models\Branch;
use App\Models\Service;
use App\Models\Staff;
use App\Models\User;
use App\Models\Booking;

// Find or set up Tenant "The Grooming Lounge"
$tenant = Tenant::where('business_name', 'LIKE', '%Grooming%')->first();
if (!$tenant) {
    $tenant = Tenant::create([
        'business_name' => 'The Grooming Lounge',
        'business_type' => 'Grooming Studio',
        'status' => 'VERIFIED',
        'booking_policy' => 'PAY_AT_SALON'
    ]);
} else {
    $tenant->update([
        'business_name' => 'The Grooming Lounge',
        'booking_policy' => 'PAY_AT_SALON' // Ensure manual approval popup mode
    ]);
}

$branch = Branch::where('tenant_id', $tenant->id)->first();
if (!$branch) {
    $branch = Branch::create([
        'tenant_id' => $tenant->id,
        'name' => 'Grooming Lounge Main Branch',
        'address' => 'Connaught Place Block A',
        'city' => 'New Delhi',
        'pin_code' => '110001'
    ]);
}

$service = Service::where('branch_id', $branch->id)->first();
if (!$service) {
    $service = Service::create([
        'branch_id' => $branch->id,
        'name' => 'Signature Haircut & Beard Trim',
        'category' => 'Haircut',
        'price' => 450.00,
        'duration_minutes' => 40,
        'buffer_time_minutes' => 5
    ]);
}

$staff = Staff::where('branch_id', $branch->id)->first();
if (!$staff) {
    $staff = Staff::create([
        'branch_id' => $branch->id,
        'name' => 'Vikram Sharma',
        'role' => 'Master Barber',
        'is_bookable' => true
    ]);
}

$customer = User::role('CUSTOMER')->first();
if (!$customer) {
    $customer = User::firstOrCreate(
        ['email' => 'aarav.g@example.com'],
        ['name' => 'Aarav Gupta', 'mobile' => '+91 9876543210', 'password' => bcrypt('password')]
    );
}

// Clear previous test bookings for this customer to ensure clean state
Booking::where('user_id', $customer->id)->where('status', 'PENDING')->delete();

$bookingDate = date('Y-m-d', strtotime('+1 day'));
$startTime = '11:30:00';
$endTime = date('H:i:s', strtotime($startTime) + ($service->duration_minutes * 60));

$booking = Booking::create([
    'tenant_id' => $tenant->id,
    'branch_id' => $branch->id,
    'service_id' => $service->id,
    'staff_id' => $staff->id,
    'user_id' => $customer->id,
    'booking_date' => $bookingDate,
    'start_time' => $startTime,
    'end_time' => $endTime,
    'amount' => $service->price,
    'status' => 'PENDING'
]);

echo "\n========================================================================\n";
echo "🎉 LIVE BOOKING CREATED & SENT TO OWNER APP!\n";
echo "========================================================================\n";
echo "  • Booking ID  : #{$booking->id}\n";
echo "  • Salon Name  : {$tenant->business_name}\n";
echo "  • Customer    : {$customer->name} ({$customer->mobile})\n";
echo "  • Service     : {$service->name}\n";
echo "  • Stylist     : {$staff->name}\n";
echo "  • Time Slot   : {$bookingDate} at " . date('h:i A', strtotime($startTime)) . "\n";
echo "  • Amount      : ₹" . number_format($booking->amount, 2) . "\n";
echo "  • Status      : {$booking->status} (Waiting for Owner App popup action...)\n";
echo "========================================================================\n";

