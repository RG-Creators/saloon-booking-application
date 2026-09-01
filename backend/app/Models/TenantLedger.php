<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TenantLedger extends Model
{
    protected $fillable = [
        'tenant_id',
        'booking_id',
        'amount',
        'type',
        'description',
        'status',
        'razorpay_order_id',
        'razorpay_payment_id',
        'razorpay_signature',
        'settled_at',
    ];
    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }
}
