<?php

require 'D:/SaaS_booking/backend/vendor/autoload.php';
$app = require_once 'D:/SaaS_booking/backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Http\Controllers\BookingController;
use Illuminate\Http\Request;

$bookingId = 16;
$controller = new BookingController();

$req = Request::create("/api/v1/business/bookings/{$bookingId}/respond", 'POST', [], [], [], [
    'CONTENT_TYPE' => 'application/json',
    'HTTP_ACCEPT' => 'application/json'
], json_encode(['action' => 'DECLINE']));

$res = $controller->respondBooking($req, $bookingId);

echo "STATUS CODE: " . $res->getStatusCode() . "\n";
echo "RESPONSE BODY: " . $res->getContent() . "\n";

