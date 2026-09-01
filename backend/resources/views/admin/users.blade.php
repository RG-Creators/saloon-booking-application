@extends('layouts.admin')

@section('title', 'Platform Users & Security Control')

@section('content')
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
        <!-- Header & Search Filter Bar -->
        <div class="px-6 py-5 border-b border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-gray-50/50">
            <div>
                <h3 class="text-lg font-bold text-gray-900">User Management & Security Access Control</h3>
                <p class="text-xs text-gray-500 mt-0.5">View user roles, track login IP addresses, and manage account suspensions.</p>
            </div>
            <form action="{{ route('admin.users') }}" method="GET" class="flex items-center space-x-2">
                <select name="role" onchange="this.form.submit()" class="px-3.5 py-2 bg-white border border-gray-200 rounded-xl text-xs font-semibold outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="">All Roles</option>
                    <option value="SUPER_ADMIN" {{ $roleFilter === 'SUPER_ADMIN' ? 'selected' : '' }}>Super Admin</option>
                    <option value="SUBADMIN" {{ $roleFilter === 'SUBADMIN' ? 'selected' : '' }}>Subadmin</option>
                    <option value="OWNER" {{ $roleFilter === 'OWNER' ? 'selected' : '' }}>Shop Owner</option>
                    <option value="STAFF" {{ $roleFilter === 'STAFF' ? 'selected' : '' }}>Staff / Stylist</option>
                    <option value="CUSTOMER" {{ $roleFilter === 'CUSTOMER' ? 'selected' : '' }}>Customer</option>
                </select>

                <div class="relative">
                    <input type="text" name="q" value="{{ $searchQuery }}" placeholder="Search name or email..." class="pl-8 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-xs outline-none focus:ring-2 focus:ring-blue-500">
                    <i class="fas fa-search absolute left-3 top-2.5 text-gray-400 text-xs"></i>
                </div>

                <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl transition shadow-sm">
                    Filter
                </button>
            </form>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">User Identity</th>
                        <th class="px-6 py-4 font-semibold">Contact & Last IP</th>
                        <th class="px-6 py-4 font-semibold">Assigned Role</th>
                        <th class="px-6 py-4 font-semibold">Salon Tenant</th>
                        <th class="px-6 py-4 font-semibold text-right">Security Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($users as $user)
                    <tr class="hover:bg-gray-50/80 transition-colors {{ $user->is_banned ? 'bg-red-50/30' : '' }}">
                        <td class="px-6 py-4 font-medium text-gray-900">
                            <div class="flex items-center">
                                <div class="w-9 h-9 rounded-full {{ $user->is_banned ? 'bg-red-100 text-red-600' : 'bg-blue-100 text-blue-700' }} flex items-center justify-center font-bold mr-3 text-sm">
                                    {{ substr($user->name, 0, 1) }}
                                </div>
                                <div>
                                    <div class="font-bold text-gray-900">{{ $user->name }}</div>
                                    @if($user->is_banned)
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-800 uppercase mt-0.5">
                                            <i class="fas fa-ban mr-1"></i> Banned / Suspended
                                        </span>
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-600">
                            <div class="font-semibold text-gray-900">{{ $user->email }}</div>
                            <div class="text-[11px] mt-0.5 text-gray-400 font-mono" title="Last Login IP">
                                <i class="fas fa-network-wired text-blue-500 mr-1"></i> {{ $user->last_login_ip ?? '127.0.0.1' }}
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            @foreach($user->roles as $role)
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-800 border border-gray-200">
                                    {{ $role->name }}
                                </span>
                            @endforeach
                        </td>
                        <td class="px-6 py-4 text-xs text-gray-600 font-medium">
                            {{ $user->tenant ? $user->tenant->business_name : 'System Platform' }}
                        </td>
                        <td class="px-6 py-4 text-right">
                            @if($user->hasRole('SUPER_ADMIN'))
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800 border border-amber-200" title="SaaS Owner is the top-most authority and protected from all block actions">
                                    <i class="fas fa-crown text-amber-600 mr-1.5"></i> Top SaaS Owner
                                </span>
                            @elseif(auth()->user()->hasRole('SUBADMIN') && $user->hasRole('SUBADMIN'))
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-purple-50 text-purple-700 border border-purple-100">
                                    <i class="fas fa-shield-alt text-purple-500 mr-1.5"></i> Subadmin Peer
                                </span>
                            @else
                                <form action="{{ route('admin.users.block', $user) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" class="px-3 py-1.5 rounded-xl text-xs font-bold transition shadow-sm {{ $user->is_banned ? 'bg-emerald-600 hover:bg-emerald-700 text-white' : 'bg-red-600 hover:bg-red-700 text-white' }}">
                                        <i class="fas {{ $user->is_banned ? 'fa-unlock mr-1' : 'fa-user-slash mr-1' }}"></i>
                                        {{ $user->is_banned ? 'Unblock User' : 'Block User' }}
                                    </button>
                                </form>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-users-slash text-4xl mb-3 text-gray-300"></i>
                            <p>No matching users found.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($users->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $users->links() }}
        </div>
        @endif
    </div>
@endsection
