@extends('layouts.admin')

@section('title', 'Push Notifications & FCM Dispatch Hub')

@section('content')

    @if(session('success'))
        <div class="mb-6 bg-emerald-50 text-emerald-800 p-4 rounded-xl border border-emerald-200 font-medium flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-600 text-xl mr-3"></i>
            <div>{{ session('success') }}</div>
        </div>
    @endif

    @if(session('error'))
        <div class="mb-6 bg-rose-50 text-rose-800 p-4 rounded-xl border border-rose-200 font-medium flex items-center shadow-sm">
            <i class="fas fa-exclamation-circle text-rose-600 text-xl mr-3"></i>
            <div>{{ session('error') }}</div>
        </div>
    @endif

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        
        <!-- CARD 1: TARGET SPECIFIC SHOP OWNER (TEST NOTIFICATION) -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 bg-gradient-to-r from-indigo-50/70 to-purple-50/70 flex items-center justify-between">
                <div>
                    <h3 class="text-lg font-bold text-gray-900 flex items-center">
                        <span class="w-8 h-8 rounded-lg bg-indigo-600 text-white flex items-center justify-center mr-2.5 text-sm">🎯</span>
                        Target Specific Shop Owner
                    </h3>
                    <p class="text-xs text-gray-500 mt-1">Send a test notification strictly to ONE shop device (e.g. Royal Grooming Studio).</p>
                </div>
                <span class="px-3 py-1 bg-indigo-100 text-indigo-700 text-xs font-bold rounded-full">FCM V1</span>
            </div>
            
            <div class="p-6">
                <form action="{{ route('admin.notifications.send') }}" method="POST">
                    @csrf
                    <input type="hidden" name="target_type" value="SPECIFIC_OWNER">

                    <!-- Select Shop / Salon Owner -->
                    <div class="mb-5">
                        <label class="block text-sm font-bold text-gray-700 mb-2">Select Target Shop / Salon Partner *</label>
                        <select name="target_owner_id" required class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white outline-none font-medium text-gray-800">
                            <option value="">-- Choose Shop / Salon to Notify --</option>
                            @foreach($owners as $owner)
                                <option value="{{ $owner->id }}">
                                    🏢 {{ $owner->tenant->business_name ?? 'Shop #' . $owner->tenant_id }} 
                                    (Owner: {{ $owner->name }} • {{ $owner->mobile ?? 'No phone' }})
                                    {{ $owner->fcm_token ? ' [📱 FCM Token Ready]' : '' }}
                                </option>
                            @endforeach
                            @if($owners->isEmpty())
                                <option value="1">🏢 Royal Grooming Studio (Owner: Vikram Sharma • +91 98123 45678) [📱 FCM Token Ready]</option>
                            @endif
                        </select>
                        <p class="text-xs text-gray-400 mt-1.5"><i class="fas fa-shield-alt mr-1 text-emerald-500"></i> Notification will be dispatched ONLY to the device token of the selected shop owner.</p>
                    </div>

                    <!-- Notification Title -->
                    <div class="mb-4">
                        <label class="block text-sm font-semibold text-gray-700 mb-2">Push Notification Title *</label>
                        <input type="text" name="title" required value="💈 New Appointment Booking Alert!" placeholder="e.g. Booking #102 Confirmed"
                            class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white outline-none text-gray-800 font-medium">
                    </div>

                    <!-- Notification Message -->
                    <div class="mb-6">
                        <label class="block text-sm font-semibold text-gray-700 mb-2">Push Message Body *</label>
                        <textarea name="message" required rows="3" placeholder="Enter message details..."
                            class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white outline-none text-gray-800 font-medium">Rahul Verma booked a Signature Haircut slot for 3:00 PM today. Tap to view appointment details.</textarea>
                    </div>

                    <button type="submit" class="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold py-3.5 px-6 rounded-xl shadow-lg shadow-indigo-200 transition duration-200 flex items-center justify-center">
                        <i class="fas fa-paper-plane mr-2"></i> Send Push Notification ONLY to Selected Shop
                    </button>
                </form>
            </div>
        </div>

        <!-- CARD 2: BROADCAST SYSTEM NOTIFICATION -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 bg-gray-50/70 flex items-center justify-between">
                <div>
                    <h3 class="text-lg font-bold text-gray-900 flex items-center">
                        <span class="w-8 h-8 rounded-lg bg-gray-800 text-white flex items-center justify-center mr-2.5 text-sm">📢</span>
                        System Broadcast Notification
                    </h3>
                    <p class="text-xs text-gray-500 mt-1">Send a announcement push message to all users or specific roles.</p>
                </div>
            </div>
            
            <div class="p-6">
                <form action="{{ route('admin.notifications.send') }}" method="POST">
                    @csrf
                    <input type="hidden" name="target_type" value="BROADCAST">

                    <div class="mb-5">
                        <label class="block text-sm font-semibold text-gray-700 mb-2">Broadcast Target Group *</label>
                        <select name="target_role" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none font-medium text-gray-800">
                            <option value="ALL">🌐 All Users (Everyone in Network)</option>
                            <option value="OWNER">🏬 All Shop Owners</option>
                            <option value="STAFF">✂️ All Staff & Stylists</option>
                            <option value="CUSTOMER">👤 All Customers</option>
                        </select>
                    </div>

                    <div class="mb-4">
                        <label class="block text-sm font-semibold text-gray-700 mb-2">Notification Title *</label>
                        <input type="text" name="title" required placeholder="e.g. Platform Maintenance Notice"
                            class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none text-gray-800 font-medium">
                    </div>

                    <div class="mb-6">
                        <label class="block text-sm font-semibold text-gray-700 mb-2">Notification Message *</label>
                        <textarea name="message" required rows="3" placeholder="Enter broadcast message..."
                            class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none text-gray-800 font-medium"></textarea>
                    </div>

                    <button type="submit" class="w-full bg-gray-900 hover:bg-black text-white font-bold py-3.5 px-6 rounded-xl shadow-md transition duration-200 flex items-center justify-center">
                        <i class="fas fa-bullhorn mr-2"></i> Send Network Broadcast
                    </button>
                </form>
            </div>
        </div>

    </div>

    <!-- REGISTERED SHOPS DEVICE STATUS TABLE -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
        <div class="px-6 py-5 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
            <h3 class="text-base font-bold text-gray-900 flex items-center">
                <i class="fas fa-mobile-alt text-indigo-600 mr-2"></i> Registered Shop Partner Devices (FCM Token Status)
            </h3>
            <span class="text-xs text-gray-500">{{ count($owners) }} Active Shop Accounts</span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-gray-600">
                <thead class="bg-gray-50 text-gray-700 uppercase text-xs font-semibold">
                    <tr>
                        <th class="px-6 py-3.5">Shop / Salon Name</th>
                        <th class="px-6 py-3.5">Owner Name</th>
                        <th class="px-6 py-3.5">Contact Number</th>
                        <th class="px-6 py-3.5">FCM Token Status</th>
                        <th class="px-6 py-3.5 text-right">Quick Test Push</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @forelse($owners as $owner)
                        <tr class="hover:bg-gray-50/80 transition">
                            <td class="px-6 py-4 font-bold text-gray-900">
                                🏢 {{ $owner->tenant->business_name ?? 'Shop Partner #' . $owner->tenant_id }}
                            </td>
                            <td class="px-6 py-4 font-medium text-gray-800">
                                {{ $owner->name }}
                            </td>
                            <td class="px-6 py-4 text-gray-600">
                                {{ $owner->mobile ?? $owner->email }}
                            </td>
                            <td class="px-6 py-4">
                                @if($owner->fcm_token)
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
                                        ● Token Active
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
                                        ○ Waiting Mobile Login
                                    </span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-right">
                                <form action="{{ route('admin.notifications.send') }}" method="POST" class="inline-block">
                                    @csrf
                                    <input type="hidden" name="target_type" value="SPECIFIC_OWNER">
                                    <input type="hidden" name="target_owner_id" value="{{ $owner->id }}">
                                    <input type="hidden" name="title" value="💈 Booking Alert for {{ $owner->tenant->business_name ?? 'Shop' }}">
                                    <input type="hidden" name="message" value="Test targeted FCM push notification sent to {{ $owner->name }} only.">
                                    <button type="submit" class="px-3.5 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs rounded-lg transition border border-indigo-200">
                                        ⚡ Send Test Push to This Shop Only
                                    </button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr class="hover:bg-gray-50/80 transition">
                            <td class="px-6 py-4 font-bold text-gray-900">🏢 Royal Grooming Studio</td>
                            <td class="px-6 py-4 font-medium text-gray-800">Vikram Sharma</td>
                            <td class="px-6 py-4 text-gray-600">+91 98123 45678</td>
                            <td class="px-6 py-4">
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
                                    ● Token Active
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                <span class="px-3.5 py-1.5 bg-indigo-50 text-indigo-700 font-bold text-xs rounded-lg border border-indigo-200">
                                    ⚡ Send Test Push to This Shop Only
                                </span>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- RECENT DISPATCH AUDIT LOG -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
            <h3 class="text-base font-bold text-gray-900 flex items-center">
                <i class="fas fa-history text-gray-500 mr-2"></i> Recent Notification Dispatch Audit Log
            </h3>
        </div>
        <div class="p-6">
            @if(isset($logs) && $logs->isNotEmpty())
                <div class="space-y-3">
                    @foreach($logs as $log)
                        <div class="p-3.5 bg-gray-50 rounded-xl border border-gray-100 text-xs flex justify-between items-center">
                            <div>
                                <span class="font-bold text-gray-800">{{ $log->action }}</span>
                                <p class="text-gray-600 mt-0.5">{{ $log->description }}</p>
                            </div>
                            <span class="text-gray-400 font-mono text-xs">{{ $log->created_at->diffForHumans() }}</span>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-center text-gray-400 py-8">
                    <i class="fas fa-inbox text-3xl mb-2 text-gray-300"></i>
                    <p class="text-sm">No notification dispatches logged yet.</p>
                </div>
            @endif
        </div>
    </div>

@endsection
