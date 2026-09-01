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
        // 1. Enhance Tenants Table with Home & Event/Wedding Service configurations
        Schema::table('tenants', function (Blueprint $table) {
            if (!Schema::hasColumn('tenants', 'home_service_enabled')) {
                $table->boolean('home_service_enabled')->default(true)->after('booking_fee_amount');
            }
            if (!Schema::hasColumn('tenants', 'event_wedding_enabled')) {
                $table->boolean('event_wedding_enabled')->default(true)->after('home_service_enabled');
            }
            if (!Schema::hasColumn('tenants', 'home_service_radius_km')) {
                $table->integer('home_service_radius_km')->default(10)->after('event_wedding_enabled');
            }
            if (!Schema::hasColumn('tenants', 'home_service_travel_fee')) {
                $table->decimal('home_service_travel_fee', 10, 2)->default(100.00)->after('home_service_radius_km');
            }
            if (!Schema::hasColumn('tenants', 'event_min_booking_amount')) {
                $table->decimal('event_min_booking_amount', 10, 2)->default(1500.00)->after('home_service_travel_fee');
            }
            if (!Schema::hasColumn('tenants', 'home_service_notes')) {
                $table->text('home_service_notes')->nullable()->after('event_min_booking_amount');
            }
        });

        // 2. Enhance Services Table with Modality & Home Surcharge
        Schema::table('services', function (Blueprint $table) {
            if (!Schema::hasColumn('services', 'service_type')) {
                $table->string('service_type', 30)->default('IN_STUDIO')->after('category'); // IN_STUDIO, AT_HOME, EVENT_WEDDING, ANY
            }
            if (!Schema::hasColumn('services', 'home_surcharge')) {
                $table->decimal('home_surcharge', 10, 2)->default(0.00)->after('price');
            }
        });

        // 3. Enhance Service Combos Table
        Schema::table('service_combos', function (Blueprint $table) {
            if (!Schema::hasColumn('service_combos', 'service_type')) {
                $table->string('service_type', 30)->default('IN_STUDIO')->after('discount');
            }
            if (!Schema::hasColumn('service_combos', 'home_surcharge')) {
                $table->decimal('home_surcharge', 10, 2)->default(0.00)->after('price');
            }
        });

        // 4. Enhance Bookings Table with Home/Event details
        Schema::table('bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('bookings', 'booking_type')) {
                $table->string('booking_type', 30)->default('IN_STUDIO')->after('staff_id'); // IN_STUDIO, AT_HOME, EVENT_WEDDING
            }
            if (!Schema::hasColumn('bookings', 'service_address')) {
                $table->text('service_address')->nullable()->after('booking_type');
            }
            if (!Schema::hasColumn('bookings', 'address_landmark')) {
                $table->string('address_landmark')->nullable()->after('service_address');
            }
            if (!Schema::hasColumn('bookings', 'occasion_type')) {
                $table->string('occasion_type')->nullable()->after('address_landmark'); // Personal, Wedding / Bridal, Party / Event, Photoshoot, etc.
            }
            if (!Schema::hasColumn('bookings', 'travel_fee')) {
                $table->decimal('travel_fee', 10, 2)->default(0.00)->after('amount');
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
                'home_service_enabled',
                'event_wedding_enabled',
                'home_service_radius_km',
                'home_service_travel_fee',
                'event_min_booking_amount',
                'home_service_notes'
            ]);
        });

        Schema::table('services', function (Blueprint $table) {
            $table->dropColumn(['service_type', 'home_surcharge']);
        });

        Schema::table('service_combos', function (Blueprint $table) {
            $table->dropColumn(['service_type', 'home_surcharge']);
        });

        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn([
                'booking_type',
                'service_address',
                'address_landmark',
                'occasion_type',
                'travel_fee'
            ]);
        });
    }
};
