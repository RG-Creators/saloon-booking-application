<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Book Salons & Grooming') - Glamora</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        body { font-family: 'Poppins', 'Plus Jakarta Sans', sans-serif; background-color: #f8fafc; }
        .glass-nav { background: rgba(255, 255, 255, 0.92); backdrop-filter: blur(16px); }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 99px; }
    </style>
</head>
<body class="bg-slate-50 flex flex-col min-h-screen antialiased selection:bg-blue-600 selection:text-white">

    <!-- Responsive Top Navigation Bar -->
    <header class="glass-nav border-b border-slate-200/80 sticky top-0 z-40 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
            <!-- Brand Logo -->
            <a href="{{ route('customer.dashboard') }}" class="text-xl sm:text-2xl font-black tracking-tight text-blue-600 flex items-center">
                <i class="fas fa-scissors mr-2 text-blue-600"></i> Glamora
            </a>

            <!-- Navigation Links (Desktop & Mobile Scrollable) -->
            <nav class="hidden md:flex items-center space-x-2 bg-slate-100/80 p-1.5 rounded-2xl border border-slate-200/60">
                <a href="{{ route('customer.dashboard') }}" class="px-4 py-2 text-xs font-bold rounded-xl transition {{ request()->routeIs('customer.dashboard') ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:text-slate-900' }}">
                    <i class="fas fa-home mr-1"></i> Dashboard
                </a>
                <a href="{{ route('customer.explore') }}" class="px-4 py-2 text-xs font-bold rounded-xl transition {{ request()->routeIs('customer.explore') ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:text-slate-900' }}">
                    <i class="fas fa-compass mr-1"></i> Explore Salons
                </a>
                <a href="{{ route('customer.bookings') }}" class="px-4 py-2 text-xs font-bold rounded-xl transition {{ request()->routeIs('customer.bookings') ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:text-slate-900' }}">
                    <i class="fas fa-calendar-check mr-1"></i> My Appointments
                </a>
            </nav>

            <!-- User Avatar & Sign Out -->
            <div class="flex items-center space-x-3">
                <div class="flex items-center space-x-2">
                    <div class="w-8 h-8 sm:w-9 sm:h-9 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs sm:text-sm">
                        {{ substr(auth()->user()->name ?? 'Guest', 0, 1) }}
                    </div>
                    <span class="hidden sm:inline-block text-xs sm:text-sm font-bold text-gray-800">{{ auth()->user()->name ?? 'User' }}</span>
                </div>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="text-xs bg-slate-100 hover:bg-red-50 text-slate-600 hover:text-red-600 px-3 py-1.5 rounded-lg transition font-semibold">
                        <i class="fas fa-sign-out-alt md:hidden"></i>
                        <span class="hidden md:inline">Sign Out</span>
                    </button>
                </form>
            </div>
        </div>

        <!-- Mobile Navigation Sub-bar -->
        <div class="md:hidden flex items-center justify-around bg-slate-100/90 border-t border-slate-200/60 px-2 py-1.5">
            <a href="{{ route('customer.dashboard') }}" class="px-3 py-1.5 text-xs font-bold rounded-lg transition {{ request()->routeIs('customer.dashboard') ? 'bg-white text-blue-600 shadow-xs' : 'text-slate-600' }}">
                <i class="fas fa-home mr-1"></i> Home
            </a>
            <a href="{{ route('customer.explore') }}" class="px-3 py-1.5 text-xs font-bold rounded-lg transition {{ request()->routeIs('customer.explore') ? 'bg-white text-blue-600 shadow-xs' : 'text-slate-600' }}">
                <i class="fas fa-compass mr-1"></i> Explore
            </a>
            <a href="{{ route('customer.bookings') }}" class="px-3 py-1.5 text-xs font-bold rounded-lg transition {{ request()->routeIs('customer.bookings') ? 'bg-white text-blue-600 shadow-xs' : 'text-slate-600' }}">
                <i class="fas fa-calendar-check mr-1"></i> Bookings
            </a>
        </div>
    </header>

    <!-- Main Workspace -->
    <main class="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6">
        @yield('content')
    </main>

    <!-- Footer -->
    <footer class="bg-white border-t border-slate-200/80 py-6 text-center text-xs text-slate-400">
        Glamora Multi-Tenant Salon & Barber Platform • All Rights Reserved
    </footer>

</body>
</html>
