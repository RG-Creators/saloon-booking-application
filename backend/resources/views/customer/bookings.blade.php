@extends('layouts.customer')

@section('title', 'My Appointment History & Real-Time Status')

@section('content')
    @if(session('success'))
        <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-500 text-lg mr-3"></i> {{ session('success') }}
        </div>
    @endif

    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <div>
                <h3 class="text-lg font-bold text-gray-900">Appointment Records & Live Status</h3>
                <p class="text-xs text-gray-500 mt-0.5">Track real-time approval or decline status from salon owners.</p>
            </div>
            <span class="text-xs font-semibold bg-blue-50 text-blue-700 px-3 py-1 rounded-full border border-blue-100">
                Total: {{ $bookings->total() }} Booking(s)
            </span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">Booking ID</th>
                        <th class="px-6 py-4 font-semibold">Salon Business</th>
                        <th class="px-6 py-4 font-semibold">Service</th>
                        <th class="px-6 py-4 font-semibold">Stylist</th>
                        <th class="px-6 py-4 font-semibold">Date & Time</th>
                        <th class="px-6 py-4 font-semibold">Amount</th>
                        <th class="px-6 py-4 font-semibold text-right">Status & Owner Notes</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($bookings as $booking)
                    <tr class="hover:bg-gray-50/80 transition">
                        <td class="px-6 py-4 font-mono font-medium text-gray-900">#{{ $booking->id }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">{{ $booking->tenant->business_name ?? 'Salon' }}</td>
                        <td class="px-6 py-4 font-medium text-gray-800">
                            @if($booking->combo)
                                {{ $booking->combo->name }} <span class="text-[10px] bg-purple-100 text-purple-700 px-1 py-0.5 rounded ml-1 uppercase">Combo</span>
                            @else
                                {{ $booking->service->name ?? 'Service' }}
                            @endif
                        </td>
                        <td class="px-6 py-4 text-gray-600">{{ $booking->staff->name ?? 'Any Staff' }}</td>
                        <td class="px-6 py-4 text-gray-500 text-xs whitespace-nowrap">{{ $booking->booking_date }} • {{ $booking->start_time }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">₹{{ number_format($booking->amount, 2) }}</td>
                        <td class="px-6 py-4 text-right">
                            @if($booking->status === 'COMPLETED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Completed</span>
                            @elseif($booking->status === 'CONFIRMED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">Confirmed & Approved</span>
                            @elseif($booking->status === 'PENDING')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 animate-pulse">⏳ Pending Owner Review</span>
                            @elseif($booking->status === 'DECLINED')
                                <div>
                                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800 border border-red-200">❌ Declined</span>
                                    <span class="block text-[11px] text-red-600 font-bold mt-1">Reason: {{ $booking->decline_reason ?? 'Slot is not free' }}</span>
                                </div>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-800">{{ $booking->status }}</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-calendar-times text-4xl mb-3 text-gray-300"></i>
                            <p>No appointment records found.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($bookings->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $bookings->links() }}
        </div>
        @endif
    </div>

    <!-- Real-time Status Polling for Customer -->
    <script>
        // Auto-refresh the bookings page every 10 seconds to show instant Approve/Decline status from the owner
        setInterval(() => {
            window.location.reload();
        }, 10000);
    </script>
@endsection
