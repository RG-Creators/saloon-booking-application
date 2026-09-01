@extends('layouts.owner')

@section('title', 'Appointment & Slot Management')

@section('content')
    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden mb-8">
        <div class="px-6 py-5 border-b border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-gray-50/50">
            <div>
                <h3 class="text-lg font-bold text-gray-900">Customer Bookings & Time Slot Schedule</h3>
                <p class="text-xs text-gray-500 mt-0.5">Approve incoming customer bookings or manually lock slots for offline callers.</p>
            </div>
            <button onclick="document.getElementById('lock-slot-modal').classList.remove('hidden')" class="px-4 py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-2xl transition shadow-md flex items-center">
                <i class="fas fa-lock text-amber-400 mr-2"></i> Lock Slot (Offline Call / VIP)
            </button>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">ID</th>
                        <th class="px-6 py-4 font-semibold">Customer</th>
                        <th class="px-6 py-4 font-semibold">Service</th>
                        <th class="px-6 py-4 font-semibold">Stylist</th>
                        <th class="px-6 py-4 font-semibold">Time & Date</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                        <th class="px-6 py-4 font-semibold text-right">Owner Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($bookings as $booking)
                    <tr class="hover:bg-gray-50/80 transition">
                        <td class="px-6 py-4 font-mono font-medium text-gray-900">#{{ $booking->id }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">
                            {{ $booking->customer->name ?? ($booking->status === 'LOCKED' ? '🔒 Locked (Offline Client)' : 'Walk-in Customer') }}
                            <span class="block text-xs font-normal text-gray-400">{{ $booking->customer->email ?? $booking->lock_note }}</span>
                            @if($booking->customer)
                                <form action="{{ route('owner.customers.toggle', $booking->customer) }}" method="POST" class="inline-block mt-1">
                                    @csrf
                                    <button type="submit" class="px-2 py-0.5 bg-blue-50 hover:bg-blue-100 text-blue-700 text-[10px] font-bold rounded-lg border border-blue-200 transition">
                                        <i class="fas fa-user-plus mr-1"></i> + Add to Customer List
                                    </button>
                                </form>
                            @endif
                        </td>
                        <td class="px-6 py-4 font-medium text-gray-800">{{ $booking->service->name ?? 'Hair Cut' }}</td>
                        <td class="px-6 py-4 text-gray-600">{{ $booking->staff->name ?? 'Stylist' }}</td>
                        <td class="px-6 py-4 text-gray-600 text-xs font-medium">
                            {{ $booking->booking_date }}<br>
                            <span class="text-blue-600 font-bold">{{ $booking->start_time }}</span>
                        </td>
                        <td class="px-6 py-4">
                            @if($booking->status === 'COMPLETED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Completed</span>
                            @elseif($booking->status === 'CONFIRMED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">Confirmed</span>
                            @elseif($booking->status === 'PENDING')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">Pending Review</span>
                            @elseif($booking->status === 'DECLINED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800" title="{{ $booking->decline_reason }}">Declined</span>
                            @elseif($booking->status === 'LOCKED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-500 text-white border border-amber-600">🔒 Locked Slot</span>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-800">{{ $booking->status }}</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right space-x-1">
                            @if($booking->status === 'PENDING')
                                <form action="{{ route('owner.appointments.approve', $booking) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" class="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition shadow-sm">
                                        <i class="fas fa-check mr-1"></i> Approve
                                    </button>
                                </form>

                                <button onclick="openDeclineModal({{ $booking->id }})" class="px-3 py-1 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-xl transition shadow-sm">
                                    <i class="fas fa-times mr-1"></i> Decline
                                </button>
                            @elseif($booking->status === 'CONFIRMED')
                                <form action="{{ route('owner.appointments.status', $booking) }}" method="POST" class="inline">
                                    @csrf
                                    <input type="hidden" name="status" value="COMPLETED">
                                    <button type="submit" class="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition">
                                        <i class="fas fa-check-circle mr-1"></i> Complete Job
                                    </button>
                                </form>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-calendar-times text-4xl mb-3 text-gray-300"></i>
                            <p>No customer appointments found.</p>
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

    <!-- 🔒 MANUAL SLOT LOCKING MODAL FOR OFFLINE CALLS -->
    <div id="lock-slot-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm flex items-center justify-center hidden z-50">
        <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl border border-gray-100">
            <div class="flex justify-between items-center mb-4 pb-3 border-b border-gray-100">
                <h3 class="text-lg font-bold text-gray-900 flex items-center">
                    <i class="fas fa-lock text-amber-500 mr-2"></i> Lock Time Slot (Offline Client)
                </h3>
                <button type="button" onclick="document.getElementById('lock-slot-modal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times text-lg"></i>
                </button>
            </div>

            <form action="{{ route('owner.slots.lock') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Select Service</label>
                    <select name="service_id" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        @foreach(\App\Models\Service::all() as $srv)
                            <option value="{{ $srv->id }}">{{ $srv->name }} (₹{{ number_format($srv->price, 2) }})</option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Select Stylist</label>
                    <select name="staff_id" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        @foreach(\App\Models\Staff::all() as $stf)
                            <option value="{{ $stf->id }}">{{ $stf->name }} ({{ $stf->role }})</option>
                        @endforeach
                    </select>
                </div>

                <div class="grid grid-cols-2 gap-3 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Date</label>
                        <input type="date" name="booking_date" value="{{ date('Y-m-d') }}" required class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Time Slot</label>
                        <select name="start_time" required class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none">
                            <option value="10:00:00">10:00 AM</option>
                            <option value="11:00:00">11:00 AM</option>
                            <option value="12:00:00">12:00 PM</option>
                            <option value="14:00:00">02:00 PM</option>
                            <option value="16:00:00">04:00 PM</option>
                            <option value="18:00:00">06:00 PM</option>
                        </select>
                    </div>
                </div>

                <div class="mb-6">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Client Note / Name (e.g. VIP Phone Caller)</label>
                    <input type="text" name="lock_note" required placeholder="e.g. Phone booking for Mr. Sharma" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs outline-none focus:ring-2 focus:ring-blue-500">
                </div>

                <button type="submit" class="w-full py-3 bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs rounded-xl transition shadow-md">
                    🔒 Lock Slot for Offline Client
                </button>
            </form>
        </div>
    </div>

    <!-- DECLINE REASON MODAL -->
    <div id="decline-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm flex items-center justify-center hidden z-50">
        <div class="bg-white rounded-3xl p-6 max-w-sm w-full shadow-2xl border border-gray-100">
            <h4 class="font-bold text-gray-900 text-base mb-2">Decline Booking Request</h4>
            <form id="table-decline-form" action="" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Select Decline Reason:</label>
                    <select name="decline_reason" required class="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none">
                        <option value="Requested time slot is not free / fully booked">Slot is not free / Fully Booked</option>
                        <option value="Assigned stylist is unavailable">Assigned Stylist Unavailable</option>
                        <option value="Salon is closed at this time">Salon Closed at this time</option>
                    </select>
                </div>

                <div class="flex justify-end space-x-2">
                    <button type="button" onclick="document.getElementById('decline-modal').classList.add('hidden')" class="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs font-bold rounded-xl">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-red-600 text-white text-xs font-bold rounded-xl shadow-sm">Confirm Decline</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openDeclineModal(bookingId) {
            document.getElementById('table-decline-form').action = "/owner/appointments/" + bookingId + "/decline";
            document.getElementById('decline-modal').classList.remove('hidden');
        }
    </script>
@endsection
