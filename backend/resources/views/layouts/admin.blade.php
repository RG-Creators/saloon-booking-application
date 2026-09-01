<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SaaS Administration | @yield('title')</title>
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
<body x-data="{ sidebarOpen: false }" class="flex h-screen overflow-hidden antialiased selection:bg-indigo-600 selection:text-white bg-slate-50">

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

    <!-- 🌟 RESPONSIVE OBSIDIAN LUXE SIDEBAR (ADMIN / SUBADMIN) -->
    <aside :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'" 
           class="fixed md:static inset-y-0 left-0 w-64 sidebar-glow text-white flex flex-col z-40 shadow-2xl border-r border-slate-800/80 transition-transform duration-300 ease-in-out">
        <div class="h-16 flex items-center justify-between px-6 bg-slate-950/60 border-b border-slate-800/80">
            <h1 class="text-xl font-extrabold tracking-tight text-white flex items-center">
                <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-amber-500 to-orange-500 flex items-center justify-center text-white text-sm mr-2.5 shadow-md">
                    <i class="fas fa-crown"></i>
                </div>
                Glamora
            </h1>
            <div class="flex items-center space-x-2">
                @if(auth()->user()->hasRole('SUPER_ADMIN'))
                    <span class="bg-amber-500/15 text-amber-400 border border-amber-500/30 text-[9px] font-black px-2 py-0.5 rounded-full uppercase tracking-wider">SUPER ADMIN</span>
                @else
                    <span class="bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 text-[9px] font-black px-2 py-0.5 rounded-full uppercase tracking-wider">SUBADMIN</span>
                @endif
                <button @click="sidebarOpen = false" class="md:hidden text-slate-400 hover:text-white p-1.5 rounded-lg transition" title="Close sidebar">
                    <i class="fas fa-times text-lg"></i>
                </button>
            </div>
        </div>

        <nav class="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
            <a href="{{ route('admin.dashboard') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.dashboard') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-indigo-400"><i class="fas fa-chart-pie text-sm"></i></span> Overview Dashboard
            </a>

            @can('manage shops')
            <a href="{{ route('admin.tenants') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.tenants') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-emerald-400"><i class="fas fa-store text-sm"></i></span> Shops & Tenants
            </a>
            @endcan

            @can('manage users')
            <a href="{{ route('admin.users') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.users') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-purple-400"><i class="fas fa-users text-sm"></i></span> System Users
            </a>
            @endcan

            @can('manage subadmins')
            <a href="{{ route('admin.subadmins') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.subadmins') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-amber-400"><i class="fas fa-user-shield text-sm"></i></span> Subadmin Staff
            </a>
            @endcan

            @can('send notifications')
            <a href="{{ route('admin.notifications') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.notifications') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-teal-400"><i class="fas fa-paper-plane text-sm"></i></span> Push Broadcasts
            </a>
            @endcan

            @can('view audit logs')
            <a href="{{ route('admin.logs') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.logs') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-cyan-400"><i class="fas fa-clipboard-list text-sm"></i></span> Audit Logs
            </a>
            <a href="{{ route('admin.crash-logs') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.crash-logs') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-red-500"><i class="fas fa-bug text-sm"></i></span> Crash Monitor
            </a>
            @endcan

            @can('manage billing')
            <a href="{{ route('admin.billing') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.billing') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-emerald-400"><i class="fas fa-file-invoice-dollar text-sm"></i></span> SaaS Ledger
            </a>
            @endcan

            @can('manage settings')
            <a href="{{ route('admin.settings') }}" class="flex items-center px-4 py-3 text-xs rounded-xl transition duration-150 {{ request()->routeIs('admin.settings') ? 'nav-active text-white font-bold' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white font-medium' }}">
                <span class="w-7 text-indigo-400"><i class="fas fa-sliders-h text-sm"></i></span> Platform Settings
            </a>
            @endcan
        </nav>

        <div class="p-3 m-3 bg-slate-950/80 rounded-2xl border border-slate-800/80">
            <div class="flex items-center justify-between">
                <div class="flex items-center min-w-0">
                    <div class="w-8 h-8 rounded-xl {{ auth()->user()->hasRole('SUPER_ADMIN') ? 'bg-amber-500 text-amber-950' : 'bg-emerald-500 text-emerald-950' }} font-extrabold flex items-center justify-center text-xs shadow-md">
                        {{ substr(auth()->user()->name ?? 'A', 0, 1) }}
                    </div>
                    <div class="ml-2.5 truncate">
                        <p class="text-xs font-bold text-slate-100 truncate leading-tight">{{ auth()->user()->name ?? 'Admin' }}</p>
                        <p class="text-[10px] font-extrabold {{ auth()->user()->hasRole('SUPER_ADMIN') ? 'text-amber-400' : 'text-emerald-400' }} truncate mt-0.5">
                            {{ auth()->user()->hasRole('SUPER_ADMIN') ? 'Super Admin' : 'Subadmin Employee' }}
                        </p>
                    </div>
                </div>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button type="submit" class="p-2 text-slate-400 hover:text-red-400 hover:bg-slate-800 rounded-lg transition" title="Logout">
                        <i class="fas fa-power-off text-xs"></i>
                    </button>
                </form>
            </div>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 flex flex-col h-screen overflow-hidden">
        <!-- Header -->
        <header class="h-16 bg-white/80 backdrop-blur-md border-b border-slate-200/80 flex items-center justify-between px-4 md:px-8 z-10 shadow-xs">
            <div class="flex items-center space-x-3">
                <button @click="sidebarOpen = true" class="md:hidden text-slate-700 hover:text-indigo-600 p-2 rounded-xl border border-slate-200 bg-white shadow-2xs transition" title="Open menu">
                    <i class="fas fa-bars text-lg"></i>
                </button>
                <h2 class="text-base md:text-lg font-bold text-slate-800">@yield('title')</h2>
            </div>
            <div class="flex items-center space-x-4">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200/60 shadow-2xs">
                    <span class="w-2 h-2 rounded-full bg-emerald-500 mr-2 animate-ping"></span> Live SaaS Platform
                </span>
            </div>
        </header>

        <!-- Page Content -->
        <div class="flex-1 overflow-y-auto p-8">
            @yield('content')
        </div>
    </main>

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
