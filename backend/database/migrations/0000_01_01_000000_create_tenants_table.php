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
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();
            $table->string('business_name');
            $table->string('business_type')->nullable(); // Barber, Salon, etc.
            $table->string('logo')->nullable();
            $table->string('cover_image')->nullable();
            $table->string('verification_image')->nullable();
            $table->text('description')->nullable();
            $table->string('status')->default('PENDING'); // PENDING, UNDER_REVIEW, VERIFIED, REJECTED, SUSPENDED
            $table->string('booking_policy', 50)->default('PAY_AT_SALON'); // PAY_AT_SALON, PREPAYMENT_REQUIRED_ALL, PREPAYMENT_REQUIRED_NEW, ADDED_CUSTOMERS_ONLY
            $table->string('notification_target', 50)->default('DISPATCH_TO_BOTH'); // DISPATCH_TO_BOTH, DISPATCH_TO_STAFF, DISPATCH_TO_OWNER
            $table->boolean('billing_enabled')->default(false);
            $table->boolean('booking_fee_enabled')->default(false);
            $table->decimal('booking_fee_amount', 8, 2)->default(1.00);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tenants');
    }
};
