<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glamora | @yield('title')</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <!-- AlpineJS for interactive dropdowns/modals without Node.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #f3f4f6; }
    </style>
</head>
<body class="flex flex-col h-screen overflow-hidden text-gray-900">

    <!-- Top Navigation Bar -->
    <header class="bg-white shadow-sm border-b border-gray-100 z-20">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex items-center">
                    <h1 class="text-2xl font-extrabold text-blue-600 tracking-tight">Glamora</h1>
                    <span class="ml-4 text-xs bg-gray-100 text-gray-600 font-medium px-2.5 py-0.5 rounded border border-gray-200 uppercase tracking-wider">
                        @yield('role', 'Dashboard')
                    </span>
                </div>
                
                <div class="flex items-center space-x-6">
                    <button class="text-gray-400 hover:text-gray-600 transition"><i class="fas fa-bell"></i></button>
                    
                    <!-- Profile Dropdown (Alpine.js) -->
                    <div x-data="{ open: false }" class="relative">
                        <button @click="open = !open" @click.away="open = false" class="flex items-center space-x-2 focus:outline-none">
                            <div class="w-9 h-9 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                                {{ substr(auth()->user()->name, 0, 1) }}
                            </div>
                            <span class="text-sm font-medium text-gray-700 hidden sm:block">{{ auth()->user()->name }}</span>
                            <i class="fas fa-chevron-down text-xs text-gray-400"></i>
                        </button>

                        <div x-show="open" style="display: none;" class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 z-30">
                            <div class="px-4 py-3">
                                <p class="text-sm text-gray-900 font-medium">{{ auth()->user()->name }}</p>
                                <p class="text-xs text-gray-500 truncate">{{ auth()->user()->email }}</p>
                            </div>
                            <div class="py-1">
                                <form method="POST" action="{{ route('logout') }}">
                                    @csrf
                                    <button type="submit" class="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-50">
                                        Sign out
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <div class="flex-1 flex overflow-hidden max-w-7xl mx-auto w-full">
        <!-- Optional Sidebar (Yielded if needed) -->
        @hasSection('sidebar')
            <aside class="w-64 bg-white border-r border-gray-100 hidden md:block overflow-y-auto">
                @yield('sidebar')
            </aside>
        @endif

        <!-- Main Page Content -->
        <main class="flex-1 overflow-y-auto bg-gray-50 p-4 sm:p-8">
            <div class="mb-6">
                <h2 class="text-2xl font-bold text-gray-900">@yield('title')</h2>
                <p class="text-sm text-gray-500 mt-1">@yield('subtitle')</p>
            </div>
            
            @yield('content')
        </main>
    </div>

</body>
</html>
