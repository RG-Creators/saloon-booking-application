@extends('layouts.owner')

@section('title', 'Staff & Stylists')

@section('content')
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Add Staff Form -->
        <div class="lg:col-span-1 bg-white rounded-2xl p-6 shadow-sm border border-gray-100 h-fit">
            <h3 class="text-lg font-bold text-gray-900 mb-4 pb-3 border-b border-gray-100 flex items-center">
                <i class="fas fa-user-plus text-blue-600 mr-2"></i> Add Stylist / Staff
            </h3>

            <form action="{{ route('owner.staff.store') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Full Name</label>
                    <input type="text" name="name" required placeholder="e.g. Alex Rivera" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Branch / Location</label>
                    <select name="branch_id" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                        @foreach($branches as $branch)
                            <option value="{{ $branch->id }}">{{ $branch->name }} ({{ $branch->city }})</option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Position / Title</label>
                    <input type="text" name="position" required placeholder="e.g. Senior Barber / Master Stylist" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                </div>

                <div class="mb-6">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Phone Number</label>
                    <input type="text" name="phone" placeholder="+91 98765 43210" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                </div>

                <button type="submit" class="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition text-sm shadow-sm">
                    Add Staff Member
                </button>
            </form>
        </div>

        <!-- Staff List -->
        <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h3 class="text-lg font-bold text-gray-900">Stylists Roster</h3>
                <span class="text-xs bg-purple-50 text-purple-700 px-3 py-1 rounded-full font-semibold border border-purple-100">
                    {{ count($staffMembers) }} Active Staff
                </span>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    @forelse($staffMembers as $staff)
                    <div class="border border-gray-200 rounded-xl p-5 hover:border-blue-300 transition bg-white shadow-sm flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                            <div class="w-12 h-12 rounded-full bg-purple-100 text-purple-700 flex items-center justify-center font-bold text-base">
                                {{ substr($staff->name, 0, 1) }}
                            </div>
                            <div>
                                <h4 class="font-bold text-gray-900 text-base">{{ $staff->name }}</h4>
                                <p class="text-xs text-gray-500 font-medium">{{ $staff->role ?? 'Stylist' }}</p>
                                <p class="text-[11px] text-gray-400 mt-0.5"><i class="fas fa-store text-gray-300 mr-1"></i> {{ $staff->branch->name ?? 'Main Branch' }}</p>
                            </div>
                        </div>
                        <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Active</span>
                    </div>
                    @empty
                    <div class="col-span-2 text-center py-12 text-gray-400">
                        <i class="fas fa-users-slash text-4xl mb-3 text-gray-300"></i>
                        <p>No staff members added yet.</p>
                    </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
@endsection
