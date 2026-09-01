@extends('layouts.owner')

@section('title', 'Shop Operating Hours & Staff Schedules')

@section('content')
    <div class="space-y-8">

        <!-- 🏪 SHOP / BRANCH OPERATING HOURS & SPLIT SHIFT CONFIGURATION -->
        @foreach($branches as $b)
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div class="flex justify-between items-center mb-6 pb-4 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center font-bold text-lg shadow-sm">
                        <i class="fas fa-store"></i>
                    </div>
                    <div>
                        <h3 class="text-lg font-bold text-gray-900">{{ $b->name }} — Shop Operating Hours & Split Shifts</h3>
                        <p class="text-xs text-gray-500">Configure weekly open/closed days, operating hours, and afternoon split shifts.</p>
                    </div>
                </div>
                <span class="text-xs bg-amber-50 text-amber-800 px-3 py-1 rounded-full font-bold border border-amber-200">
                    <i class="fas fa-clock mr-1"></i> Live Status Engine Active
                </span>
            </div>

            <form action="{{ route('owner.branch.hours.update') }}" method="POST">
                @csrf
                <input type="hidden" name="branch_id" value="{{ $b->id }}">

                <div class="grid grid-cols-1 md:grid-cols-7 gap-4 mb-6">
                    @php
                        $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                    @endphp
                    @foreach($days as $index => $dayName)
                        @php
                            $bwh = $b->workingHours->where('day_of_week', $index)->first();
                            $isOpen = $bwh ? $bwh->is_open : ($index !== 0); // Sunday default closed
                            $openTime = $bwh ? \Carbon\Carbon::parse($bwh->open_time)->format('H:i') : '10:00';
                            $closeTime = $bwh ? \Carbon\Carbon::parse($bwh->close_time)->format('H:i') : '20:00';
                            $hasSplit = $bwh ? $bwh->has_split_shift : false;
                            $splitOpen = $bwh && $bwh->split_open_time ? \Carbon\Carbon::parse($bwh->split_open_time)->format('H:i') : '16:00';
                            $splitClose = $bwh && $bwh->split_close_time ? \Carbon\Carbon::parse($bwh->split_close_time)->format('H:i') : '21:00';
                        @endphp
                        <div class="border {{ $isOpen ? 'border-amber-200 bg-amber-50/20' : 'border-gray-200 bg-gray-50' }} rounded-2xl p-3 flex flex-col justify-between transition">
                            <input type="hidden" name="days[{{ $index }}][day_of_week]" value="{{ $index }}">

                            <div class="text-center mb-3">
                                <span class="text-xs font-bold uppercase tracking-wider block mb-2 {{ $isOpen ? 'text-amber-800' : 'text-gray-400' }}">{{ $dayName }}</span>
                                <label class="inline-flex items-center cursor-pointer">
                                    <input type="checkbox" name="days[{{ $index }}][is_open]" value="1" {{ $isOpen ? 'checked' : '' }} class="w-4 h-4 text-amber-600 rounded border-gray-300 focus:ring-amber-500">
                                    <span class="ml-1.5 text-[11px] font-bold text-gray-700">{{ $isOpen ? 'OPEN' : 'CLOSED' }}</span>
                                </label>
                            </div>

                            <div class="space-y-2">
                                <div>
                                    <label class="block text-[9px] font-bold uppercase text-gray-500 text-center">Open Time</label>
                                    <input type="time" name="days[{{ $index }}][open_time]" value="{{ $openTime }}" class="w-full px-2 py-1 bg-white border border-gray-200 rounded-lg text-xs font-bold outline-none text-center focus:ring-1 focus:ring-amber-500">
                                </div>
                                <div>
                                    <label class="block text-[9px] font-bold uppercase text-gray-500 text-center">Close Time</label>
                                    <input type="time" name="days[{{ $index }}][close_time]" value="{{ $closeTime }}" class="w-full px-2 py-1 bg-white border border-gray-200 rounded-lg text-xs font-bold outline-none text-center focus:ring-1 focus:ring-amber-500">
                                </div>

                                <!-- Split Shift Option -->
                                <div class="pt-2 border-t border-gray-200/60 text-center">
                                    <label class="inline-flex items-center cursor-pointer mb-1">
                                        <input type="checkbox" name="days[{{ $index }}][has_split_shift]" value="1" {{ $hasSplit ? 'checked' : '' }} class="w-3.5 h-3.5 text-purple-600 rounded border-gray-300 focus:ring-purple-500">
                                        <span class="ml-1 text-[10px] font-bold text-purple-700">Split Shift</span>
                                    </label>

                                    <div class="space-y-1.5 {{ $hasSplit ? '' : 'opacity-40' }}">
                                        <input type="time" name="days[{{ $index }}][split_open_time]" value="{{ $splitOpen }}" class="w-full px-2 py-1 bg-purple-50/50 border border-purple-200 rounded-lg text-[11px] font-bold outline-none text-center focus:ring-1 focus:ring-purple-500" title="Split Shift Start Time">
                                        <input type="time" name="days[{{ $index }}][split_close_time]" value="{{ $splitClose }}" class="w-full px-2 py-1 bg-purple-50/50 border border-purple-200 rounded-lg text-[11px] font-bold outline-none text-center focus:ring-1 focus:ring-purple-500" title="Split Shift End Time">
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>

                <div class="flex justify-end">
                    <button type="submit" class="px-6 py-2.5 bg-amber-600 hover:bg-amber-700 text-white font-bold rounded-xl transition text-xs shadow-sm flex items-center">
                        <i class="fas fa-save mr-2"></i> Save Shop Business Hours & Split Shifts
                    </button>
                </div>
            </form>
        </div>
        @endforeach

        <!-- ✂️ INDIVIDUAL STAFF WORKING SHIFTS -->
        <h2 class="text-xl font-black text-gray-900 pt-4 flex items-center">
            <i class="fas fa-users text-blue-600 mr-2"></i> Individual Stylist Working Shifts
        </h2>

        @forelse($staffMembers as $staff)
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div class="flex justify-between items-center mb-6 pb-4 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-lg">
                        {{ substr($staff->name, 0, 1) }}
                    </div>
                    <div>
                        <h3 class="text-lg font-bold text-gray-900">{{ $staff->name }}</h3>
                        <p class="text-xs text-gray-500">{{ $staff->role }} • {{ $staff->branch->name }}</p>
                    </div>
                </div>
                <span class="text-xs bg-blue-50 text-blue-700 px-3 py-1 rounded-full font-semibold border border-blue-100">
                    Active Stylist Shift
                </span>
            </div>

            <form action="{{ route('owner.schedules.update') }}" method="POST">
                @csrf
                <input type="hidden" name="staff_id" value="{{ $staff->id }}">
                
                <div class="grid grid-cols-1 md:grid-cols-7 gap-4 mb-6">
                    @foreach($days as $index => $dayName)
                        @php
                            $wh = $staff->workingHours->where('day_of_week', $index)->first();
                            $isWorking = $wh ? $wh->is_working_day : ($index !== 0);
                            $start = $wh ? \Carbon\Carbon::parse($wh->start_time)->format('H:i') : '10:00';
                            $end = $wh ? \Carbon\Carbon::parse($wh->end_time)->format('H:i') : '20:00';
                        @endphp
                        <div class="border {{ $isWorking ? 'border-blue-200 bg-blue-50/30' : 'border-gray-200 bg-gray-50' }} rounded-xl p-3 flex flex-col items-center justify-between transition h-full">
                            <input type="hidden" name="days[{{ $index }}][day_of_week]" value="{{ $index }}">
                            
                            <label class="flex flex-col items-center cursor-pointer mb-3">
                                <span class="text-xs font-bold uppercase tracking-wider mb-2 {{ $isWorking ? 'text-blue-700' : 'text-gray-500' }}">{{ $dayName }}</span>
                                <input type="checkbox" name="days[{{ $index }}][is_working_day]" value="1" {{ $isWorking ? 'checked' : '' }} class="w-4 h-4 text-blue-600 rounded border-gray-300 focus:ring-blue-500">
                            </label>

                            <div class="w-full space-y-2">
                                <div>
                                    <label class="block text-[10px] font-semibold text-gray-500 mb-0.5 text-center">Shift Start</label>
                                    <input type="time" name="days[{{ $index }}][start_time]" value="{{ $start }}" class="w-full px-2 py-1 bg-white border border-gray-200 rounded text-xs focus:ring-2 focus:ring-blue-500 outline-none text-center font-bold">
                                </div>
                                <div>
                                    <label class="block text-[10px] font-semibold text-gray-500 mb-0.5 text-center">Shift End</label>
                                    <input type="time" name="days[{{ $index }}][end_time]" value="{{ $end }}" class="w-full px-2 py-1 bg-white border border-gray-200 rounded text-xs focus:ring-2 focus:ring-blue-500 outline-none text-center font-bold">
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>

                <div class="flex justify-end">
                    <button type="submit" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl transition text-xs shadow-sm flex items-center">
                        <i class="fas fa-save mr-2"></i> Save Stylist Shift for {{ $staff->name }}
                    </button>
                </div>
            </form>
        </div>
        @empty
        <div class="bg-white rounded-2xl p-12 shadow-sm border border-gray-100 text-center">
            <i class="fas fa-calendar-alt text-5xl mb-4 text-gray-300"></i>
            <h3 class="text-xl font-bold text-gray-900 mb-2">No Staff Members Found</h3>
            <p class="text-sm text-gray-500 mb-6">You need to add staff members before configuring their working schedules.</p>
            <a href="{{ route('owner.staff') }}" class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition text-sm shadow-sm inline-flex items-center">
                <i class="fas fa-plus mr-2"></i> Add Staff Member
            </a>
        </div>
        @endforelse
    </div>
@endsection
