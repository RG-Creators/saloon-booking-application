<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable([
    'tenant_id', 'branch_id', 'service_id', 'combo_id', 'staff_id', 'user_id', 
    'booking_type', 'service_address', 'address_landmark', 'occasion_type', 'travel_fee',
    'booking_date', 'start_time', 'end_time', 'status', 'decline_reason', 'lock_note', 
    'amount', 'payment_status', 'lock_expires_at'
])]
class Booking extends Model
{
    protected $casts = [
        'amount'     => 'float',
        'travel_fee' => 'float',
    ];

    public function tenant() { return $this->belongsTo(Tenant::class); }
    public function branch() { return $this->belongsTo(Branch::class); }
    public function service() { return $this->belongsTo(Service::class); }
    public function combo() { return $this->belongsTo(ServiceCombo::class, 'combo_id'); }
    public function staff() { return $this->belongsTo(Staff::class); }
    public function customer() { return $this->belongsTo(User::class, 'user_id'); }
    public function user() { return $this->customer(); }
}
