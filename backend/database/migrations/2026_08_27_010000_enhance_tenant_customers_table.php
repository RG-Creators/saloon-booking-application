<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tenant_customers')) {
            Schema::table('tenant_customers', function (Blueprint $table) {
                // Drop foreign key on user_id if needed to make it nullable
                if (Schema::hasColumn('tenant_customers', 'user_id')) {
                    $table->dropForeign(['user_id']);
                }
            });

            Schema::table('tenant_customers', function (Blueprint $table) {
                if (Schema::hasColumn('tenant_customers', 'user_id')) {
                    $table->foreignId('user_id')->nullable()->change()->constrained('users')->nullOnDelete();
                } else {
                    $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                }

                if (!Schema::hasColumn('tenant_customers', 'name')) {
                    $table->string('name')->default('Valued Client')->after('user_id');
                }
                if (!Schema::hasColumn('tenant_customers', 'phone')) {
                    $table->string('phone')->nullable()->index()->after('name');
                }
                if (!Schema::hasColumn('tenant_customers', 'email')) {
                    $table->string('email')->nullable()->after('phone');
                }
                if (!Schema::hasColumn('tenant_customers', 'gender')) {
                    $table->string('gender')->nullable()->after('email');
                }
                if (!Schema::hasColumn('tenant_customers', 'is_vip')) {
                    $table->boolean('is_vip')->default(false)->after('notes');
                }
                if (!Schema::hasColumn('tenant_customers', 'total_bookings')) {
                    $table->integer('total_bookings')->default(0)->after('is_vip');
                }
                if (!Schema::hasColumn('tenant_customers', 'total_spent')) {
                    $table->decimal('total_spent', 10, 2)->default(0.00)->after('total_bookings');
                }
                if (!Schema::hasColumn('tenant_customers', 'source')) {
                    $table->string('source')->default('MANUAL')->after('total_spent');
                }
            });
        } else {
            Schema::create('tenant_customers', function (Blueprint $table) {
                $table->id();
                $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('name');
                $table->string('phone')->index();
                $table->string('email')->nullable();
                $table->string('gender')->nullable();
                $table->text('notes')->nullable();
                $table->boolean('is_vip')->default(false);
                $table->integer('total_bookings')->default(0);
                $table->decimal('total_spent', 10, 2)->default(0.00);
                $table->boolean('is_added')->default(true);
                $table->string('source')->default('MANUAL');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        // No down needed for upgrade
    }
};
