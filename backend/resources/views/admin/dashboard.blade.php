@extends('layouts.admin')

@section('title', 'Platform Overview')

@section('content')
    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        
        <div class="bg-white rounded-2xl shadow-xs p-6 border border-slate-200/80 flex items-center justify-between hover:shadow-md hover:-translate-y-0.5 transition duration-200">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Total Businesses</p>
                <h3 class="text-3xl font-extrabold text-slate-900 tracking-tight">{{ $stats['total_tenants'] }}</h3>
            </div>
            <div class="w-13 h-13 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white text-xl shadow-md">
                <i class="fas fa-store"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl shadow-xs p-6 border border-slate-200/80 flex items-center justify-between hover:shadow-md hover:-translate-y-0.5 transition duration-200">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Active Outlets</p>
                <h3 class="text-3xl font-extrabold text-slate-900 tracking-tight">{{ $stats['active_branches'] }}</h3>
            </div>
            <div class="w-13 h-13 rounded-2xl bg-gradient-to-tr from-emerald-500 to-teal-600 flex items-center justify-center text-white text-xl shadow-md">
                <i class="fas fa-code-branch"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl shadow-xs p-6 border border-slate-200/80 flex items-center justify-between hover:shadow-md hover:-translate-y-0.5 transition duration-200">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Total Users</p>
                <h3 class="text-3xl font-extrabold text-slate-900 tracking-tight">{{ $stats['total_users'] }}</h3>
            </div>
            <div class="w-13 h-13 rounded-2xl bg-gradient-to-tr from-purple-600 to-pink-600 flex items-center justify-center text-white text-xl shadow-md">
                <i class="fas fa-users"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl shadow-xs p-6 border border-slate-200/80 flex items-center justify-between hover:shadow-md hover:-translate-y-0.5 transition duration-200">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Total Appointments</p>
                <h3 class="text-3xl font-extrabold text-slate-900 tracking-tight">{{ $stats['total_bookings'] }}</h3>
            </div>
            <div class="w-13 h-13 rounded-2xl bg-gradient-to-tr from-amber-500 to-orange-600 flex items-center justify-center text-white text-xl shadow-md">
                <i class="fas fa-calendar-check"></i>
            </div>
        </div>
    </div>

    <!-- Recent Tenants Table -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 class="text-lg font-semibold text-gray-800">Recently Onboarded Businesses</h3>
            <a href="/admin/tenants" class="text-sm text-blue-600 hover:text-blue-800 font-medium">View All &rarr;</a>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-medium">Business Name</th>
                        <th class="px-6 py-4 font-medium">Type</th>
                        <th class="px-6 py-4 font-medium">Status</th>
                        <th class="px-6 py-4 font-medium">Joined Date</th>
                        <th class="px-6 py-4 font-medium text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @forelse($recentTenants as $tenant)
                    <tr class="hover:bg-gray-50/50 transition-colors">
                        <td class="px-6 py-4 font-medium text-gray-900">{{ $tenant->business_name }}</td>
                        <td class="px-6 py-4 text-gray-500">{{ $tenant->business_type }}</td>
                        <td class="px-6 py-4">
                            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium 
                                {{ $tenant->status === 'ACTIVE' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800' }}">
                                {{ $tenant->status }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-500">{{ $tenant->created_at->format('M d, Y') }}</td>
                        <td class="px-6 py-4 text-right">
                            <a href="{{ route('admin.tenants') }}" class="text-blue-600 hover:text-blue-900 text-sm font-medium">Manage</a>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                            <i class="fas fa-store-slash text-3xl mb-3 text-gray-300"></i>
                            <p>No businesses have onboarded yet.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- My Permissions (Subadmin Only) -->
    @if(auth()->user()->hasRole('SUBADMIN'))
    <div class="mt-8 bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 bg-blue-50/30">
            <h3 class="text-lg font-semibold text-gray-800"><i class="fas fa-id-badge text-blue-500 mr-2"></i> My Active Permissions</h3>
            <p class="text-sm text-gray-500 mt-1">These are the specific capabilities granted to your Subadmin account.</p>
        </div>
        <div class="p-6">
            <div class="flex flex-wrap gap-3">
                @forelse(auth()->user()->getAllPermissions() as $permission)
                    <span class="inline-flex items-center px-3 py-1.5 rounded-lg text-sm font-medium bg-blue-100 text-blue-800 border border-blue-200">
                        <i class="fas fa-check-circle mr-2 text-blue-500"></i> {{ ucwords($permission->name) }}
                    </span>
                @empty
                    <p class="text-gray-500 italic">No special permissions have been granted to your account yet.</p>
                @endforelse
            </div>
        </div>
    </div>
    @endif
@endsection
