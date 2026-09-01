<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class BlockedIp extends Model
{
    use HasFactory;

    protected $fillable = [
        'ip_address',
        'reason',
        'blocked_by_user_id',
    ];

    public function blocker()
    {
        return $this->belongsTo(User::class, 'blocked_by_user_id');
    }

    /**
     * Check if an IP address is blocked (cached for 60 seconds for performance)
     */
    public static function isBlocked(string $ip): bool
    {
        return Cache::remember("ip_blocked_{$ip}", 60, function () use ($ip) {
            return static::where('ip_address', $ip)->exists();
        });
    }

    /**
     * Clear cache when creating or deleting a blocked IP
     */
    protected static function booted()
    {
        static::saved(function ($blockedIp) {
            Cache::forget("ip_blocked_{$blockedIp->ip_address}");
        });

        static::deleted(function ($blockedIp) {
            Cache::forget("ip_blocked_{$blockedIp->ip_address}");
        });
    }
}
