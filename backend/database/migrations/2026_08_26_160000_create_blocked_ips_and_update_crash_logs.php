<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Create blocked_ips table
        if (!Schema::hasTable('blocked_ips')) {
            Schema::create('blocked_ips', function (Blueprint $table) {
                $table->id();
                $table->string('ip_address')->unique()->index();
                $table->string('reason')->nullable();
                $table->unsignedBigInteger('blocked_by_user_id')->nullable();
                $table->timestamps();
            });
        }

        // 2. Add ip_address column to app_crash_logs if not present
        if (Schema::hasTable('app_crash_logs') && !Schema::hasColumn('app_crash_logs', 'ip_address')) {
            Schema::table('app_crash_logs', function (Blueprint $table) {
                $table->string('ip_address')->nullable()->after('device_model')->index();
            });
        }

        // 3. Create app_traffic_logs table for live IP tracking
        if (!Schema::hasTable('app_traffic_logs')) {
            Schema::create('app_traffic_logs', function (Blueprint $table) {
                $table->id();
                $table->string('ip_address')->index();
                $table->string('endpoint')->nullable();
                $table->string('method', 10)->default('GET');
                $table->string('device_model')->nullable();
                $table->string('app_version')->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->unsignedBigInteger('tenant_id')->nullable();
                $table->integer('status_code')->default(200);
                $table->timestamp('last_seen_at')->useCurrent()->index();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('blocked_ips');
        Schema::dropIfExists('app_traffic_logs');
        if (Schema::hasTable('app_crash_logs') && Schema::hasColumn('app_crash_logs', 'ip_address')) {
            Schema::table('app_crash_logs', function (Blueprint $table) {
                $table->dropColumn('ip_address');
            });
        }
    }
};
