@extends('layouts.customer')

@section('title', 'Customer Portal')

@section('content')
    <!-- Hero Banner -->
    <div class="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-3xl p-8 text-white shadow-xl mb-8 flex flex-col md:flex-row items-center justify-between">
        <div>
            <span class="text-xs uppercase font-bold tracking-wider text-blue-200 bg-blue-500/30 px-3 py-1 rounded-full">Welcome Back</span>
            <h1 class="text-3xl font-black mt-2">Hello, {{ $user->name }}!</h1>
            <p class="text-blue-100 text-sm mt-1">Book top-rated barbers, hair stylists, and spa treatments near you.</p>
        </div>
        <div class="mt-6 md:mt-0">
            <a href="{{ route('customer.explore') }}" class="px-6 py-3 bg-white text-blue-600 font-bold rounded-2xl shadow-lg hover:bg-blue-50 transition text-sm inline-block">
                <i class="fas fa-search mr-2"></i> Explore Salons
            </a>
        </div>
    </div>

    <!-- Active Upcoming Bookings -->
    <div class="mb-10">
        <h3 class="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <i class="fas fa-calendar-alt text-blue-600 mr-2"></i> Upcoming Appointments
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            @forelse($activeBookings as $booking)
            <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between hover:border-blue-300 transition">
                <div>
                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-800 uppercase">{{ $booking->status }}</span>
                    <h4 class="font-bold text-gray-900 text-lg mt-2">{{ $booking->service->name ?? 'Salon Service' }}</h4>
                    <p class="text-xs text-gray-500 mt-1"><i class="fas fa-store text-gray-400 mr-1"></i> {{ $booking->tenant->business_name ?? 'Salon' }} ({{ $booking->branch->name ?? 'Main Branch' }})</p>
                    <p class="text-xs text-gray-400 mt-0.5"><i class="far fa-clock mr-1"></i> {{ $booking->booking_date }} at {{ $booking->start_time }}</p>
                </div>
                <div class="text-right">
                    <span class="text-xl font-black text-gray-900 block">₹{{ number_format($booking->amount, 2) }}</span>
                    <span class="text-xs text-emerald-600 font-semibold">Confirmed</span>
                </div>
            </div>
            @empty
            <div class="col-span-2 bg-white rounded-2xl p-8 border border-gray-100 text-center text-gray-400">
                <i class="fas fa-calendar-check text-4xl mb-3 text-gray-300"></i>
                <p class="text-sm font-semibold text-gray-600">No active upcoming appointments.</p>
                <a href="{{ route('customer.explore') }}" class="text-xs font-bold text-blue-600 hover:underline mt-1 inline-block">Book your next haircut or grooming service &rarr;</a>
            </div>
            @endforelse
        </div>
    </div>

    <!-- Featured Salons -->
    <div>
        <h3 class="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <i class="fas fa-star text-amber-500 mr-2"></i> Verified Partner Salons
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            @foreach($featuredSalons as $salon)
            @php
                $branch = $salon->branches->first();
                $tz = config('app.timezone', 'Asia/Kolkata');
                $now = \Carbon\Carbon::now($tz);
                $todayOfWeek = $now->dayOfWeek; // 0=Sunday
                $tomorrowOfWeek = ($todayOfWeek + 1) % 7;

                $bwhToday = $branch ? $branch->workingHours->where('day_of_week', $todayOfWeek)->first() : null;
                $bwhTomorrow = $branch ? $branch->workingHours->where('day_of_week', $tomorrowOfWeek)->first() : null;

                $currentTime = $now->format('H:i:s');
                $isOpenNow = false;
                $statusBadge = '🔴 CLOSED NOW';
                $statusBg = 'bg-red-50 text-red-700 border-red-200';
                $isOwnerOffline = in_array($salon->status, ['EMERGENCY_CLOSED', 'OFFLINE', 'SUSPENDED_FOR_DELETION']);

                if ($bwhToday && $bwhToday->is_open) {
                    $openTime = strlen($bwhToday->open_time) === 5 ? $bwhToday->open_time . ':00' : $bwhToday->open_time;
                    $closeTime = strlen($bwhToday->close_time) === 5 ? $bwhToday->close_time . ':00' : $bwhToday->close_time;
                    
                    $inShift1 = ($currentTime >= $openTime && $currentTime <= $closeTime);
                    $inShift2 = false;
                    if ($bwhToday->has_split_shift && $bwhToday->split_open_time && $bwhToday->split_close_time) {
                        $sOpen = strlen($bwhToday->split_open_time) === 5 ? $bwhToday->split_open_time . ':00' : $bwhToday->split_open_time;
                        $sClose = strlen($bwhToday->split_close_time) === 5 ? $bwhToday->split_close_time . ':00' : $bwhToday->split_close_time;
                        $inShift2 = ($currentTime >= $sOpen && $currentTime <= $sClose);
                    }

                    if ($inShift1 || $inShift2) {
                        if ($isOwnerOffline) {
                            $isOpenNow = false;
                            $statusBadge = "🟠 TEMPORARILY OFFLINE • Paused by Owner";
                            $statusBg = 'bg-amber-50 text-amber-900 border-amber-300';
                        } else {
                            $isOpenNow = true;
                            $closingTimeFormatted = $inShift1 ? \Carbon\Carbon::parse($closeTime)->format('h:i A') : \Carbon\Carbon::parse($bwhToday->split_close_time)->format('h:i A');
                            $statusBadge = "🟢 OPEN NOW • Closes at {$closingTimeFormatted}";
                            $statusBg = 'bg-emerald-50 text-emerald-800 border-emerald-200';
                        }
                    } else {
                        if ($currentTime < $openTime) {
                            $statusBadge = "🔴 CLOSED NOW • Opens today at " . \Carbon\Carbon::parse($openTime)->format('h:i A');
                        } elseif ($bwhToday->has_split_shift && $currentTime > $closeTime && $currentTime < $bwhToday->split_open_time) {
                            $statusBadge = "🔴 CLOSED NOW (Break) • Reopens at " . \Carbon\Carbon::parse($bwhToday->split_open_time)->format('h:i A');
                        } else {
                            $tomorrowOpen = ($bwhTomorrow && $bwhTomorrow->is_open) ? \Carbon\Carbon::parse($bwhTomorrow->open_time)->format('h:i A') : '10:00 AM';
                            $statusBadge = "🔴 CLOSED NOW • Opens tomorrow at {$tomorrowOpen}";
                        }
                    }
                } else {
                    $statusBadge = '🔴 CLOSED TODAY';
                }

                $isClosedTomorrow = ($bwhTomorrow && !$bwhTomorrow->is_open);
            @endphp

            <div class="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col justify-between hover:shadow-md transition">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <div class="w-12 h-12 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xl">
                            <i class="fas fa-store"></i>
                        </div>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border {{ $statusBg }}">
                            {{ $statusBadge }}
                        </span>
                    </div>
                    <h4 class="font-black text-gray-900 text-lg">{{ $salon->business_name }}</h4>
                    <p class="text-xs text-gray-500 font-medium mt-0.5">
                        {{ $salon->business_type }} • 
                        <span class="font-bold text-gray-700"><i class="fas fa-code-branch text-blue-500 mr-1"></i>{{ $salon->branches->count() }} {{ \Illuminate\Support\Str::plural('Branch', $salon->branches->count()) }}</span>
                    </p>
                    <p class="text-xs text-gray-400 mt-2 font-semibold"><i class="fas fa-map-marker-alt text-red-500 mr-1"></i> {{ $salon->branches->first()->address ?? 'Main Branch' }}, {{ $salon->branches->first()->city ?? 'New Delhi' }}</p>
                    
                    @if($isClosedTomorrow)
                        <div class="mt-2">
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                                ⚠️ Closed Tomorrow ({{ \Carbon\Carbon::tomorrow()->format('l') }})
                            </span>
                        </div>
                    @endif
                </div>

                <div class="mt-5 pt-4 border-t border-gray-100 flex justify-between items-center">
                    <span class="text-xs font-bold text-emerald-600 flex items-center"><i class="fas fa-shield-check mr-1 text-sm"></i> Verified Shop</span>
                    <a href="{{ route('customer.explore') }}?q={{ urlencode($salon->business_name) }}" class="text-xs font-bold bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-xl transition shadow-sm">Book Slot &rarr;</a>
                </div>
            </div>
            @endforeach
        </div>
    </div>
@endsection
