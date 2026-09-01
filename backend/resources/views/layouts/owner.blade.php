<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Salon Dashboard') - Glamora Partner</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        body { font-family: 'Poppins', 'Plus Jakarta Sans', sans-serif; background-color: #f8fafc; }
        .sidebar-glow { background: linear-gradient(180deg, #0b0f19 0%, #111827 60%, #1e1b4b 100%); }
        .nav-active { background: linear-gradient(90deg, #4f46e5 0%, #7c3aed 100%); border-left: 4px solid #38bdf8; box-shadow: 0 4px 18px rgba(79, 70, 229, 0.4); }
        .glass-header { background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(16px); }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 99px; }
        ::-webkit-scrollbar-thumb:hover { background: #94a3b8; }
    </style>
</head>
<body x-data="{ sidebarOpen: false }" class="bg-slate-50 flex h-screen overflow-hidden antialiased selection:bg-indigo-600 selection:text-white">

    <!-- 📱 Mobile Overlay Touch-Outside Backdrop -->
    <div x-show="sidebarOpen" 
         x-transition:enter="transition-opacity ease-linear duration-200"
         x-transition:enter-start="opacity-0"
         x-transition:enter-end="opacity-100"
         x-transition:leave="transition-opacity ease-linear duration-200"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0"
         @click="sidebarOpen = false" 
         class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs z-30 md:hidden"
         style="display: none;">
    </div>

    <!-- 🌟 RESPONSIVE OBSIDIAN LUXE SIDEBAR -->
    <aside :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'" 
           class="fixed md:static inset-y-0 left-0 w-64 sidebar-glow text-white flex flex-col z-40 shadow-2xl border-r border-slate-800/80 transition-transform duration-300 ease-in-out">
        <!-- Logo Branding Header -->
        <div class="h-16 flex items-center justify-between px-6 border-b border-slate-800/80 bg-slate-950/60">
            <h1 class="text-xl font-extrabold text-white tracking-tight flex items-center">
                <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-indigo-500 to-violet-500 flex items-center justify-center text-white text-sm mr-2.5 shadow-md">
                    <i class="fas fa-scissors"></i>
                </div>
                Glamora <span class="text-[10px] bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 px-2 py-0.5 rounded-full ml-2 uppercase font-extrabold">Partner</span>
            </h1>
            <button @click="sidebarOpen = false" class="md:hidden text-slate-400 hover:text-white p-2 rounded-lg transition" title="Close sidebar">
                <i class="fas fa-times text-lg"></i>
            </button>
        </div>

        <!-- Tenant / Salon Identity Card -->
        <div class="px-5 py-4 mx-3 my-3 bg-slate-800/40 rounded-2xl border border-slate-700/50 backdrop-blur-sm">
            <p class="text-[10px] text-slate-400 uppercase font-black tracking-wider">Active Business Outlet</p>
            <h2 class="text-xs font-bold text-slate-100 truncate mt-0.5">
                {{ auth()->user()->tenant->business_name ?? 'Salon Business' }}
            </h2>
            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-black bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 mt-1.5">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 mr-1.5 animate-ping"></span> Verified Outlet
            </span>
        </div>

        <!-- Navigation Menu -->
        <nav class="flex-1 px-3 space-y-1.5 overflow-y-auto py-2">
            <a href="{{ route('owner.dashboard') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.dashboard') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-indigo-400"><i class="fas fa-chart-pie text-sm"></i></span> Overview Dashboard
            </a>
            <a href="{{ route('owner.appointments') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.appointments') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-emerald-400"><i class="fas fa-calendar-alt text-sm"></i></span> Appointments
            </a>
            <a href="{{ route('owner.services') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.services') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-purple-400"><i class="fas fa-cut text-sm"></i></span> Service Menu
            </a>
            <a href="{{ route('owner.combos') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.combos') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-amber-400"><i class="fas fa-layer-group text-sm"></i></span> Combos & Packages
            </a>
            <a href="{{ route('owner.staff') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.staff') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-teal-400"><i class="fas fa-users text-sm"></i></span> Staff & Stylists
            </a>
            <a href="{{ route('owner.schedules') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.schedules') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-cyan-400"><i class="fas fa-clock text-sm"></i></span> Hours & Shifts
            </a>
            <a href="{{ route('owner.customers') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.customers') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-indigo-400"><i class="fas fa-id-card text-sm"></i></span> Customer CRM
            </a>
            <a href="{{ route('owner.marketing') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.marketing') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-pink-400"><i class="fas fa-bullhorn text-sm"></i></span> Marketing & Offers
            </a>
            @php
                $globalBillingEnabled = \App\Models\PlatformSetting::where('key', 'billing_enabled')->value('value') === 'true';
            @endphp
            @if($globalBillingEnabled)
            <a href="{{ route('owner.billing') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('owner.billing') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-emerald-400"><i class="fas fa-file-invoice-dollar text-sm"></i></span> SaaS Billing & Ledger
            </a>
            @endif
        </nav>

        <!-- User Profile Card -->
        <div class="p-3 m-3 bg-slate-950/80 rounded-2xl border border-slate-800/80">
            <div class="flex items-center justify-between">
                <div class="flex items-center min-w-0">
                    <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-indigo-600 to-purple-600 text-white flex items-center justify-center font-extrabold text-xs shadow-md">
                        {{ substr(auth()->user()->name, 0, 1) }}
                    </div>
                    <div class="ml-2.5 truncate">
                        <p class="text-xs font-bold text-slate-100 truncate leading-tight">{{ auth()->user()->name }}</p>
                        <p class="text-[10px] text-slate-400 truncate mt-0.5">Shop Owner</p>
                    </div>
                </div>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="p-2 text-slate-400 hover:text-red-400 hover:bg-slate-800 rounded-lg transition" title="Sign Out">
                        <i class="fas fa-power-off text-xs"></i>
                    </button>
                </form>
            </div>
        </div>
    </aside>

    <!-- Main Workspace -->
    <div class="flex-1 flex flex-col overflow-hidden">
        <!-- Top Glass Header -->
        <header class="h-16 glass-header border-b border-slate-200/80 flex items-center justify-between px-4 md:px-8 z-10 shadow-xs">
            <div class="flex items-center space-x-3">
                <button @click="sidebarOpen = true" class="md:hidden text-slate-700 hover:text-indigo-600 p-2 rounded-xl border border-slate-200 bg-white shadow-2xs transition" title="Open menu">
                    <i class="fas fa-bars text-lg"></i>
                </button>
                <h2 class="text-base md:text-lg font-bold text-slate-900 tracking-tight">@yield('title')</h2>
            </div>
            
            <div class="flex items-center space-x-3">
                <span class="text-xs bg-indigo-50 text-indigo-700 px-3 py-1 rounded-full font-bold border border-indigo-200/60 shadow-2xs">
                    <i class="fas fa-shield-alt text-indigo-500 mr-1.5"></i> Owner Control Panel
                </span>
            </div>
        </header>

        <!-- Main Workspace -->
        <main class="flex-1 overflow-y-auto p-8">
            @if(session('success'))
                <div class="mb-6 bg-emerald-50 border border-emerald-200 text-emerald-800 p-4 rounded-xl font-medium text-sm flex items-center shadow-sm">
                    <i class="fas fa-check-circle text-emerald-500 mr-2 text-lg"></i> {{ session('success') }}
                </div>
            @endif

            @if(session('info'))
                <div class="mb-6 bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded-xl font-medium text-sm flex items-center shadow-sm">
                    <i class="fas fa-info-circle text-blue-500 mr-2 text-lg"></i> {{ session('info') }}
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    <!-- Notification Sound Audio Element -->
    <audio id="notification-sound" src="https://actions.google.com/sounds/v1/alarms/beep_short.ogg" preload="auto"></audio>

    <!-- 🔔 GLOBAL LIVE REAL-TIME BOOKING ACTION MODAL (Pops up on ANY screen) -->
    <div id="global-booking-modal" class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center hidden z-50">
        <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl border-2 border-blue-500 animate-pulse">
            <div class="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-2xl bg-blue-600 text-white flex items-center justify-center text-xl shadow-md">
                        <i class="fas fa-bell"></i>
                    </div>
                    <div>
                        <h4 class="font-black text-gray-900 text-base">🔔 NEW BOOKING REQUEST!</h4>
                        <p class="text-[11px] text-gray-500 font-semibold" id="global-popup-time">Just now</p>
                    </div>
                </div>
                <button type="button" onclick="closeGlobalModal()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times text-lg"></i>
                </button>
            </div>

            <div class="bg-blue-50/70 rounded-2xl p-4 mb-6 border border-blue-100 text-xs">
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Booking ID:</span>
                    <span class="font-bold text-gray-900" id="global-popup-id">#--</span>
                </div>
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Customer Name:</span>
                    <span class="font-bold text-gray-900" id="global-popup-customer">--</span>
                </div>
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Requested Service:</span>
                    <span class="font-bold text-gray-900" id="global-popup-service">--</span>
                </div>
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Assigned Stylist:</span>
                    <span class="font-bold text-gray-900" id="global-popup-stylist">--</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-gray-500">Service Price:</span>
                    <span class="font-black text-emerald-700" id="global-popup-price">₹0.00</span>
                </div>
            </div>

            <!-- Action Forms: Approve or Decline -->
            <div class="space-y-3">
                <form id="approve-form" action="" method="POST">
                    @csrf
                    <button type="submit" class="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-2xl transition shadow-md flex items-center justify-center">
                        <i class="fas fa-check-circle text-base mr-2"></i> Approve Booking Request
                    </button>
                </form>

                <div class="pt-2 border-t border-gray-100">
                    <form id="decline-form" action="" method="POST">
                        @csrf
                        <div class="mb-2">
                            <label class="block text-[10px] font-bold uppercase tracking-wider text-gray-500 mb-1">Decline Reason (Notifies Customer Instantly)</label>
                            <select name="decline_reason" required class="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold outline-none focus:ring-2 focus:ring-red-500">
                                <option value="Requested time slot is not free / fully booked">Slot is not free / Fully Booked</option>
                                <option value="Assigned stylist is unavailable">Assigned Stylist Unavailable</option>
                                <option value="Salon is closed at this time">Salon Closed at this time</option>
                            </select>
                        </div>
                        <button type="submit" class="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl transition shadow-sm flex items-center justify-center">
                            <i class="fas fa-times-circle text-base mr-2"></i> Decline Booking
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentAlertBookingId = null;

        function checkGlobalUnreadBooking() {
            fetch("{{ route('owner.api.unread_booking') }}")
                .then(res => res.json())
                .then(data => {
                    if (data.has_new && data.id !== currentAlertBookingId) {
                        currentAlertBookingId = data.id;

                        document.getElementById('global-popup-id').innerText = '#' + data.id;
                        document.getElementById('global-popup-customer').innerText = data.customer_name;
                        document.getElementById('global-popup-service').innerText = data.service_name;
                        document.getElementById('global-popup-stylist').innerText = data.staff_name;
                        document.getElementById('global-popup-price').innerText = '₹' + data.amount;
                        document.getElementById('global-popup-time').innerText = data.time_ago;

                        document.getElementById('approve-form').action = "/owner/appointments/" + data.id + "/approve";
                        document.getElementById('decline-form').action = "/owner/appointments/" + data.id + "/decline";

                        document.getElementById('global-booking-modal').classList.remove('hidden');

                        // Play sound notification
                        let audio = document.getElementById('notification-sound');
                        if (audio) {
                            audio.play().catch(e => console.log('Audio playback blocked by browser:', e));
                        }
                    }
                })
                .catch(err => console.log('Global polling unread booking:', err));
        }

        function closeGlobalModal() {
            document.getElementById('global-booking-modal').classList.add('hidden');
        }

        // Poll every 3 seconds across ALL owner screens
        setInterval(checkGlobalUnreadBooking, 3000);
        checkGlobalUnreadBooking();
    </script>

    <!-- 🔔 Global Bottom Toast Notification Container -->
    <div id="toast-container" class="fixed bottom-5 right-5 z-50 flex flex-col space-y-3 max-w-md w-full px-4 pointer-events-none"></div>

    <script>
        function showToast(message, type = 'success', rawError = null) {
            const container = document.getElementById('toast-container');
            if (!container) return;

            const toast = document.createElement('div');
            toast.className = 'pointer-events-auto bg-slate-900/95 text-white rounded-2xl p-4 shadow-2xl border border-slate-800 backdrop-blur-md transform translate-y-8 opacity-0 transition-all duration-300 flex flex-col space-y-2';

            let icon = '<i class="fas fa-check-circle text-emerald-400 text-lg mr-3"></i>';
            if (type === 'error') {
                icon = '<i class="fas fa-exclamation-triangle text-rose-400 text-lg mr-3"></i>';
            } else if (type === 'info') {
                icon = '<i class="fas fa-info-circle text-blue-400 text-lg mr-3"></i>';
            }

            let rawErrorHtml = '';
            if (rawError) {
                rawErrorHtml = `
                    <div class="mt-2 p-2.5 bg-rose-950/90 border border-rose-800/90 rounded-xl text-[11px] font-mono text-rose-200 overflow-x-auto max-h-36 shadow-inner">
                        <span class="font-extrabold uppercase text-rose-400 block mb-1">🚨 RAW EXCEPTION TRACE (DEBUG MODE ON):</span>
                        <code>${rawError}</code>
                    </div>
                `;
            }

            toast.innerHTML = `
                <div class="flex items-center justify-between">
                    <div class="flex items-center">
                        ${icon}
                        <span class="text-xs font-bold leading-snug">${message}</span>
                    </div>
                    <button onclick="this.closest('.pointer-events-auto').remove()" class="text-slate-400 hover:text-white ml-4 text-xs">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                ${rawErrorHtml}
            `;

            container.appendChild(toast);

            setTimeout(() => {
                toast.classList.remove('translate-y-8', 'opacity-0');
            }, 10);

            const timeout = rawError ? 12000 : 4500;
            setTimeout(() => {
                toast.classList.add('translate-y-8', 'opacity-0');
                setTimeout(() => toast.remove(), 300);
            }, timeout);
        }

        @if(session('success'))
            document.addEventListener('DOMContentLoaded', function() {
                showToast("{{ session('success') }}", 'success');
            });
        @endif

        @if(session('error'))
            document.addEventListener('DOMContentLoaded', function() {
                showToast("{{ session('error') }}", 'error');
            });
        @endif
    </script>
</body>
</html>
