<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tenant = App\Models\Tenant::where('business_name', 'like', '%Grooming%')->first();
if (!$tenant) {
    echo "Tenant not found.\n";
    exit;
}

$branches = App\Models\Branch::where('tenant_id', $tenant->id)->get();
$branchIds = $branches->pluck('id')->toArray();

$services = App\Models\Service::whereIn('branch_id', $branchIds)->get();
$combos = App\Models\ServiceCombo::whereIn('branch_id', $branchIds)->get();
$staff = App\Models\Staff::whereIn('branch_id', $branchIds)->get();
$bookings = App\Models\Booking::whereIn('branch_id', $branchIds)->get();

$data = [
    'tenant' => $tenant->toArray(),
    'branches' => $branches->toArray(),
    'services' => $services->toArray(),
    'combos' => $combos->toArray(),
    'staff' => $staff->toArray(),
    'bookings' => $bookings->toArray()
];

echo json_encode($data, JSON_PRETTY_PRINT);
