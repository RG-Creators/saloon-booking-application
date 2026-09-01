<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OffPeakDiscount extends Model
{
    protected $fillable = [
        'tenant_id',
        'branch_id',
        'title',
        'discount_percent',
        'days_of_week',
        'start_time',
        'end_time',
        'time_window',
        'is_active',
    ];

    protected $casts = [
        'discount_percent' => 'float',
        'days_of_week'     => 'array',
        'is_active'        => 'boolean',
    ];

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }
}
