<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['tenant_id', 'name', 'address', 'city', 'state', 'pin_code', 'latitude', 'longitude', 'contact_mobile', 'contact_email', 'is_active'])]
class Branch extends Model
{
    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function tenant() { return $this->belongsTo(Tenant::class); }
    public function services() { return $this->hasMany(Service::class); }
    public function combos() { return $this->hasMany(ServiceCombo::class); }
    public function staff() { return $this->hasMany(Staff::class); }
    public function workingHours() { return $this->hasMany(BranchWorkingHour::class); }
}
