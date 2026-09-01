<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

class Tenant extends Model
{
    protected $fillable = [
        'business_name', 'business_type', 'logo', 'cover_image', 'verification_image',
        'description', 'status', 'booking_policy', 'crm_only_booking', 'notification_target', 
        'billing_enabled', 'booking_fee_enabled', 'booking_fee_amount',
        'cancellation_buffer_minutes', 'prebooking_token_amount', 'consecutive_declines_limit',
        'home_service_enabled', 'event_wedding_enabled', 'home_service_radius_km',
        'home_service_travel_fee', 'event_min_booking_amount', 'home_service_notes'
    ];

    protected $casts = [
        'crm_only_booking'             => 'boolean',
        'cancellation_buffer_minutes'  => 'integer',
        'prebooking_token_amount'      => 'float',
        'consecutive_declines_limit'   => 'integer',
        'home_service_enabled'         => 'boolean',
        'event_wedding_enabled'        => 'boolean',
        'home_service_radius_km'       => 'integer',
        'home_service_travel_fee'      => 'float',
        'event_min_booking_amount'     => 'float',
    ];
    public function branches()
    {
        return $this->hasMany(Branch::class);
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function addedCustomers()
    {
        return $this->belongsToMany(User::class, 'tenant_customers')->withPivot('is_added', 'notes')->withTimestamps();
    }
}
