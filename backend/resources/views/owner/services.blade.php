@extends('layouts.owner')

@section('title', 'Salon Services')

@section('content')
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Add Service Form -->
        <div class="lg:col-span-1 bg-white rounded-2xl p-6 shadow-sm border border-gray-100 h-fit">
            <h3 class="text-lg font-bold text-gray-900 mb-4 pb-3 border-b border-gray-100 flex items-center">
                <i class="fas fa-plus-circle text-blue-600 mr-2"></i> Add New Service
            </h3>

            <form action="{{ route('owner.services.store') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Service Name</label>
                    <input type="text" name="name" required placeholder="e.g. Premium Haircut & Style" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Branch / Location</label>
                    <select name="branch_id" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                        @foreach($branches as $b)
                            <option value="{{ $b->id }}">{{ $b->name }} ({{ $b->city }})</option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Category</label>
                    <select name="category" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                        <option value="Haircut">Haircut & Styling</option>
                        <option value="Beard Grooming">Beard & Shave</option>
                        <option value="Hair Coloring">Hair Coloring & Spa</option>
                        <option value="Facial & Skin">Facial & Skin Care</option>
                        <option value="Massage">Massage & Relaxation</option>
                    </select>
                </div>

                <div class="grid grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Duration (Min)</label>
                        <input type="number" name="duration_minutes" required min="5" value="30" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Price (₹)</label>
                        <input type="number" name="price" required min="0" step="0.01" value="350" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                </div>

                <div class="mb-6">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Buffer Time (Min)</label>
                    <input type="number" name="buffer_time_minutes" min="0" value="5" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                </div>

                <button type="submit" class="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition text-sm shadow-sm">
                    Create Service
                </button>
            </form>
        </div>

        <!-- Services List -->
        <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h3 class="text-lg font-bold text-gray-900">Active Services Menu</h3>
                <span class="text-xs bg-blue-50 text-blue-700 px-3 py-1 rounded-full font-semibold border border-blue-100">
                    {{ count($services) }} Active Service(s)
                </span>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    @forelse($services as $service)
                    <div class="border border-gray-200 rounded-xl p-5 hover:border-blue-300 transition bg-white shadow-sm flex flex-col justify-between">
                        <div>
                            <div class="flex justify-between items-start mb-2">
                                <h4 class="font-bold text-gray-900 text-base">{{ $service->name }}</h4>
                                <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-100">
                                    {{ $service->category }}
                                </span>
                            </div>
                            <p class="text-xs text-gray-500 mb-4"><i class="far fa-clock mr-1"></i> {{ $service->duration_minutes }} Mins Duration</p>
                        </div>
                        <div class="flex justify-between items-center pt-3 border-t border-gray-100">
                            <span class="text-lg font-black text-gray-900">₹{{ number_format($service->price, 2) }}</span>
                            <span class="text-xs text-emerald-600 font-semibold flex items-center">
                                <span class="w-2 h-2 rounded-full bg-emerald-500 mr-1"></span> Active
                            </span>
                        </div>
                    </div>
                    @empty
                    <div class="col-span-2 text-center py-12 text-gray-400">
                        <i class="fas fa-cut text-4xl mb-3 text-gray-300"></i>
                        <p>No services registered yet. Add your first service using the form.</p>
                    </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
@endsection
