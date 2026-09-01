<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RushPricingRule extends Model
{
    protected $fillable = [
        'tenant_id',
        'branch_id',
        'title',
        'surge_amount',
        'days_of_week',
        'start_time',
        'end_time',
        'time_slot',
        'is_enabled',
    ];

    protected $casts = [
        'surge_amount' => 'float',
        'days_of_week' => 'array',
        'is_enabled'   => 'boolean',
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
