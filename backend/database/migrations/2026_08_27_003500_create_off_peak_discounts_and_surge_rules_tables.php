<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('off_peak_discounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('branch_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->decimal('discount_percent', 5, 2)->default(10.00);
            $table->json('days_of_week')->nullable();
            $table->time('start_time')->default('14:00:00');
            $table->time('end_time')->default('17:00:00');
            $table->string('time_window')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('rush_pricing_rules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('branch_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->decimal('surge_amount', 10, 2)->default(100.00);
            $table->json('days_of_week')->nullable();
            $table->time('start_time')->default('16:00:00');
            $table->time('end_time')->default('20:00:00');
            $table->string('time_slot')->nullable();
            $table->boolean('is_enabled')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rush_pricing_rules');
        Schema::dropIfExists('off_peak_discounts');
    }
};
