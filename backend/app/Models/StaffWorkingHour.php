<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['staff_id', 'day_of_week', 'start_time', 'end_time', 'break_start', 'break_end', 'is_working_day'])]
class StaffWorkingHour extends Model
{
    public function staff() { return $this->belongsTo(Staff::class); }
}
