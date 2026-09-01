<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use App\Models\AppCrashLog;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Auto clear crash logs older than 5 hours
Schedule::call(function () {
    AppCrashLog::where('created_at', '<', now()->subHours(5))->delete();
})->hourly();
