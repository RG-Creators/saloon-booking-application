<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Stylist Workstation') - Glamora Staff</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        body { font-family: 'Poppins', 'Plus Jakarta Sans', sans-serif; background-color: #f8fafc; }
        .sidebar-glow { background: linear-gradient(180deg, #0b0f19 0%, #111827 60%, #1e1b4b 100%); }
        .nav-active { background: linear-gradient(90deg, #7c3aed 0%, #4f46e5 100%); border-left: 4px solid #a78bfa; box-shadow: 0 4px 18px rgba(124, 58, 237, 0.4); }
        .glass-header { background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(16px); }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 99px; }
    </style>
</head>
<body x-data="{ sidebarOpen: false }" class="bg-slate-50 flex h-screen overflow-hidden antialiased selection:bg-purple-600 selection:text-white">

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

    <!-- 🌟 RESPONSIVE OBSIDIAN LUXE SIDEBAR (STAFF / STYLIST) -->
    <aside :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'" 
           class="fixed md:static inset-y-0 left-0 w-64 sidebar-glow text-white flex flex-col z-40 shadow-2xl border-r border-slate-800/80 transition-transform duration-300 ease-in-out">
        <div class="h-16 flex items-center justify-between px-6 border-b border-slate-800/80 bg-slate-950/60">
            <h1 class="text-xl font-extrabold text-white tracking-tight flex items-center">
                <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-purple-600 to-indigo-500 flex items-center justify-center text-white text-sm mr-2.5 shadow-md">
                    <i class="fas fa-cut"></i>
                </div>
                Glamora <span class="text-[10px] bg-purple-500/20 text-purple-300 border border-purple-500/30 px-2 py-0.5 rounded-full ml-2 uppercase font-extrabold">Stylist</span>
            </h1>
            <button @click="sidebarOpen = false" class="md:hidden text-slate-400 hover:text-white p-1.5 rounded-lg transition" title="Close sidebar">
                <i class="fas fa-times text-lg"></i>
            </button>
        </div>

        <div class="px-5 py-4 mx-3 my-3 bg-slate-800/40 rounded-2xl border border-slate-700/50 backdrop-blur-sm">
            <p class="text-[10px] text-slate-400 uppercase font-black tracking-wider">Stylist Workstation</p>
            <h2 class="text-xs font-bold text-slate-100 truncate mt-0.5">{{ auth()->user()->name }}</h2>
            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-black bg-purple-500/10 text-purple-400 border border-purple-500/20 mt-1.5">
                <span class="w-1.5 h-1.5 rounded-full bg-purple-400 mr-1.5 animate-ping"></span> On Active Shift
            </span>
        </div>

        <nav class="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
            <a href="{{ route('staff.dashboard') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('staff.dashboard') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-purple-400"><i class="fas fa-calendar-check text-sm"></i></span> My Daily Schedule
            </a>
        </nav>

        <div class="p-3 m-3 bg-slate-950/80 rounded-2xl border border-slate-800/80">
            <div class="flex items-center justify-between">
                <div class="flex items-center min-w-0">
                    <div class="w-8 h-8 rounded-xl bg-purple-600 text-white font-extrabold flex items-center justify-center text-xs shadow-md">
                        {{ substr(auth()->user()->name, 0, 1) }}
                    </div>
                    <div class="ml-2.5 truncate">
                        <p class="text-xs font-bold text-slate-100 truncate leading-tight">{{ auth()->user()->name }}</p>
                        <p class="text-[10px] text-purple-400 font-extrabold truncate mt-0.5">Staff Stylist</p>
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

    <!-- Main Content -->
    <div class="flex-1 flex flex-col overflow-hidden">
        <header class="h-16 glass-header border-b border-slate-200/80 flex items-center justify-between px-4 md:px-8 z-10 shadow-xs">
            <div class="flex items-center space-x-3">
                <button @click="sidebarOpen = true" class="md:hidden text-slate-700 hover:text-purple-600 p-2 rounded-xl border border-slate-200 bg-white shadow-2xs transition" title="Open menu">
                    <i class="fas fa-bars text-lg"></i>
                </button>
                <h2 class="text-base md:text-lg font-bold text-slate-900 tracking-tight">@yield('title')</h2>
            </div>
            <div class="flex items-center space-x-3">
                <span class="text-xs bg-purple-50 text-purple-700 px-3 py-1 rounded-full font-bold border border-purple-200/60 shadow-2xs">
                    <i class="fas fa-user-circle mr-1"></i> Stylist Workstation
                </span>
            </div>
        </header>

        <main class="flex-1 overflow-y-auto p-8">
            @if(session('success'))
                <div class="mb-6 bg-emerald-50 border border-emerald-200 text-emerald-800 p-4 rounded-xl font-medium text-sm flex items-center shadow-sm">
                    <i class="fas fa-check-circle text-emerald-500 mr-2 text-lg"></i> {{ session('success') }}
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    <!-- Notification Sound Audio Element -->
    <audio id="notification-sound" src="https://actions.google.com/sounds/v1/alarms/beep_short.ogg" preload="auto"></audio>

    <!-- 🔔 GLOBAL LIVE REAL-TIME BOOKING ALERT MODAL (STAFF) -->
    <div id="staff-booking-modal" class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center hidden z-50">
        <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl border-2 border-purple-500 animate-pulse">
            <div class="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-2xl bg-purple-600 text-white flex items-center justify-center text-xl shadow-md">
                        <i class="fas fa-bell"></i>
                    </div>
                    <div>
                        <h4 class="font-black text-gray-900 text-base">🔔 NEW APPOINTMENT!</h4>
                        <p class="text-[11px] text-gray-500 font-semibold" id="staff-popup-time">Just now</p>
                    </div>
                </div>
                <button type="button" onclick="closeStaffModal()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times text-lg"></i>
                </button>
            </div>

            <div class="bg-purple-50/70 rounded-2xl p-4 mb-6 border border-purple-100 text-xs">
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Booking ID:</span>
                    <span class="font-bold text-gray-900" id="staff-popup-id">#--</span>
                </div>
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Customer Name:</span>
                    <span class="font-bold text-gray-900" id="staff-popup-customer">--</span>
                </div>
                <div class="flex justify-between mb-1.5">
                    <span class="text-gray-500">Requested Service:</span>
                    <span class="font-bold text-gray-900" id="staff-popup-service">--</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-gray-500">Service Price:</span>
                    <span class="font-black text-emerald-700" id="staff-popup-price">₹0.00</span>
                </div>
            </div>

            <button type="button" onclick="closeStaffModal()" class="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-800 font-bold text-xs rounded-2xl transition shadow-sm flex items-center justify-center">
                Acknowledge Alert
            </button>
        </div>
    </div>

    <script>
        let staffAlertBookingId = null;

        function checkStaffUnreadBooking() {
            fetch("{{ route('staff.api.unread_booking') }}")
                .then(res => res.json())
                .then(data => {
                    if (data.has_new && data.id !== staffAlertBookingId) {
                        staffAlertBookingId = data.id;

                        document.getElementById('staff-popup-id').innerText = '#' + data.id;
                        document.getElementById('staff-popup-customer').innerText = data.customer_name;
                        document.getElementById('staff-popup-service').innerText = data.service_name;
                        document.getElementById('staff-popup-price').innerText = '₹' + data.amount;
                        document.getElementById('staff-popup-time').innerText = data.time_ago;

                        document.getElementById('staff-booking-modal').classList.remove('hidden');

                        // Play sound notification
                        let audio = document.getElementById('notification-sound');
                        if (audio) {
                            audio.play().catch(e => console.log('Audio playback blocked by browser:', e));
                        }
                    }
                })
                .catch(err => console.log('Staff polling unread booking:', err));
        }

        function closeStaffModal() {
            document.getElementById('staff-booking-modal').classList.add('hidden');
        }

        // Poll every 3 seconds for assigned staff
        setInterval(checkStaffUnreadBooking, 3000);
        checkStaffUnreadBooking();
    </script>
</body>
</html>
