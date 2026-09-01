@extends('layouts.admin')

@section('title', 'Subadmin Roles & Permissions')

@section('content')
    @if(session('success'))
        <div class="mb-6 bg-emerald-50 text-emerald-800 p-4 rounded-xl border border-emerald-200 font-semibold text-sm flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-500 mr-2 text-lg"></i> {{ session('success') }}
        </div>
    @endif

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        <!-- Create Subadmin Form -->
        <div class="lg:col-span-1 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden h-fit">
            <div class="px-6 py-5 border-b border-gray-100 bg-gray-50/50">
                <h3 class="text-lg font-bold text-gray-900 flex items-center">
                    <i class="fas fa-user-shield text-blue-600 mr-2"></i> Create Subadmin Account
                </h3>
                <p class="text-xs text-gray-500 mt-1">Delegate specific admin powers to your employee</p>
            </div>
            <div class="p-6">
                <form action="{{ route('admin.subadmins.store') }}" method="POST">
                    @csrf
                    
                    <div class="mb-4">
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Full Name</label>
                        <input type="text" name="name" required placeholder="e.g. John Doe" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                    
                    <div class="mb-4">
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Email Address</label>
                        <input type="email" name="email" required placeholder="employee@glamora.com" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>

                    <div class="mb-6">
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Account Password</label>
                        <input type="password" name="password" required placeholder="••••••••" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                    
                    <h4 class="font-bold text-xs uppercase tracking-wider text-gray-400 mb-3 pb-2 border-b border-gray-100">Granted Capabilities</h4>
                    <div class="space-y-2.5 mb-6">
                        @foreach($permissions as $perm)
                        <label class="flex items-center p-2.5 bg-gray-50 rounded-xl border border-gray-200 hover:bg-blue-50/50 hover:border-blue-200 transition cursor-pointer">
                            <input type="checkbox" name="permissions[]" value="{{ $perm->name }}" id="new_perm_{{ $perm->id }}" class="rounded text-blue-600 focus:ring-blue-500 h-4 w-4 mr-3">
                            <div>
                                <p class="text-xs font-bold text-gray-900">{{ ucwords(str_replace('_', ' ', $perm->name)) }}</p>
                            </div>
                        </label>
                        @endforeach
                    </div>

                    <button type="submit" class="w-full bg-blue-600 text-white py-3 rounded-xl font-bold text-sm hover:bg-blue-700 transition shadow-sm">
                        Create Subadmin User
                    </button>
                </form>
            </div>
        </div>

        <!-- Manage Subadmins List -->
        <div class="lg:col-span-2 space-y-6">
            @forelse($subadmins as $subadmin)
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <div class="flex items-center">
                        <div class="w-10 h-10 rounded-full bg-purple-100 text-purple-700 flex items-center justify-center font-bold mr-3 text-base shadow-sm">
                            {{ substr($subadmin->name, 0, 1) }}
                        </div>
                        <div>
                            <h4 class="font-bold text-gray-900 text-base">{{ $subadmin->name }}</h4>
                            <p class="text-xs text-gray-500">{{ $subadmin->email }}</p>
                        </div>
                    </div>
                    <span class="bg-purple-100 text-purple-800 text-xs font-bold px-3 py-1 rounded-full border border-purple-200">
                        SUBADMIN
                    </span>
                </div>
                <div class="p-6">
                    <form action="{{ route('admin.subadmins.permissions', $subadmin) }}" method="POST">
                        @csrf
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-6">
                            @foreach($permissions as $perm)
                            <label class="flex items-center bg-gray-50 p-3 rounded-xl border border-gray-200 hover:border-blue-300 transition cursor-pointer">
                                <input type="checkbox" name="permissions[]" value="{{ $perm->name }}" id="perm_{{ $subadmin->id }}_{{ $perm->id }}" 
                                    {{ $subadmin->hasPermissionTo($perm->name) ? 'checked' : '' }}
                                    class="rounded text-blue-600 focus:ring-blue-500 mr-3 h-4 w-4">
                                <div>
                                    <span class="text-xs font-bold text-gray-800 block">{{ ucwords(str_replace('_', ' ', $perm->name)) }}</span>
                                </div>
                            </label>
                            @endforeach
                        </div>
                        <div class="flex justify-end">
                            <button type="submit" class="bg-slate-900 text-white px-5 py-2.5 text-xs font-bold rounded-xl hover:bg-slate-800 transition shadow-sm">
                                <i class="fas fa-save mr-1.5"></i> Update Subadmin Permissions
                            </button>
                        </div>
                    </form>
                </div>
            </div>
            @empty
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-12 text-center text-gray-500">
                <i class="fas fa-users-slash text-4xl mb-4 text-gray-300"></i>
                <p class="text-lg font-bold text-gray-800">No Subadmins Registered</p>
                <p class="text-sm text-gray-500 mt-1">Create your first subadmin user using the form on the left.</p>
            </div>
            @endforelse
        </div>
    </div>
@endsection
