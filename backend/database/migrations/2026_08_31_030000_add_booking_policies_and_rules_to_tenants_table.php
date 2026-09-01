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
        Schema::table('tenants', function (Blueprint $table) {
            if (!Schema::hasColumn('tenants', 'cancellation_buffer_minutes')) {
                $table->integer('cancellation_buffer_minutes')->default(120)->after('booking_policy'); // 15, 60, 120 (2 hrs), 240 (4 hrs), 1440 (24 hrs)
            }
            if (!Schema::hasColumn('tenants', 'prebooking_token_amount')) {
                $table->decimal('prebooking_token_amount', 10, 2)->default(50.00)->after('cancellation_buffer_minutes');
            }
            if (!Schema::hasColumn('tenants', 'consecutive_declines_limit')) {
                $table->integer('consecutive_declines_limit')->default(3)->after('prebooking_token_amount');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn([
                'cancellation_buffer_minutes',
                'prebooking_token_amount',
                'consecutive_declines_limit'
            ]);
        });
    }
};
