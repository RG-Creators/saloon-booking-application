<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['branch_id', 'name', 'description', 'category', 'service_type', 'price', 'home_surcharge', 'duration_minutes', 'buffer_time_minutes', 'image', 'is_active', 'online_booking_enabled'])]
class Service extends Model
{
    protected $casts = [
        'price'                  => 'float',
        'home_surcharge'         => 'float',
        'duration_minutes'       => 'integer',
        'buffer_time_minutes'    => 'integer',
        'is_active'              => 'boolean',
        'online_booking_enabled' => 'boolean',
    ];

    public function branch() { return $this->belongsTo(Branch::class); }
    public function combos() { return $this->belongsToMany(ServiceCombo::class, 'combo_services'); }
    public function staff() { return $this->belongsToMany(Staff::class, 'staff_services'); }
}
