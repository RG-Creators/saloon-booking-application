<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tenant_ledgers')) {
            Schema::table('tenant_ledgers', function (Blueprint $table) {
                if (!Schema::hasColumn('tenant_ledgers', 'razorpay_order_id')) {
                    $table->string('razorpay_order_id')->nullable()->after('status');
                }
                if (!Schema::hasColumn('tenant_ledgers', 'razorpay_payment_id')) {
                    $table->string('razorpay_payment_id')->nullable()->after('razorpay_order_id');
                }
                if (!Schema::hasColumn('tenant_ledgers', 'razorpay_signature')) {
                    $table->string('razorpay_signature')->nullable()->after('razorpay_payment_id');
                }
                if (!Schema::hasColumn('tenant_ledgers', 'settled_at')) {
                    $table->timestamp('settled_at')->nullable()->after('razorpay_signature');
                }
            });
        }
    }

    public function down(): void
    {
        Schema::table('tenant_ledgers', function (Blueprint $table) {
            $table->dropColumn(['razorpay_order_id', 'razorpay_payment_id', 'razorpay_signature', 'settled_at']);
        });
    }
};
