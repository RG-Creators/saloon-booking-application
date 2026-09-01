<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use App\Models\AppCrashLog;
use App\Models\AppTrafficLog;
use App\Models\BlockedIp;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminLogController extends Controller
{
    public function index()
    {
        $logs = ActivityLog::with('user')->latest()->paginate(20);
        return view('admin.logs', compact('logs'));
    }

    public function crashLogs(Request $request)
    {
        $search = $request->input('search');
        $tab = $request->input('tab', 'crash'); // 'crash', 'traffic', 'blocked'

        // 1. Crash Reports
        $crashQuery = AppCrashLog::with(['user', 'tenant'])->latest();
        if ($search) {
            $crashQuery->where(function ($q) use ($search) {
                $q->where('error_message', 'like', "%{$search}%")
                  ->orWhere('device_model', 'like', "%{$search}%")
                  ->orWhere('ip_address', 'like', "%{$search}%");
            });
        }
        $crashLogs = $crashQuery->paginate(30, ['*'], 'crash_page');

        // 2. IP Traffic Tracker (Grouped by IP with live stats)
        $trafficQuery = AppTrafficLog::select(
            'ip_address',
            DB::raw('MAX(last_seen_at) as latest_activity'),
            DB::raw('COUNT(*) as total_requests'),
            DB::raw('MAX(device_model) as last_device'),
            DB::raw('MAX(app_version) as last_app_version'),
            DB::raw('MAX(user_id) as last_user_id'),
            DB::raw('MAX(tenant_id) as last_tenant_id')
        )->groupBy('ip_address')->orderByDesc('latest_activity');

        if ($search) {
            $trafficQuery->where('ip_address', 'like', "%{$search}%")
                         ->orWhere('device_model', 'like', "%{$search}%");
        }
        $trafficLogs = $trafficQuery->paginate(30, ['*'], 'traffic_page');

        // 3. Blocked IPs list
        $blockedIps = BlockedIp::with('blocker')->latest()->paginate(30, ['*'], 'blocked_page');
        $blockedIpList = BlockedIp::pluck('ip_address')->toArray();

        return view('admin.crash_logs', compact(
            'crashLogs',
            'trafficLogs',
            'blockedIps',
            'blockedIpList',
            'tab',
            'search'
        ));
    }

    /**
     * Block an IP Address
     */
    public function blockIp(Request $request)
    {
        $validated = $request->validate([
            'ip_address' => 'required|string|max:45',
            'reason' => 'nullable|string|max:255',
        ]);

        $ip = trim($validated['ip_address']);

        BlockedIp::firstOrCreate(
            ['ip_address' => $ip],
            [
                'reason' => $validated['reason'] ?? 'Blocked via Super Admin Console',
                'blocked_by_user_id' => auth()->id(),
            ]
        );

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Blocked IP Address',
            'description' => "Blocked IP address {$ip}. Reason: " . ($validated['reason'] ?? 'Admin manual block'),
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "IP address {$ip} has been blocked successfully.");
    }

    /**
     * Unblock an IP Address
     */
    public function unblockIp(Request $request)
    {
        $validated = $request->validate([
            'ip_address' => 'required|string|max:45',
        ]);

        $ip = trim($validated['ip_address']);
        BlockedIp::where('ip_address', $ip)->delete();

        ActivityLog::create([
            'user_id' => auth()->id(),
            'action' => 'Unblocked IP Address',
            'description' => "Unblocked IP address {$ip}.",
            'ip_address' => $request->ip()
        ]);

        return back()->with('success', "IP address {$ip} has been unblocked successfully.");
    }
}
