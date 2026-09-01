<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['branch_id', 'user_id', 'name', 'mobile', 'email', 'photo', 'is_bookable', 'is_active', 'role'])]
class Staff extends Model
{
    public function branch() { return $this->belongsTo(Branch::class); }
    public function user() { return $this->belongsTo(User::class); }
    public function services() { return $this->belongsToMany(Service::class, 'staff_services'); }
    public function workingHours() { return $this->hasMany(StaffWorkingHour::class); }
    public function holidays() { return $this->hasMany(StaffHoliday::class); }
}
