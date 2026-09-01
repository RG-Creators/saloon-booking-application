<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['branch_id', 'day_of_week', 'is_open', 'open_time', 'close_time', 'has_split_shift', 'split_open_time', 'split_close_time'])]
class BranchWorkingHour extends Model
{
    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }
}
