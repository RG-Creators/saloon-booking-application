<?php

require 'D:/SaaS_booking/backend/vendor/autoload.php';
$app = require_once 'D:/SaaS_booking/backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Booking;
use App\Models\TenantLedger;
use App\Models\UserNotification;
use Illuminate\Support\Facades\DB;

echo "========================================================================\n";
echo "🧹 RESETTING DATABASE TO FRESH CLEAN STATE FOR TESTING\n";
echo "========================================================================\n";

// Delete all test bookings
$deletedBookings = Booking::query()->delete();
echo "  • Deleted {$deletedBookings} old test booking records.\n";

// Delete all tenant ledgers
$deletedLedgers = TenantLedger::query()->delete();
echo "  • Deleted {$deletedLedgers} tenant ledger entries.\n";

// Delete all user notifications
$deletedNotifications = UserNotification::query()->delete();
echo "  • Deleted {$deletedNotifications} notification inbox entries.\n";

// Clear tenant_customers CRM table
$deletedCrm = DB::table('tenant_customers')->delete();
echo "  • Cleared {$deletedCrm} CRM customer records.\n";

echo "========================================================================\n";
echo "✅ DATABASE IS NOW 100% FRESH & READY FOR CLEAN TESTING!\n";
echo "========================================================================\n";

