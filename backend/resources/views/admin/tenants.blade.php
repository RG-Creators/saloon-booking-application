@extends('layouts.admin')

@section('title', 'Tenant (Salon) Management')

@section('content')
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <div>
                <h3 class="text-lg font-bold text-gray-900">Salon Applications & Verification Requests</h3>
                <p class="text-xs text-gray-500 mt-0.5">Inspect uploaded shop verification images and approve or hold salon registration applications.</p>
            </div>
            <span class="text-xs font-semibold bg-blue-50 text-blue-700 px-3 py-1 rounded-full border border-blue-100">
                Total: {{ $tenants->total() }} Salon(s)
            </span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">ID</th>
                        <th class="px-6 py-4 font-semibold">Shop Proof Photo</th>
                        <th class="px-6 py-4 font-semibold">Business Name</th>
                        <th class="px-6 py-4 font-semibold">Type</th>
                        <th class="px-6 py-4 font-semibold">Verification Status</th>
                        <th class="px-6 py-4 font-semibold">Joined Date</th>
                        <th class="px-6 py-4 font-semibold text-right">Verification Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($tenants as $tenant)
                    <tr class="hover:bg-gray-50/80 transition-colors">
                        <td class="px-6 py-4 text-gray-400 font-mono">#{{ $tenant->id }}</td>
                        <td class="px-6 py-4">
                            @if($tenant->verification_image)
                                @php
                                    $imgUrl = \Illuminate\Support\Str::startsWith($tenant->verification_image, ['http://', 'https://']) 
                                        ? $tenant->verification_image 
                                        : asset($tenant->verification_image);
                                @endphp
                                <a href="{{ $imgUrl }}" target="_blank" class="flex items-center space-x-2 text-blue-600 hover:text-blue-800 group" title="Click to view shop proof photo">
                                    <div class="w-12 h-12 rounded-xl overflow-hidden border border-gray-200 shadow-sm group-hover:border-blue-500 transition">
                                        <img src="{{ $imgUrl }}" alt="Shop Proof" class="w-full h-full object-cover" onerror="this.src='https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=600&q=80'">
                                    </div>
                                    <span class="text-xs font-semibold underline text-blue-600">View Proof</span>
                                </a>
                            @else
                                <span class="text-xs text-gray-400 italic">No image</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 font-bold text-gray-900">{{ $tenant->business_name }}</td>
                        <td class="px-6 py-4 text-gray-600 font-medium">{{ $tenant->business_type }}</td>
                        <td class="px-6 py-4">
                            @if($tenant->status === 'VERIFIED' || $tenant->status === 'ACTIVE')
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
                                    <i class="fas fa-check-circle mr-1"></i> VERIFIED
                                </span>
                            @elseif($tenant->status === 'PENDING')
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800 animate-pulse">
                                    <i class="fas fa-clock mr-1"></i> PENDING REVIEW
                                </span>
                            @elseif($tenant->status === 'SUSPENDED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-yellow-100 text-yellow-800">
                                    <i class="fas fa-pause-circle mr-1"></i> ON HOLD
                                </span>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800">
                                    <i class="fas fa-times-circle mr-1"></i> {{ $tenant->status }}
                                </span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-gray-500 text-xs">{{ $tenant->created_at->format('M d, Y') }}</td>
                        <td class="px-6 py-4 text-right space-x-1">
                            <form action="{{ route('admin.tenants.status', $tenant) }}" method="POST" class="inline">
                                @csrf
                                <input type="hidden" name="status" value="VERIFIED">
                                <button type="submit" class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition shadow-sm" title="Approve Shop Verification">
                                    <i class="fas fa-check mr-1"></i> Verify & Approve
                                </button>
                            </form>
                            
                            <form action="{{ route('admin.tenants.status', $tenant) }}" method="POST" class="inline">
                                @csrf
                                <input type="hidden" name="status" value="SUSPENDED">
                                <button type="submit" class="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold rounded-xl transition shadow-sm" title="Put Shop on Hold">
                                    <i class="fas fa-pause mr-1"></i> Hold
                                </button>
                            </form>

                            <form action="{{ route('admin.tenants.status', $tenant) }}" method="POST" class="inline">
                                @csrf
                                <input type="hidden" name="status" value="REJECTED">
                                <button type="submit" class="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-xl transition shadow-sm" title="Reject Application">
                                    <i class="fas fa-times mr-1"></i> Reject
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-store-slash text-4xl mb-3 text-gray-300"></i>
                            <p>No salon applications found.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($tenants->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $tenants->links() }}
        </div>
        @endif
    </div>
@endsection
