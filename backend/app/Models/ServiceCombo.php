<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['branch_id', 'name', 'description', 'service_type', 'price', 'home_surcharge', 'discount', 'duration_minutes', 'is_active'])]
class ServiceCombo extends Model
{
    protected $casts = [
        'price'            => 'float',
        'home_surcharge'   => 'float',
        'discount'         => 'float',
        'duration_minutes' => 'integer',
        'is_active'        => 'boolean',
    ];

    public function branch() { return $this->belongsTo(Branch::class); }
    public function services() { return $this->belongsToMany(Service::class, 'combo_services', 'service_combo_id', 'service_id'); }
}
