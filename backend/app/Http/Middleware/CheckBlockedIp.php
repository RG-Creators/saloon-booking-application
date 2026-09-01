<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\BlockedIp;
use App\Models\AppTrafficLog;

class CheckBlockedIp
{
    /**
     * Check if client IP is blocked, and record traffic log for mobile/API requests.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $ip = $request->ip();

        // 1. 🛡️ Check if IP is in Blocked list
        if ($ip && BlockedIp::isBlocked($ip)) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Access Denied: Your IP address has been blocked by the system administrator.',
                    'blocked_ip' => $ip,
                ], 403);
            }

            abort(403, 'Your IP address (' . $ip . ') has been blocked by the platform administrator.');
        }

        $response = $next($request);

        // 2. 📊 Record Traffic Log for API & Mobile requests (non-blocking)
        try {
            if ($request->is('api/*') && $ip) {
                // Keep recent log updated
                $endpoint = substr($request->path(), 0, 190);
                $deviceModel = $request->header('X-Device-Model', $request->header('User-Agent'));
                $appVersion = $request->header('X-App-Version', '1.0.0');

                // Upsert or insert traffic log entry
                AppTrafficLog::create([
                    'ip_address' => $ip,
                    'endpoint' => $endpoint,
                    'method' => $request->method(),
                    'device_model' => substr($deviceModel ?? 'Unknown Device', 0, 100),
                    'app_version' => substr($appVersion ?? '1.0.0', 0, 30),
                    'user_id' => auth('sanctum')->id() ?? auth()->id(),
                    'tenant_id' => auth('sanctum')->user()?->tenant_id ?? auth()->user()?->tenant_id,
                    'status_code' => $response->getStatusCode(),
                    'last_seen_at' => now(),
                ]);
            }
        } catch (\Throwable $e) {
            // Ignore logging errors so request is never interrupted
        }

        return $response;
    }
}
