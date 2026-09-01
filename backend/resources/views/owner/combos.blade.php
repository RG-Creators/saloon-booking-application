@extends('layouts.owner')

@section('title', 'Service Combos & Packages')

@section('content')
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Add Combo Form -->
        <div class="lg:col-span-1 bg-white rounded-2xl p-6 shadow-sm border border-gray-100 h-fit">
            <h3 class="text-lg font-bold text-gray-900 mb-4 pb-3 border-b border-gray-100 flex items-center">
                <i class="fas fa-layer-group text-blue-600 mr-2"></i> Add New Combo
            </h3>

            <form action="{{ route('owner.combos.store') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Combo Name</label>
                    <input type="text" name="name" required placeholder="e.g. Grooming Special" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
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
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Select Services to Include</label>
                    <select name="services[]" multiple required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none h-32">
                        @foreach($services as $service)
                            <option value="{{ $service->id }}">{{ $service->name }} (₹{{ $service->price }} / {{ $service->duration_minutes }}m)</option>
                        @endforeach
                    </select>
                    <p class="text-[10px] text-gray-400 mt-1">Hold CTRL/CMD to select multiple services.</p>
                </div>

                <div class="grid grid-cols-2 gap-4 mb-6">
                    <div>
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Total Duration (Min)</label>
                        <input type="number" name="duration_minutes" required min="5" value="60" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Combo Price (₹)</label>
                        <input type="number" name="price" required min="0" step="0.01" value="500" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 outline-none">
                    </div>
                </div>

                <button type="submit" class="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition text-sm shadow-sm">
                    Create Combo Package
                </button>
            </form>
        </div>

        <!-- Combos List -->
        <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h3 class="text-lg font-bold text-gray-900">Active Service Packages</h3>
                <span class="text-xs bg-blue-50 text-blue-700 px-3 py-1 rounded-full font-semibold border border-blue-100">
                    {{ count($combos) }} Active Combo(s)
                </span>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    @forelse($combos as $combo)
                    <div class="border border-purple-200 rounded-xl p-5 hover:border-purple-400 transition bg-gradient-to-br from-white to-purple-50/30 shadow-sm flex flex-col justify-between">
                        <div>
                            <div class="flex justify-between items-start mb-2">
                                <h4 class="font-bold text-gray-900 text-base">{{ $combo->name }}</h4>
                                <span class="text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider bg-purple-100 text-purple-700">
                                    Combo
                                </span>
                            </div>
                            <p class="text-xs text-gray-500 mb-3"><i class="far fa-clock mr-1"></i> {{ $combo->duration_minutes }} Mins Total</p>
                            
                            <div class="mb-4">
                                <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5">Included Services</p>
                                <ul class="space-y-1">
                                    @foreach($combo->services as $s)
                                        <li class="text-xs font-semibold text-gray-700 flex items-center">
                                            <i class="fas fa-check text-purple-500 mr-1.5"></i> {{ $s->name }}
                                        </li>
                                    @endforeach
                                </ul>
                            </div>
                        </div>
                        <div class="flex justify-between items-end pt-3 border-t border-purple-100">
                            <div>
                                <p class="text-[10px] text-gray-400 font-semibold mb-0.5">Package Price</p>
                                <span class="text-lg font-black text-gray-900">₹{{ number_format($combo->price, 2) }}</span>
                            </div>
                            <span class="text-xs text-emerald-600 font-semibold flex items-center bg-emerald-50 px-2 py-1 rounded">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5"></span> Active
                            </span>
                        </div>
                    </div>
                    @empty
                    <div class="col-span-2 text-center py-12 text-gray-400">
                        <i class="fas fa-layer-group text-4xl mb-3 text-gray-300"></i>
                        <p>No combo packages created yet. Add your first combo using the form.</p>
                    </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
@endsection
