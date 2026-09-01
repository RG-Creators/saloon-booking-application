<?php

require 'D:/SaaS_booking/backend/vendor/autoload.php';
$app = require_once 'D:/SaaS_booking/backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Booking;

$booking = Booking::with(['customer', 'service', 'staff', 'tenant'])->latest()->first();

if (!$booking) {
    echo "No booking found.\n";
    exit(1);
}
$bookingId = $booking->id;

$startTimeFormatted = date('h:i A', strtotime($booking->start_time));

echo "========================================================================\n";
echo "🔍 LIVE MONITORING STATUS FOR BOOKING #{$booking->id}\n";
echo "========================================================================\n";
echo "  • Salon       : {$booking->tenant->business_name}\n";
echo "  • Customer    : {$booking->customer->name}\n";
echo "  • Service     : {$booking->service->name}\n";
echo "  • Slot Date   : {$booking->booking_date}\n";
echo "  • Slot Time   : {$startTimeFormatted} ({$booking->start_time} - {$booking->end_time})\n";
echo "  • Status      : {$booking->status}\n";
echo "========================================================================\n";

if ($booking->status === 'CONFIRMED') {
    echo "✅ ACTION DETECTED: You ACCEPTED / CONFIRMED the booking! (Slot: {$startTimeFormatted})\n";
} elseif ($booking->status === 'CANCELLED') {
    echo "❌ ACTION DETECTED: You DECLINED / CANCELLED the booking!\n";
} elseif ($booking->status === 'PENDING') {
    echo "⏳ WAITING: Booking #{$booking->id} is currently displaying on your phone screen.\n";
} else {
    echo "ℹ️ STATUS UPDATED: {$booking->status}\n";
}
echo "========================================================================\n";

