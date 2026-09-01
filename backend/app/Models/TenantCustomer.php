<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TenantCustomer extends Model
{
    protected $fillable = [
        'tenant_id',
        'user_id',
        'name',
        'phone',
        'email',
        'gender',
        'notes',
        'is_vip',
        'total_bookings',
        'total_spent',
        'is_added',
        'source',
    ];

    protected $casts = [
        'is_vip'         => 'boolean',
        'is_added'       => 'boolean',
        'total_bookings' => 'integer',
        'total_spent'    => 'float',
    ];

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
