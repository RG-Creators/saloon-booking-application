@extends('layouts.staff')

@section('title', 'Stylist Schedule & Workstation')

@section('content')
    <!-- Stats Row -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Completed Services Today</p>
                <h3 class="text-3xl font-black text-gray-900">{{ $completedCount }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-check-double"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Pending Appointments</p>
                <h3 class="text-3xl font-black text-gray-900">{{ $pendingCount }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-clock"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Daily Service Volume</p>
                <h3 class="text-3xl font-black text-purple-600">₹{{ number_format($todaysEarnings, 2) }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-rupee-sign"></i>
            </div>
        </div>
    </div>

    <!-- Appointment Schedule Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 class="text-lg font-bold text-gray-900">Today's Appointment Queue</h3>
            <span class="text-xs font-semibold bg-purple-50 text-purple-700 px-3 py-1 rounded-full border border-purple-100">
                {{ count($todayBookings) }} Booking(s)
            </span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">Time & Date</th>
                        <th class="px-6 py-4 font-semibold">Client Name</th>
                        <th class="px-6 py-4 font-semibold">Requested Service</th>
                        <th class="px-6 py-4 font-semibold">Price</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Job Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($todayBookings as $booking)
                    <tr class="hover:bg-gray-50/80 transition">
                        <td class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap">
                            <i class="far fa-clock text-purple-500 mr-1.5"></i> {{ $booking->start_time }} - {{ $booking->end_time }}
                        </td>
                        <td class="px-6 py-4 font-bold text-gray-900">{{ $booking->customer->name ?? 'Guest Client' }}</td>
                        <td class="px-6 py-4 text-gray-700 font-medium">{{ $booking->service->name ?? 'Hair Cut' }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">₹{{ number_format($booking->amount, 2) }}</td>
                        <td class="px-6 py-4">
                            @if($booking->status === 'COMPLETED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Completed</span>
                            @elseif($booking->status === 'CONFIRMED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">Confirmed</span>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">{{ $booking->status }}</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right space-x-1">
                            @if($booking->status !== 'COMPLETED')
                            <form action="{{ route('staff.appointments.update', $booking) }}" method="POST" class="inline">
                                @csrf
                                <input type="hidden" name="status" value="COMPLETED">
                                <button type="submit" class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition">
                                    <i class="fas fa-check mr-1"></i> Finish Job
                                </button>
                            </form>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-calendar-day text-4xl mb-3 text-gray-300"></i>
                            <p>No appointments scheduled for your workstation today.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- 🔔 Real-Time Live Stylist Workstation Booking Notification Popup Alert Modal -->
    <div id="staff-booking-popup" class="fixed bottom-6 right-6 bg-white rounded-3xl p-6 shadow-2xl border-2 border-purple-500 max-w-md w-full hidden z-50 transform transition-all duration-300 animate-bounce">
        <div class="flex items-start justify-between mb-3">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-2xl bg-purple-600 text-white flex items-center justify-center text-xl shadow-md">
                    <i class="fas fa-bell"></i>
                </div>
                <div>
                    <h4 class="font-black text-gray-900 text-base">💇 NEW CLIENT BOOKING ASSIGNED!</h4>
                    <p class="text-[11px] text-gray-500 font-semibold">Assigned to your workstation</p>
                </div>
            </div>
            <button onclick="document.getElementById('staff-booking-popup').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times text-sm"></i>
            </button>
        </div>

        <div class="bg-purple-50/60 rounded-2xl p-4 mb-4 border border-purple-100 text-xs">
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Client:</span>
                <span class="font-bold text-gray-900">Alex Smith</span>
            </div>
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Requested Service:</span>
                <span class="font-bold text-gray-900">Beard Trim & Royal Shave</span>
            </div>
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Slot Time:</span>
                <span class="font-bold text-purple-700">11:00 AM - 11:25 AM</span>
            </div>
        </div>

        <div class="flex space-x-3">
            <button onclick="document.getElementById('staff-booking-popup').classList.add('hidden')" class="w-full py-2.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-xl text-center transition shadow-md">
                Accept Client & Prepare Station &rarr;
            </button>
        </div>
    </div>

    <script>
        // Simulate real-time workstation alert popup
        setTimeout(function() {
            document.getElementById('staff-booking-popup').classList.remove('hidden');
        }, 5000);
    </script>
@endsection
