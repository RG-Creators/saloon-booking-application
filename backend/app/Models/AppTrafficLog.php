<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppTrafficLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'ip_address',
        'endpoint',
        'method',
        'device_model',
        'app_version',
        'user_id',
        'tenant_id',
        'status_code',
        'last_seen_at',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
