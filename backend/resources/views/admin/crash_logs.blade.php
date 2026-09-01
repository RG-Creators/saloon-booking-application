@extends('layouts.admin')

@section('title', 'App Crash Reports & Live IP Traffic Monitor')

@section('content')
<div class="space-y-6">
    <!-- Top Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center justify-between">
            <div>
                <div class="text-xs font-bold text-gray-400 uppercase tracking-wider">Uncaught App Crashes</div>
                <div class="text-2xl font-black text-gray-900 mt-1">{{ $crashLogs->total() }}</div>
                <div class="text-xs text-rose-500 font-semibold mt-0.5 flex items-center">
                    <span class="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping mr-1.5"></span> Live App Exceptions
                </div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-rose-50 flex items-center justify-center text-rose-600">
                <i class="fas fa-bug text-xl"></i>
            </div>
        </div>

        <div class="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center justify-between">
            <div>
                <div class="text-xs font-bold text-gray-400 uppercase tracking-wider">Active Device IPs</div>
                <div class="text-2xl font-black text-gray-900 mt-1">{{ $trafficLogs->total() }}</div>
                <div class="text-xs text-emerald-600 font-semibold mt-0.5">Connected client endpoints</div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600">
                <i class="fas fa-network-wired text-xl"></i>
            </div>
        </div>

        <div class="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center justify-between">
            <div>
                <div class="text-xs font-bold text-gray-400 uppercase tracking-wider">Blocked IPs (Firewall)</div>
                <div class="text-2xl font-black text-gray-900 mt-1">{{ $blockedIps->total() }}</div>
                <div class="text-xs text-amber-600 font-semibold mt-0.5">Blocked from accessing API</div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600">
                <i class="fas fa-shield-alt text-xl"></i>
            </div>
        </div>
    </div>

    <!-- Main Container with Tabs -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <!-- Header & Tab Switcher -->
        <div class="px-6 py-4 border-b border-gray-100 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gray-50/50">
            <!-- Tabs -->
            <div class="flex items-center space-x-2 bg-gray-200/60 p-1 rounded-xl">
                <a href="{{ route('admin.crash-logs', ['tab' => 'crash', 'search' => $search]) }}"
                   class="px-4 py-2 rounded-lg text-xs font-bold transition flex items-center space-x-1.5 {{ $tab === 'crash' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900' }}">
                    <i class="fas fa-exclamation-triangle text-rose-500"></i>
                    <span>Crash Reports</span>
                    <span class="bg-rose-100 text-rose-700 px-1.5 py-0.5 rounded-full text-[10px]">{{ $crashLogs->total() }}</span>
                </a>
                <a href="{{ route('admin.crash-logs', ['tab' => 'traffic', 'search' => $search]) }}"
                   class="px-4 py-2 rounded-lg text-xs font-bold transition flex items-center space-x-1.5 {{ $tab === 'traffic' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900' }}">
                    <i class="fas fa-satellite-dish text-indigo-500"></i>
                    <span>Live IP Inspector</span>
                    <span class="bg-indigo-100 text-indigo-700 px-1.5 py-0.5 rounded-full text-[10px]">{{ $trafficLogs->total() }}</span>
                </a>
                <a href="{{ route('admin.crash-logs', ['tab' => 'blocked', 'search' => $search]) }}"
                   class="px-4 py-2 rounded-lg text-xs font-bold transition flex items-center space-x-1.5 {{ $tab === 'blocked' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900' }}">
                    <i class="fas fa-ban text-amber-500"></i>
                    <span>Blocked IPs</span>
                    <span class="bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded-full text-[10px]">{{ $blockedIps->total() }}</span>
                </a>
            </div>

            <!-- Search & Actions -->
            <div class="flex items-center space-x-3">
                <form action="{{ route('admin.crash-logs') }}" method="GET" class="flex items-center">
                    <input type="hidden" name="tab" value="{{ $tab }}">
                    <div class="relative">
                        <i class="fas fa-search absolute left-3 top-2.5 text-gray-400 text-xs"></i>
                        <input type="text" name="search" value="{{ $search }}" placeholder="Search IP, error, device..."
                               class="pl-8 pr-3 py-1.5 bg-white border border-gray-200 rounded-xl text-xs outline-none focus:ring-2 focus:ring-indigo-500 w-48 md:w-64 transition">
                    </div>
                </form>

                <button onclick="document.getElementById('manual-block-modal').classList.remove('hidden')"
                        class="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-1.5 whitespace-nowrap">
                    <i class="fas fa-plus-circle"></i>
                    <span>Block An IP</span>
                </button>
            </div>
        </div>

        <!-- 1. TAB: Crash Reports -->
        @if($tab === 'crash')
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-gray-50/50 text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-3.5 font-semibold">Time</th>
                        <th class="px-6 py-3.5 font-semibold">IP Address & Location</th>
                        <th class="px-6 py-3.5 font-semibold">Device & Version</th>
                        <th class="px-6 py-3.5 font-semibold">Crash Exception</th>
                        <th class="px-6 py-3.5 font-semibold text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($crashLogs as $log)
                    @php $isBlocked = in_array($log->ip_address, $blockedIpList); @endphp
                    <tr class="hover:bg-rose-50/30 transition">
                        <td class="px-6 py-4 text-gray-500 text-xs whitespace-nowrap">
                            <div class="font-bold text-gray-800">{{ $log->created_at->format('M d, H:i:s') }}</div>
                            <div class="text-[11px] text-gray-400">{{ $log->created_at->diffForHumans() }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            @if($log->ip_address)
                                <div class="font-mono text-xs font-bold text-gray-900 flex items-center space-x-1.5">
                                    <i class="fas fa-globe text-gray-400"></i>
                                    <span>{{ $log->ip_address }}</span>
                                </div>
                                @if($isBlocked)
                                    <span class="inline-block mt-1 text-[10px] font-extrabold bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full">BLOCKED</span>
                                @endif
                            @else
                                <span class="text-gray-400 text-xs italic">Unknown IP</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="font-bold text-gray-900 text-xs">{{ $log->device_model ?? 'Mobile Device' }}</div>
                            <div class="text-[11px] text-gray-500">App v{{ $log->app_version ?? '1.0' }} • OS: {{ $log->os_version ?? 'Unknown' }}</div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="font-bold text-rose-600 text-xs line-clamp-1 max-w-md">{{ $log->error_message }}</div>
                            <button onclick="showStackTraceModal(`{{ addslashes($log->error_message) }}`, `{{ addslashes($log->stack_trace) }}`)"
                                    class="text-[11px] text-indigo-600 font-bold mt-0.5 hover:underline inline-flex items-center space-x-1">
                                <i class="fas fa-code"></i>
                                <span>Inspect Stack Trace</span>
                            </button>
                        </td>
                        <td class="px-6 py-4 text-right whitespace-nowrap">
                            @if($log->ip_address)
                                @if($isBlocked)
                                    <form action="{{ route('admin.ip.unblock') }}" method="POST" class="inline">
                                        @csrf
                                        <input type="hidden" name="ip_address" value="{{ $log->ip_address }}">
                                        <button type="submit" class="px-3 py-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-bold rounded-lg transition border border-emerald-200">
                                            <i class="fas fa-unlock-alt mr-1"></i> Unblock IP
                                        </button>
                                    </form>
                                @else
                                    <button onclick="openBlockModal(`{{ $log->ip_address }}`)" class="px-3 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold rounded-lg transition border border-rose-200">
                                        <i class="fas fa-ban mr-1"></i> Block IP
                                    </button>
                                @endif
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center">
                            <div class="w-12 h-12 rounded-full bg-emerald-50 text-emerald-600 mx-auto flex items-center justify-center mb-2">
                                <i class="fas fa-check text-xl"></i>
                            </div>
                            <div class="text-gray-700 font-bold text-sm">No Crash Reports Found</div>
                            <div class="text-gray-400 text-xs mt-0.5">Your mobile applications are running smoothly without uncaught errors.</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($crashLogs->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $crashLogs->links() }}
        </div>
        @endif
        @endif

        <!-- 2. TAB: Live IP Traffic & Devices -->
        @if($tab === 'traffic')
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-gray-50/50 text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-3.5 font-semibold">IP Address</th>
                        <th class="px-6 py-3.5 font-semibold">Last Seen</th>
                        <th class="px-6 py-3.5 font-semibold">Device & Version</th>
                        <th class="px-6 py-3.5 font-semibold">Total Requests</th>
                        <th class="px-6 py-3.5 font-semibold text-right">Firewall Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($trafficLogs as $traffic)
                    @php $isBlocked = in_array($traffic->ip_address, $blockedIpList); @endphp
                    <tr class="hover:bg-indigo-50/30 transition">
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="font-mono text-xs font-bold text-gray-900 flex items-center space-x-2">
                                <span class="w-2 h-2 rounded-full {{ $isBlocked ? 'bg-rose-500' : 'bg-emerald-500' }}"></span>
                                <span>{{ $traffic->ip_address }}</span>
                            </div>
                            @if($isBlocked)
                                <span class="inline-block mt-1 text-[10px] font-extrabold bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full">BLOCKED ACCESS</span>
                            @else
                                <span class="inline-block mt-1 text-[10px] font-extrabold bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">ACTIVE</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">
                            <div class="font-bold text-gray-800">{{ \Carbon\Carbon::parse($traffic->latest_activity)->format('M d, H:i:s') }}</div>
                            <div class="text-[11px] text-gray-400">{{ \Carbon\Carbon::parse($traffic->latest_activity)->diffForHumans() }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="font-bold text-gray-900 text-xs">{{ $traffic->last_device ?? 'Mobile Device' }}</div>
                            <div class="text-[11px] text-gray-500">App v{{ $traffic->last_app_version ?? '1.0' }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="px-2.5 py-1 bg-gray-100 text-gray-800 text-xs font-bold rounded-lg">
                                {{ number_format($traffic->total_requests) }} calls
                            </span>
                        </td>
                        <td class="px-6 py-4 text-right whitespace-nowrap">
                            @if($isBlocked)
                                <form action="{{ route('admin.ip.unblock') }}" method="POST" class="inline">
                                    @csrf
                                    <input type="hidden" name="ip_address" value="{{ $traffic->ip_address }}">
                                    <button type="submit" class="px-3 py-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-bold rounded-lg transition border border-emerald-200">
                                        <i class="fas fa-unlock-alt mr-1"></i> Unblock IP
                                    </button>
                                </form>
                            @else
                                <button onclick="openBlockModal(`{{ $traffic->ip_address }}`)" class="px-3 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold rounded-lg transition border border-rose-200">
                                    <i class="fas fa-ban mr-1"></i> Block IP
                                </button>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center text-gray-400 text-xs">
                            No IP traffic logged yet. Once mobile devices communicate with the backend, they will appear here automatically.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($trafficLogs->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $trafficLogs->links() }}
        </div>
        @endif
        @endif

        <!-- 3. TAB: Blocked IPs -->
        @if($tab === 'blocked')
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-gray-50/50 text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-3.5 font-semibold">Blocked IP</th>
                        <th class="px-6 py-3.5 font-semibold">Reason</th>
                        <th class="px-6 py-3.5 font-semibold">Blocked Date</th>
                        <th class="px-6 py-3.5 font-semibold">Blocked By</th>
                        <th class="px-6 py-3.5 font-semibold text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($blockedIps as $blocked)
                    <tr class="hover:bg-amber-50/30 transition">
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="font-mono text-xs font-bold text-rose-600 flex items-center space-x-1.5">
                                <i class="fas fa-ban"></i>
                                <span>{{ $blocked->ip_address }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-700">
                            {{ $blocked->reason ?? 'Manual Block' }}
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">
                            {{ $blocked->created_at->format('M d, Y H:i') }}
                        </td>
                        <td class="px-6 py-4 text-xs font-bold text-gray-800 whitespace-nowrap">
                            {{ $blocked->blocker?->name ?? 'Super Admin' }}
                        </td>
                        <td class="px-6 py-4 text-right whitespace-nowrap">
                            <form action="{{ route('admin.ip.unblock') }}" method="POST" class="inline">
                                @csrf
                                <input type="hidden" name="ip_address" value="{{ $blocked->ip_address }}">
                                <button type="submit" class="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition shadow-sm">
                                    <i class="fas fa-unlock mr-1"></i> Unblock
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center">
                            <div class="w-12 h-12 rounded-full bg-gray-50 text-gray-400 mx-auto flex items-center justify-center mb-2">
                                <i class="fas fa-shield-alt text-xl"></i>
                            </div>
                            <div class="text-gray-700 font-bold text-sm">No Blocked IPs</div>
                            <div class="text-gray-400 text-xs mt-0.5">Your firewall has no active IP blocks.</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($blockedIps->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $blockedIps->links() }}
        </div>
        @endif
        @endif
    </div>
</div>

<!-- Modal: Block IP Form -->
<div id="manual-block-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 hidden">
    <div class="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-gray-100 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-base font-extrabold text-gray-900 flex items-center space-x-2">
                <span class="w-8 h-8 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center">
                    <i class="fas fa-shield-virus"></i>
                </span>
                <span>Block IP Address</span>
            </h3>
            <button onclick="document.getElementById('manual-block-modal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times"></i>
            </button>
        </div>

        <form action="{{ route('admin.ip.block') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-bold text-gray-700 mb-1">IP Address to Block</label>
                <input type="text" name="ip_address" id="modal-ip-input" required placeholder="e.g. 192.168.1.100"
                       class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-mono outline-none focus:ring-2 focus:ring-rose-500">
            </div>

            <div>
                <label class="block text-xs font-bold text-gray-700 mb-1">Reason for Blocking (Optional)</label>
                <input type="text" name="reason" placeholder="e.g. Suspicious automated activity or spam"
                       class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-rose-500">
            </div>

            <div class="p-3 bg-amber-50 rounded-xl border border-amber-200 text-amber-800 text-xs">
                <i class="fas fa-info-circle mr-1"></i>
                Requests from this IP will instantly be rejected with a <strong>403 Forbidden</strong> response across web & mobile apps.
            </div>

            <div class="flex items-center justify-end space-x-3 pt-2">
                <button type="button" onclick="document.getElementById('manual-block-modal').classList.add('hidden')"
                        class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-bold rounded-xl transition">
                    Cancel
                </button>
                <button type="submit" class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-xl transition shadow-sm">
                    Confirm & Block IP
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Stack Trace Viewer -->
<div id="stack-trace-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 hidden">
    <div class="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-xl border border-gray-100">
        <div class="flex justify-between items-center mb-3">
            <h3 class="text-base font-extrabold text-gray-900 flex items-center space-x-2">
                <span class="w-8 h-8 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center">
                    <i class="fas fa-terminal"></i>
                </span>
                <span>Crash Stack Trace</span>
            </h3>
            <button onclick="document.getElementById('stack-trace-modal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times"></i>
            </button>
        </div>

        <div class="mb-3">
            <div class="text-xs font-bold text-gray-500 mb-1">Error Message:</div>
            <div id="stack-error-message" class="text-xs font-bold text-rose-700 bg-rose-50 p-2.5 rounded-xl border border-rose-100 font-mono break-all"></div>
        </div>

        <div>
            <div class="text-xs font-bold text-gray-500 mb-1">Trace Details:</div>
            <pre id="stack-trace-content" class="bg-gray-900 text-gray-200 p-4 rounded-xl text-xs font-mono max-h-72 overflow-y-auto whitespace-pre-wrap select-all"></pre>
        </div>

        <div class="flex justify-end pt-4">
            <button type="button" onclick="document.getElementById('stack-trace-modal').classList.add('hidden')"
                    class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-bold rounded-xl transition">
                Close
            </button>
        </div>
    </div>
</div>

<script>
    function openBlockModal(ip) {
        document.getElementById('modal-ip-input').value = ip;
        document.getElementById('manual-block-modal').classList.remove('hidden');
    }

    function showStackTraceModal(error, trace) {
        document.getElementById('stack-error-message').innerText = error || 'Unknown Error';
        document.getElementById('stack-trace-content').innerText = trace || 'No stack trace recorded for this exception.';
        document.getElementById('stack-trace-modal').classList.remove('hidden');
    }
</script>
@endsection
