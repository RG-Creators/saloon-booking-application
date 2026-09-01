@extends('layouts.owner')

@section('title', 'Salon Overview & Booking Policy')

@section('content')
    @if(session('success'))
        <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-500 text-lg mr-3"></i> {{ session('success') }}
        </div>
    @endif

    @if($tenant->status === 'PENDING')
        <div class="mb-8 p-6 bg-gradient-to-r from-amber-500 to-orange-600 rounded-3xl text-white shadow-lg flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center text-2xl font-bold">
                    <i class="fas fa-clock animate-spin"></i>
                </div>
                <div>
                    <h3 class="text-xl font-bold">⏳ Shop Application Pending Super Admin Verification</h3>
                    <p class="text-amber-100 text-xs mt-0.5">Your shop verification image & registration request have been submitted. SaaS Super Admin is currently reviewing your business proof.</p>
                </div>
            </div>
            <span class="text-xs bg-white text-amber-900 font-bold px-4 py-2 rounded-full uppercase tracking-wider shadow-sm">Under Review</span>
        </div>
    @endif

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between hover:shadow-md transition">
            <div>
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-1">Today's Revenue</p>
                <h3 class="text-2xl font-black text-gray-900">₹{{ number_format($todaysRevenue, 2) }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-rupee-sign"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between hover:shadow-md transition">
            <div>
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-1">Pending Appointments</p>
                <h3 class="text-2xl font-black text-gray-900">{{ $pendingBookings }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-clock"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between hover:shadow-md transition">
            <div>
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-1">Active Stylists</p>
                <h3 class="text-2xl font-black text-gray-900">{{ $staffCount }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-user-tie"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between hover:shadow-md transition">
            <div>
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-1">Glamora ₹1 Fee Due</p>
                <h3 class="text-2xl font-black text-blue-600">₹{{ number_format($unpaidSaasFee, 2) }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center text-xl font-bold">
                <i class="fas fa-receipt"></i>
            </div>
        </div>
    </div>

    <!-- Shop Owner Customizable Booking Rules & Notification Dispatch Configurator -->
    <div class="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 mb-8">
        <div class="border-b border-gray-100 pb-4 mb-6">
            <h3 class="text-lg font-bold text-gray-900 flex items-center">
                <i class="fas fa-sliders-h text-blue-600 mr-2"></i> Customize Shop Booking Policy & Live Notifications
            </h3>
            <p class="text-xs text-gray-500 mt-0.5">Control whether prepayment is required, set rules for added CRM customers, and choose notification alert dispatch targets.</p>
        </div>

        <form action="{{ route('owner.policy.update') }}" method="POST">
            @csrf
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <!-- Booking Policy Rule -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-2">
                        <i class="fas fa-shield-alt text-emerald-600 mr-1"></i> Customer Booking Policy Rule
                    </label>
                    <select name="booking_policy" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl text-xs font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="PAY_AT_SALON" {{ $tenant->booking_policy === 'PAY_AT_SALON' ? 'selected' : '' }}>
                            🟢 Pay at Salon (No prepayment required for any customer)
                        </option>
                        <option value="PREPAYMENT_REQUIRED_ALL" {{ $tenant->booking_policy === 'PREPAYMENT_REQUIRED_ALL' ? 'selected' : '' }}>
                            💳 Prepayment Required (All customers must pay before slot is confirmed)
                        </option>
                        <option value="PREPAYMENT_REQUIRED_NEW" {{ $tenant->booking_policy === 'PREPAYMENT_REQUIRED_NEW' ? 'selected' : '' }}>
                            ⭐ Prepayment for New Users; Free Booking for Added CRM Customers
                        </option>
                        <option value="ADDED_CUSTOMERS_ONLY" {{ $tenant->booking_policy === 'ADDED_CUSTOMERS_ONLY' ? 'selected' : '' }}>
                            🔒 Pre-Approved CRM Customers Only (Non-added users cannot book)
                        </option>
                    </select>
                </div>

                <!-- Notification Dispatch Target -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-2">
                        <i class="fas fa-bell text-amber-500 mr-1"></i> Live Booking Alert Dispatch Target
                    </label>
                    <select name="notification_target" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl text-xs font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="DISPATCH_TO_BOTH" {{ $tenant->notification_target === 'DISPATCH_TO_BOTH' ? 'selected' : '' }}>
                            🔔 Send Live Popup Alert to BOTH Shop Owner & Selected Stylist
                        </option>
                        <option value="DISPATCH_TO_STAFF" {{ $tenant->notification_target === 'DISPATCH_TO_STAFF' ? 'selected' : '' }}>
                            💇 Send Live Popup Alert Directly to Selected Stylist / Staff Workstation
                        </option>
                        <option value="DISPATCH_TO_OWNER" {{ $tenant->notification_target === 'DISPATCH_TO_OWNER' ? 'selected' : '' }}>
                            🏬 Send Live Popup Alert Directly to Shop Owner Dashboard Only
                        </option>
                    </select>
                </div>
            </div>

            <div class="flex justify-end">
                <button type="submit" class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-2xl transition shadow-md">
                    <i class="fas fa-save mr-1.5"></i> Save Booking Policy Settings
                </button>
            </div>
        </form>
    </div>

    <!-- Active Branches -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-8">
        <div class="flex justify-between items-center mb-6">
            <div>
                <h3 class="text-lg font-bold text-gray-900">Your Branches & Locations</h3>
                <p class="text-xs text-gray-500 mt-0.5">Manage the operational locations of {{ $tenant->business_name }}</p>
            </div>
            <span class="text-xs font-semibold bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg border border-gray-200">
                <i class="fas fa-map-marker-alt text-red-500 mr-1"></i> {{ count($branches) }} Location(s)
            </span>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            @forelse($branches as $branch)
            <div class="border border-gray-200 rounded-xl p-5 bg-gray-50/50 hover:bg-white hover:border-blue-300 transition">
                <div class="flex justify-between items-start">
                    <div>
                        <h4 class="font-bold text-gray-900 text-base">{{ $branch->name }}</h4>
                        <p class="text-xs text-gray-500 mt-1"><i class="fas fa-location-arrow text-blue-500 mr-1"></i> {{ $branch->city }}, {{ $branch->state }} (PIN: {{ $branch->pin_code ?? '110001' }})</p>
                    </div>
                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
                        Active Branch
                    </span>
                </div>
            </div>
            @empty
            <div class="col-span-2 text-center py-6 text-gray-500 text-sm">
                No branches registered yet.
            </div>
            @endforelse
        </div>
    </div>

    <!-- Recent Bookings Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 class="text-lg font-bold text-gray-900">Recent Customer Appointments</h3>
            <a href="{{ route('owner.appointments') }}" class="text-sm font-semibold text-blue-600 hover:text-blue-800">View All Appointments &rarr;</a>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">Booking ID</th>
                        <th class="px-6 py-4 font-semibold">Customer</th>
                        <th class="px-6 py-4 font-semibold">Service</th>
                        <th class="px-6 py-4 font-semibold">Stylist</th>
                        <th class="px-6 py-4 font-semibold">Price</th>
                        <th class="px-6 py-4 font-semibold">Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm">
                    @forelse($recentBookings as $booking)
                    <tr class="hover:bg-gray-50 transition">
                        <td class="px-6 py-4 font-mono font-medium text-gray-900">#{{ $booking->id }}</td>
                        <td class="px-6 py-4 font-medium text-gray-900">{{ $booking->customer->name ?? 'Guest' }}</td>
                        <td class="px-6 py-4 text-gray-600">{{ $booking->service->name ?? 'Service' }}</td>
                        <td class="px-6 py-4 text-gray-600">{{ $booking->staff->name ?? 'Unassigned' }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">₹{{ number_format($booking->amount, 2) }}</td>
                        <td class="px-6 py-4">
                            @if($booking->status === 'COMPLETED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Completed</span>
                            @elseif($booking->status === 'CONFIRMED')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">Confirmed</span>
                            @elseif($booking->status === 'PENDING')
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">Pending</span>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800">{{ $booking->status }}</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-calendar-times text-4xl mb-3 text-gray-300"></i>
                            <p>No customer appointments recorded yet.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- 🔔 Real-Time Live Booking Notification Popup Alert Modal -->
    <div id="new-booking-popup" class="fixed bottom-6 right-6 bg-white rounded-3xl p-6 shadow-2xl border-2 border-blue-500 max-w-md w-full hidden z-50 transform transition-all duration-300">
        <div class="flex items-start justify-between mb-3">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-2xl bg-blue-600 text-white flex items-center justify-center text-xl shadow-md">
                    <i class="fas fa-bell"></i>
                </div>
                <div>
                    <h4 class="font-black text-gray-900 text-base">🔔 REAL NEW BOOKING RECEIVED!</h4>
                    <p class="text-[11px] text-gray-500 font-semibold" id="popup-time">Just now</p>
                </div>
            </div>
            <button onclick="document.getElementById('new-booking-popup').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times text-sm"></i>
            </button>
        </div>

        <div class="bg-blue-50/60 rounded-2xl p-4 mb-4 border border-blue-100 text-xs">
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Booking ID:</span>
                <span class="font-bold text-gray-900" id="popup-id">#--</span>
            </div>
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Customer:</span>
                <span class="font-bold text-gray-900" id="popup-customer">--</span>
            </div>
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Service:</span>
                <span class="font-bold text-gray-900" id="popup-service">--</span>
            </div>
            <div class="flex justify-between mb-1">
                <span class="text-gray-500">Assigned Stylist:</span>
                <span class="font-bold text-gray-900" id="popup-stylist">--</span>
            </div>
            <div class="flex justify-between">
                <span class="text-gray-500">Total Price:</span>
                <span class="font-black text-emerald-700" id="popup-price">₹0.00</span>
            </div>
        </div>

        <div class="flex space-x-3">
            <button onclick="document.getElementById('new-booking-popup').classList.add('hidden')" class="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-xs rounded-xl transition">
                Dismiss
            </button>
            <a href="{{ route('owner.appointments') }}" class="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl text-center transition shadow-md">
                View Appointments &rarr;
            </a>
        </div>
    </div>

    <script>
        // Real-Time AJAX Polling for New Bookings from Customer Checkout
        function pollUnreadBooking() {
            fetch("{{ route('owner.api.unread_booking') }}")
                .then(response => response.json())
                .then(data => {
                    if (data.has_new) {
                        document.getElementById('popup-id').innerText = '#' + data.id;
                        document.getElementById('popup-customer').innerText = data.customer_name;
                        document.getElementById('popup-service').innerText = data.service_name;
                        document.getElementById('popup-stylist').innerText = data.staff_name;
                        document.getElementById('popup-price').innerText = '₹' + data.amount;
                        document.getElementById('popup-time').innerText = data.time_ago;

                        document.getElementById('new-booking-popup').classList.remove('hidden');
                    }
                })
                .catch(err => console.log('Polling unread booking:', err));
        }

        // Poll every 3 seconds for newly placed customer bookings
        setInterval(pollUnreadBooking, 3000);
        pollUnreadBooking();
    </script>
@endsection
