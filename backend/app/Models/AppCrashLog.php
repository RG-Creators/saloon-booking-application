<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppCrashLog extends Model
{
    use HasFactory;
    
    protected $fillable = [
        'user_id',
        'tenant_id',
        'app_version',
        'os_version',
        'error_message',
        'stack_trace',
        'device_model',
        'ip_address',
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
