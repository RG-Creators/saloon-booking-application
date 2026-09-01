@extends('layouts.admin')

@section('title', 'Platform Audit Logs')

@section('content')
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 class="text-lg font-semibold text-gray-800">Security & Activity Audit</h3>
            <p class="text-sm text-gray-500">Track all actions performed by Subadmins and Super Admins.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-medium">Timestamp</th>
                        <th class="px-6 py-4 font-medium">User</th>
                        <th class="px-6 py-4 font-medium">Action</th>
                        <th class="px-6 py-4 font-medium">Details</th>
                        <th class="px-6 py-4 font-medium text-right">IP Address</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @forelse($logs as $log)
                    <tr class="hover:bg-gray-50/50 transition-colors">
                        <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">{{ $log->created_at->format('M d, H:i A') }}</td>
                        <td class="px-6 py-4 font-medium text-gray-900">
                            @if($log->user)
                                {{ $log->user->name }}
                                <span class="text-xs text-gray-400 block">{{ $log->user->email }}</span>
                            @else
                                <span class="text-gray-400 italic">System</span>
                            @endif
                        </td>
                        <td class="px-6 py-4">
                            <span class="inline-flex items-center px-2.5 py-1 rounded text-xs font-semibold bg-gray-100 text-gray-800">
                                {{ $log->action }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-600">{{ $log->description }}</td>
                        <td class="px-6 py-4 text-sm text-gray-400 text-right font-mono">{{ $log->ip_address ?? 'N/A' }}</td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center text-gray-500">
                            <i class="fas fa-clipboard-list text-4xl mb-4 text-gray-300"></i>
                            <p class="text-lg">No audit logs found.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($logs->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $logs->links() }}
        </div>
        @endif
    </div>
@endsection
