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
        if (!Schema::hasTable('branch_working_hours')) {
            Schema::create('branch_working_hours', function (Blueprint $table) {
                $table->id();
                $table->foreignId('branch_id')->constrained('branches')->cascadeOnDelete();
                $table->tinyInteger('day_of_week'); // 0=Sunday, 1=Monday, ..., 6=Saturday
                $table->boolean('is_open')->default(true);
                $table->time('open_time')->default('10:00:00');
                $table->time('close_time')->default('20:00:00');
                $table->boolean('has_split_shift')->default(false);
                $table->time('split_open_time')->nullable();
                $table->time('split_close_time')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('branch_working_hours');
    }
};
