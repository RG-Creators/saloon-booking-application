@extends('layouts.customer')

@section('title', 'Explore Salons & Multi-Branch Booking')

@section('content')
    @if(session('error'))
        <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-exclamation-circle text-red-500 text-lg mr-3"></i> {{ session('error') }}
        </div>
    @endif

    @if(session('success'))
        <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-500 text-lg mr-3"></i> {{ session('success') }}
        </div>
    @endif

    <!-- GPS Location Banner / Toast Notification Container -->
    <div id="location-banner" class="hidden mb-6 p-4 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-2xl shadow-md flex items-center justify-between transition-all duration-300">
        <div class="flex items-center space-x-3">
            <div class="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center font-bold">
                <i class="fas fa-crosshairs text-white animate-pulse"></i>
            </div>
            <div>
                <p class="text-xs font-black uppercase tracking-wider text-blue-100" id="location-title">GPS Detected</p>
                <p class="text-sm font-bold" id="location-subtitle">Showing salons near your area</p>
            </div>
        </div>
        <button type="button" onclick="dismissLocationBanner()" class="text-white/80 hover:text-white text-xs px-3 py-1.5 bg-white/10 rounded-xl">
            Dismiss
        </button>
    </div>

    <!-- Location & PIN Code Search Bar -->
    <div class="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 mb-8">
        <form action="{{ route('customer.explore') }}" method="GET" id="explore-filter-form" class="flex flex-col md:flex-row gap-4">
            <div class="flex-1 relative">
                <i class="fas fa-search absolute left-4 top-3.5 text-gray-400"></i>
                <input type="text" name="q" value="{{ $query }}" placeholder="Search by salon name or service (e.g. Grooming Lounge, Haircut)..." class="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
            </div>

            <div class="w-full md:w-72 relative">
                <i class="fas fa-map-pin absolute left-4 top-3.5 text-blue-500"></i>
                <input type="text" name="pincode" id="explore_pincode" value="{{ $pincode }}" placeholder="PIN Code (e.g. 110001)" class="w-full pl-10 pr-20 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                <button type="button" id="auto-gps-btn" onclick="autofetchLocation(true)" class="absolute right-2 top-2 px-3 py-1.5 bg-blue-100 hover:bg-blue-200 text-blue-700 text-xs font-bold rounded-lg transition flex items-center" title="Autofetch Geolocation via GPS API">
                    <i class="fas fa-location-arrow mr-1"></i> Auto
                </button>
            </div>

            <button type="submit" class="px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm rounded-xl transition shadow-sm">
                Filter Salons
            </button>
        </form>
    </div>

    <!-- Salons Directory -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
        @forelse($salons as $salon)
        @php
            $branches = $salon->branches;
            $hasMultipleBranches = $branches->count() > 1;
            $defaultBranch = $branches->first();
            $tz = config('app.timezone', 'Asia/Kolkata');
            $now = \Carbon\Carbon::now($tz);
            $todayOfWeek = $now->dayOfWeek; // 0=Sunday
            $tomorrowOfWeek = ($todayOfWeek + 1) % 7;
            $currentTime = $now->format('H:i:s');
            $isOwnerOffline = in_array($salon->status, ['EMERGENCY_CLOSED', 'OFFLINE', 'SUSPENDED_FOR_DELETION']);

            // Precompute branch data for JavaScript interactivity
            $branchesJsonData = $branches->map(function($b) use ($todayOfWeek, $tomorrowOfWeek, $currentTime, $isOwnerOffline) {
                $bwhToday = $b->workingHours->where('day_of_week', $todayOfWeek)->first();
                $bwhTomorrow = $b->workingHours->where('day_of_week', $tomorrowOfWeek)->first();
                
                $isOpen = false;
                $statusBadge = '🔴 CLOSED TODAY';
                $statusBg = 'bg-red-50 text-red-700 border-red-200';

                if (!$b->is_active) {
                    $isOpen = false;
                    $statusBadge = "🟠 BRANCH DISABLED • Paused by Owner";
                    $statusBg = 'bg-amber-50 text-amber-900 border-amber-300';
                } elseif ($bwhToday && $bwhToday->is_open) {
                    $openTime = strlen($bwhToday->open_time) === 5 ? $bwhToday->open_time . ':00' : $bwhToday->open_time;
                    $closeTime = strlen($bwhToday->close_time) === 5 ? $bwhToday->close_time . ':00' : $bwhToday->close_time;
                    
                    $inShift1 = ($currentTime >= $openTime && $currentTime <= $closeTime);
                    $inShift2 = false;
                    if ($bwhToday->has_split_shift && $bwhToday->split_open_time && $bwhToday->split_close_time) {
                        $sOpen = strlen($bwhToday->split_open_time) === 5 ? $bwhToday->split_open_time . ':00' : $bwhToday->split_open_time;
                        $sClose = strlen($bwhToday->split_close_time) === 5 ? $bwhToday->split_close_time . ':00' : $bwhToday->split_close_time;
                        $inShift2 = ($currentTime >= $sOpen && $currentTime <= $sClose);
                    }

                    if ($inShift1 || $inShift2) {
                        if ($isOwnerOffline) {
                            $isOpen = false;
                            $statusBadge = "🟠 TEMPORARILY OFFLINE";
                            $statusBg = 'bg-amber-50 text-amber-900 border-amber-300';
                        } else {
                            $isOpen = true;
                            $closingFormatted = $inShift1 ? \Carbon\Carbon::parse($closeTime)->format('h:i A') : \Carbon\Carbon::parse($bwhToday->split_close_time)->format('h:i A');
                            $statusBadge = "🟢 OPEN NOW • Closes {$closingFormatted}";
                            $statusBg = 'bg-emerald-50 text-emerald-800 border-emerald-200';
                        }
                    } else {
                        if ($currentTime < $openTime) {
                            $statusBadge = "🔴 CLOSED NOW • Opens at " . \Carbon\Carbon::parse($openTime)->format('h:i A');
                        } elseif ($bwhToday->has_split_shift && $currentTime > $closeTime && $currentTime < $bwhToday->split_open_time) {
                            $statusBadge = "🔴 BREAK • Reopens at " . \Carbon\Carbon::parse($bwhToday->split_open_time)->format('h:i A');
                        } else {
                            $tomorrowOpen = ($bwhTomorrow && $bwhTomorrow->is_open) ? \Carbon\Carbon::parse($bwhTomorrow->open_time)->format('h:i A') : '10:00 AM';
                            $statusBadge = "🔴 CLOSED NOW • Opens tomorrow {$tomorrowOpen}";
                        }
                    }
                }

                return [
                    'id' => $b->id,
                    'name' => $b->name,
                    'city' => $b->city,
                    'address' => $b->address,
                    'pin_code' => $b->pin_code,
                    'phone' => $b->phone,
                    'is_open' => $isOpen,
                    'status_badge' => $statusBadge,
                    'status_bg' => $statusBg,
                    'staff' => $b->staff->map(fn($s) => ['id' => $s->id, 'name' => $s->name, 'role' => $s->role]),
                    'combos' => $b->combos->where('is_active', true)->values(),
                ];
            });
        @endphp

        <div class="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 hover:border-blue-300 transition flex flex-col justify-between" id="salon-card-{{ $salon->id }}" data-branches="{{ htmlspecialchars(json_encode($branchesJsonData), ENT_QUOTES) }}">
            <div>
                <!-- Salon Header -->
                <div class="flex items-start justify-between mb-3">
                    <div class="flex items-center space-x-4">
                        <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white flex items-center justify-center font-bold text-2xl shadow-md">
                            <i class="fas fa-store"></i>
                        </div>
                        <div>
                            <h3 class="text-xl font-black text-gray-900">{{ $salon->business_name }}</h3>
                            <p class="text-xs text-gray-500 font-medium mt-0.5">
                                {{ $salon->business_type }} • 
                                <span class="font-bold text-gray-700">
                                    <i class="fas fa-code-branch text-blue-500 mr-1"></i> {{ $branches->count() }} {{ Str::plural('Branch', $branches->count()) }}
                                </span>
                            </p>
                        </div>
                    </div>
                    <span class="px-3 py-1 text-xs font-bold rounded-full {{ $salon->booking_policy === 'ADDED_CUSTOMERS_ONLY' ? 'bg-amber-100 text-amber-800' : 'bg-emerald-100 text-emerald-800' }}">
                        {{ $salon->booking_policy === 'PAY_AT_SALON' ? 'Pay at Salon' : ($salon->booking_policy === 'PREPAYMENT_REQUIRED_ALL' ? 'Prepayment Required' : ($salon->booking_policy === 'ADDED_CUSTOMERS_ONLY' ? 'Members Only' : 'Prepayment for New Users')) }}
                    </span>
                </div>

                <!-- 🏢 MULTI-BRANCH SELECTOR CHIPS (If > 1 Branch) -->
                @if($hasMultipleBranches)
                    <div class="mt-3 p-3 bg-slate-50 rounded-2xl border border-slate-100">
                        <p class="text-[11px] font-black uppercase tracking-wider text-slate-500 mb-2 flex items-center">
                            <i class="fas fa-map-marked-alt text-blue-600 mr-1.5"></i> Select Operating Branch:
                        </p>
                        <div class="flex flex-wrap gap-2">
                            @foreach($branches as $index => $b)
                                <button type="button" 
                                    onclick="selectCardBranch({{ $salon->id }}, {{ $b->id }})" 
                                    id="branch-tab-{{ $salon->id }}-{{ $b->id }}" 
                                    class="branch-chip-{{ $salon->id }} px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center space-x-1.5 {{ $index === 0 ? 'bg-blue-600 text-white shadow-sm ring-2 ring-blue-300' : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-100' }}">
                                    <i class="fas fa-store text-[10px]"></i>
                                    <span>{{ $b->name }}</span>
                                    <span class="text-[10px] opacity-80">({{ $b->pin_code }})</span>
                                </button>
                            @endforeach
                        </div>
                    </div>
                @endif

                <!-- Active Branch Location & Operating Hours Banner -->
                <div class="mt-3">
                    <div class="flex items-center justify-between text-xs text-gray-600">
                        <p class="font-semibold text-gray-700 flex items-center" id="card-address-{{ $salon->id }}">
                            <i class="fas fa-map-marker-alt text-red-500 mr-1.5"></i> 
                            {{ $defaultBranch->name ?? 'Main Branch' }} • {{ $defaultBranch->address ?? '' }}, {{ $defaultBranch->city ?? 'New Delhi' }}
                        </p>
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-700 border border-blue-100" id="card-pincode-{{ $salon->id }}">
                            PIN: {{ $defaultBranch->pin_code ?? '110001' }}
                        </span>
                    </div>

                    <div class="flex flex-wrap items-center gap-1.5 mt-2">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border {{ $branchesJsonData[0]['status_bg'] ?? 'bg-gray-50 text-gray-700' }}" id="card-badge-{{ $salon->id }}">
                            {{ $branchesJsonData[0]['status_badge'] ?? '🔴 CLOSED TODAY' }}
                        </span>
                    </div>
                </div>

                <!-- Available Services & Combos -->
                <div class="border-t border-gray-100 pt-4 mt-4">
                    <h4 class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">Popular Services & Combos</h4>
                    
                    <div class="space-y-2" id="card-services-list-{{ $salon->id }}">
                        @php
                            $initialBranchCombos = $defaultBranch ? $defaultBranch->combos->where('is_active', true)->take(2) : collect();
                            $staffList = $defaultBranch ? $defaultBranch->staff->map(fn($s) => ['id' => $s->id, 'name' => $s->name, 'role' => $s->role])->toJson() : '[]';
                        @endphp
                        
                        @foreach($initialBranchCombos as $combo)
                        <div class="flex items-center justify-between p-3 bg-purple-50 rounded-2xl border border-purple-100 hover:bg-purple-100/50 transition">
                            <div>
                                <p class="text-sm font-bold text-gray-900">{{ $combo->name }} <span class="text-[10px] bg-purple-200 text-purple-700 px-1.5 py-0.5 rounded ml-1 uppercase">Combo</span></p>
                                <p class="text-xs text-gray-500"><i class="far fa-clock mr-1"></i> {{ $combo->duration_minutes }} Mins</p>
                            </div>
                            <div class="text-right">
                                <span class="text-base font-black text-gray-900 block">₹{{ number_format($combo->price, 2) }}</span>
                                <button type="button" 
                                    onclick="openBookingModal({{ $salon->id }}, '{{ addslashes($salon->business_name) }}', {{ $defaultBranch->id ?? 0 }}, '', {{ $combo->id }}, '{{ addslashes($combo->name) }} (Combo)', {{ $combo->price }}, '{{ $salon->booking_policy }}')" 
                                    class="text-[10px] bg-purple-600 hover:bg-purple-700 text-white font-bold px-3 py-1.5 rounded-xl inline-block cursor-pointer shadow-sm transition">
                                    Book Combo &rarr;
                                </button>
                            </div>
                        </div>
                        @endforeach

                        @foreach($services->take(3 - $initialBranchCombos->count()) as $service)
                        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-2xl border border-gray-100 hover:bg-white transition">
                            <div>
                                <p class="text-sm font-bold text-gray-900">{{ $service->name }}</p>
                                <p class="text-xs text-gray-500"><i class="far fa-clock mr-1"></i> {{ $service->duration_minutes }} Mins • {{ $service->category }}</p>
                            </div>
                            <div class="text-right">
                                <span class="text-base font-black text-gray-900 block">₹{{ number_format($service->price, 2) }}</span>
                                <button type="button" 
                                    onclick="openBookingModal({{ $salon->id }}, '{{ addslashes($salon->business_name) }}', {{ $defaultBranch->id ?? 0 }}, {{ $service->id }}, '', '{{ addslashes($service->name) }}', {{ $service->price }}, '{{ $salon->booking_policy }}')" 
                                    class="text-[10px] bg-blue-600 hover:bg-blue-700 text-white font-bold px-3 py-1.5 rounded-xl inline-block cursor-pointer shadow-sm transition">
                                    Book Service &rarr;
                                </button>
                            </div>
                        </div>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>
        @empty
        <div class="col-span-2 text-center py-16 text-gray-400 bg-white rounded-3xl border border-gray-100">
            <i class="fas fa-map-marker-slash text-4xl mb-3 text-gray-300"></i>
            <p class="font-bold text-gray-700">No salons found matching PIN Code '{{ $pincode }}'.</p>
            <p class="text-xs text-gray-500 mt-1">Try clearing the PIN code filter or using the Auto GPS button.</p>
        </div>
        @endforelse
    </div>

    <!-- 💳 REAL BOOKING CHECKOUT MODAL WITH BRANCH SELECTOR -->
    <div id="booking-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm flex items-center justify-center hidden z-50 p-4">
        <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div class="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
                <div>
                    <h3 class="text-lg font-black text-gray-900" id="modal-salon-name">Salon Name</h3>
                    <p class="text-xs text-gray-500 font-semibold" id="modal-service-name">Service Name</p>
                </div>
                <button type="button" onclick="closeBookingModal()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times text-lg"></i>
                </button>
            </div>

            <form action="{{ route('customer.book.store') }}" method="POST">
                @csrf
                <input type="hidden" name="tenant_id" id="modal-tenant-id">
                <input type="hidden" name="service_id" id="modal-service-id">
                <input type="hidden" name="combo_id" id="modal-combo-id">

                <!-- Branch Selector in Modal -->
                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">
                        <i class="fas fa-store text-blue-600 mr-1"></i> Selected Branch
                    </label>
                    <select name="branch_id" id="modal-branch-select" onchange="onModalBranchChanged()" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Booking Date</label>
                    <input type="date" name="booking_date" id="modal-booking-date" value="{{ date('Y-m-d') }}" onchange="fetchDynamicSlots()" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Preferred Stylist / Staff</label>
                    <select name="staff_id" id="modal-staff-select" onchange="fetchDynamicSlots()" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="any">Any Available Stylist</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">
                        Dynamic Calculated Slot <span class="text-[10px] text-blue-600 lowercase font-normal">(Duration + Buffer fitted)</span>
                    </label>
                    <select name="start_time" id="modal-start-time" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="">Calculating available slots...</option>
                    </select>
                    <p id="modal-slot-info" class="text-[10px] text-gray-500 mt-1 font-semibold"></p>
                </div>

                <div class="p-4 bg-blue-50/70 rounded-2xl border border-blue-100 mb-6 text-xs text-blue-900">
                    <div class="flex justify-between font-bold mb-1">
                        <span>Total Payable Amount:</span>
                        <span class="text-sm font-black text-gray-900" id="modal-price">₹0.00</span>
                    </div>
                    <div class="text-[11px] text-gray-600" id="modal-policy-notice">
                        Pay at salon after service completion.
                    </div>
                </div>

                <button type="submit" id="modal-submit-btn" class="w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-2xl transition shadow-md">
                    Confirm Real Booking Slot &rarr;
                </button>
            </form>
        </div>
    </div>

    <script>
        // Store current active branch ID per salon card
        const salonActiveBranches = {};

        function selectCardBranch(tenantId, branchId) {
            salonActiveBranches[tenantId] = branchId;
            const card = document.getElementById(`salon-card-${tenantId}`);
            if (!card) return;

            const branches = JSON.parse(card.getAttribute('data-branches') || '[]');
            const branch = branches.find(b => b.id === branchId);
            if (!branch) return;

            // Highlight selected chip
            document.querySelectorAll(`.branch-chip-${tenantId}`).forEach(chip => {
                chip.className = `branch-chip-${tenantId} px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center space-x-1.5 bg-white text-gray-700 border border-gray-200 hover:bg-gray-100`;
            });
            const activeChip = document.getElementById(`branch-tab-${tenantId}-${branchId}`);
            if (activeChip) {
                activeChip.className = `branch-chip-${tenantId} px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center space-x-1.5 bg-blue-600 text-white shadow-sm ring-2 ring-blue-300`;
            }

            // Update Card Info
            const addrEl = document.getElementById(`card-address-${tenantId}`);
            if (addrEl) {
                addrEl.innerHTML = `<i class="fas fa-map-marker-alt text-red-500 mr-1.5"></i> ${branch.name} • ${branch.address ? branch.address + ', ' : ''}${branch.city}`;
            }

            const pinEl = document.getElementById(`card-pincode-${tenantId}`);
            if (pinEl) {
                pinEl.innerText = `PIN: ${branch.pin_code}`;
            }

            const badgeEl = document.getElementById(`card-badge-${tenantId}`);
            if (badgeEl) {
                badgeEl.className = `inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${branch.status_bg}`;
                badgeEl.innerText = branch.status_badge;
            }
        }

        function openBookingModal(tenantId, salonName, branchId, serviceId, comboId, serviceName, price, policy) {
            document.getElementById('modal-tenant-id').value = tenantId;
            document.getElementById('modal-service-id').value = serviceId || '';
            document.getElementById('modal-combo-id').value = comboId || '';
            document.getElementById('modal-salon-name').innerText = salonName;
            document.getElementById('modal-service-name').innerText = serviceName;
            document.getElementById('modal-price').innerText = `₹${parseFloat(price).toFixed(2)}`;

            // Populate Modal Branch Selector
            const card = document.getElementById(`salon-card-${tenantId}`);
            const branches = card ? JSON.parse(card.getAttribute('data-branches') || '[]') : [];
            const branchSelect = document.getElementById('modal-branch-select');
            branchSelect.innerHTML = '';

            const currentActiveBranchId = salonActiveBranches[tenantId] || branchId || (branches[0] ? branches[0].id : null);

            branches.forEach(b => {
                const opt = document.createElement('option');
                opt.value = b.id;
                opt.innerText = `📍 ${b.name} (${b.city} • PIN: ${b.pin_code})`;
                if (b.id === currentActiveBranchId) opt.selected = true;
                branchSelect.appendChild(opt);
            });

            // Update Staff List for active branch
            updateModalStaffList(tenantId, currentActiveBranchId);

            // Set Policy Notice
            let notice = "Pay at salon after service completion.";
            if (policy === 'PREPAYMENT_REQUIRED_ALL') {
                notice = "Online Prepayment Required by Salon Policy.";
            } else if (policy === 'PREPAYMENT_REQUIRED_NEW') {
                notice = "Prepayment Required for New Customers (Pay at Salon for Added Members).";
            } else if (policy === 'ADDED_CUSTOMERS_ONLY') {
                notice = "⚠️ Members Only: Only pre-approved CRM customers can book this salon.";
            }
            document.getElementById('modal-policy-notice').innerText = notice;

            document.getElementById('booking-modal').classList.remove('hidden');

            // Trigger dynamic slot calculation
            fetchDynamicSlots();
        }

        function onModalBranchChanged() {
            const tenantId = document.getElementById('modal-tenant-id').value;
            const branchId = parseInt(document.getElementById('modal-branch-select').value);
            updateModalStaffList(tenantId, branchId);
            fetchDynamicSlots();
        }

        function updateModalStaffList(tenantId, branchId) {
            const card = document.getElementById(`salon-card-${tenantId}`);
            const branches = card ? JSON.parse(card.getAttribute('data-branches') || '[]') : [];
            const branch = branches.find(b => b.id === branchId);
            const staffSelect = document.getElementById('modal-staff-select');
            staffSelect.innerHTML = '<option value="any">Any Available Stylist</option>';

            if (branch && branch.staff) {
                branch.staff.forEach(s => {
                    const opt = document.createElement('option');
                    opt.value = s.id;
                    opt.innerText = `${s.name} (${s.role})`;
                    staffSelect.appendChild(opt);
                });
            }
        }

        function fetchDynamicSlots() {
            let tenantId = document.getElementById('modal-tenant-id').value;
            let branchId = document.getElementById('modal-branch-select').value;
            let serviceId = document.getElementById('modal-service-id').value;
            let comboId = document.getElementById('modal-combo-id').value;
            let staffId = document.getElementById('modal-staff-select').value;
            let date = document.getElementById('modal-booking-date').value;

            let timeSelect = document.getElementById('modal-start-time');
            let infoP = document.getElementById('modal-slot-info');
            let submitBtn = document.getElementById('modal-submit-btn');

            timeSelect.innerHTML = '<option value="">Calculating real-time slots...</option>';

            let url = `/customer/api/slots?tenant_id=${tenantId}&branch_id=${branchId}&service_id=${serviceId}&combo_id=${comboId}&staff_id=${staffId}&date=${date}`;

            fetch(url)
                .then(res => res.json())
                .then(data => {
                    timeSelect.innerHTML = '';
                    if (data.is_closed) {
                        timeSelect.innerHTML = '<option value="">Branch is CLOSED on this date</option>';
                        infoP.innerText = `🔴 ${data.message} Booking is disabled for this date.`;
                        infoP.className = "text-xs text-red-600 font-bold mt-1.5 p-2 bg-red-50 rounded-xl border border-red-200";
                        submitBtn.disabled = true;
                        submitBtn.className = "w-full py-3.5 bg-gray-300 text-gray-500 text-xs font-bold rounded-2xl cursor-not-allowed shadow-none";
                        submitBtn.innerText = "❌ Booking Disabled (Branch Closed)";
                    } else if (data.slots && data.slots.length > 0) {
                        infoP.innerText = `⏱️ Duration: ${data.duration_minutes}m + ${data.buffer_minutes}m buffer (${data.required_minutes}m total window).`;
                        infoP.className = "text-[10px] text-gray-500 mt-1 font-semibold";
                        submitBtn.disabled = false;
                        submitBtn.className = "w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-2xl transition shadow-md cursor-pointer";
                        submitBtn.innerText = "Confirm Real Booking Slot →";

                        data.slots.forEach(slot => {
                            let opt = document.createElement('option');
                            opt.value = slot.time_value;
                            opt.innerText = `${slot.display_text} (Gap: ${slot.available_gap_minutes}m available)`;
                            timeSelect.appendChild(opt);
                        });
                    } else {
                        timeSelect.innerHTML = '<option value="">No free slots on this date</option>';
                        infoP.innerText = '⚠️ All operating slots are fully booked or conflict with existing appointments on this date.';
                        infoP.className = "text-[10px] text-amber-600 font-semibold mt-1";
                        submitBtn.disabled = true;
                        submitBtn.className = "w-full py-3.5 bg-gray-300 text-gray-500 text-xs font-bold rounded-2xl cursor-not-allowed shadow-none";
                        submitBtn.innerText = "❌ No Slots Available";
                    }
                })
                .catch(err => {
                    console.log('Error fetching slots:', err);
                    timeSelect.innerHTML = '<option value="10:00:00">10:00 AM</option><option value="11:00:00">11:00 AM</option>';
                });
        }

        function closeBookingModal() {
            document.getElementById('booking-modal').classList.add('hidden');
        }

        // --- 📍 REAL GPS LOCATION AUTO-FETCH & PROXIMITY SORT ---
        function autofetchLocation(manualClick = false) {
            const btn = document.getElementById('auto-gps-btn');
            if (btn) btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Locating...';

            if (!navigator.geolocation) {
                if (btn) btn.innerHTML = '<i class="fas fa-location-arrow mr-1"></i> Auto';
                if (manualClick) alert('Geolocation is not supported by your browser.');
                return;
            }

            navigator.geolocation.getCurrentPosition(
                function(pos) {
                    const lat = pos.coords.latitude;
                    const lng = pos.coords.longitude;

                    // Call the Registration / Location Controller detection API
                    fetch(`/location/detect?lat=${lat}&lng=${lng}`)
                        .then(r => r.json())
                        .then(res => {
                            if (btn) btn.innerHTML = '<i class="fas fa-location-arrow mr-1"></i> Auto';
                            if (res.success && res.data) {
                                const detectedPin = res.data.zipcode || '110001';
                                const detectedCity = res.data.city || 'Nearby Area';

                                document.getElementById('explore_pincode').value = detectedPin;

                                // Show Toast Banner
                                const banner = document.getElementById('location-banner');
                                document.getElementById('location-title').innerText = `📍 GPS Location: ${detectedCity} (${detectedPin})`;
                                document.getElementById('location-subtitle').innerText = `Filtering salons near ${detectedCity} first!`;
                                banner.classList.remove('hidden');

                                // Automatically submit filter if PIN changed or manually clicked
                                if (manualClick || !new URLSearchParams(window.location.search).get('pincode')) {
                                    document.getElementById('explore-filter-form').submit();
                                }
                            }
                        })
                        .catch(err => {
                            if (btn) btn.innerHTML = '<i class="fas fa-location-arrow mr-1"></i> Auto';
                            console.error('Location API error:', err);
                        });
                },
                function(err) {
                    if (btn) btn.innerHTML = '<i class="fas fa-location-arrow mr-1"></i> Auto';
                    console.warn('Geolocation permission error:', err);
                    if (manualClick) {
                        alert('Location permission was denied. Please enter your PIN code manually.');
                    }
                },
                { timeout: 8000, enableHighAccuracy: true }
            );
        }

        function dismissLocationBanner() {
            document.getElementById('location-banner').classList.add('hidden');
        }

        // On initial page load: auto-prompt GPS if user hasn't filtered by PIN yet
        document.addEventListener('DOMContentLoaded', function() {
            const urlParams = new URLSearchParams(window.location.search);
            if (!urlParams.get('pincode') && !sessionStorage.getItem('gps_auto_checked')) {
                sessionStorage.setItem('gps_auto_checked', 'true');
                autofetchLocation(false);
            }
        });
    </script>
@endsection
