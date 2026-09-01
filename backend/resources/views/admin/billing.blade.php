@extends('layouts.admin')

@section('title', 'Billing & Invoices')

@section('content')

    @if(session('success'))
        <div class="mb-6 bg-emerald-50 text-emerald-800 p-4 rounded-xl border border-emerald-200 font-semibold flex items-center space-x-2">
            <i class="fas fa-check-circle text-emerald-600 text-lg"></i>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    @if(session('error'))
        <div class="mb-6 bg-rose-50 text-rose-800 p-4 rounded-xl border border-rose-200 font-semibold flex items-center space-x-2">
            <i class="fas fa-exclamation-circle text-rose-600 text-lg"></i>
            <span>{{ session('error') }}</span>
        </div>
    @endif

    <!-- Global SaaS Billing Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Total SaaS Revenue Collected</p>
                <h3 id="stat-total-collected" class="text-3xl font-black text-emerald-600">₹{{ number_format($totalSaasCollected, 2) }}</h3>
            </div>
            <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-2xl font-bold shadow-sm">
                <i class="fas fa-hand-holding-usd"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Outstanding Tenant Balance</p>
                <h3 id="stat-outstanding" class="text-3xl font-black text-amber-600">₹{{ number_format($totalOutstandingFees, 2) }}</h3>
            </div>
            <div class="w-14 h-14 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center text-2xl font-bold shadow-sm">
                <i class="fas fa-exclamation-circle"></i>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Commission Rate</p>
                <h3 class="text-3xl font-black text-blue-600">₹{{ $bookingFee }} <span class="text-xs font-normal text-gray-500">/ booking</span></h3>
            </div>
            <div class="w-14 h-14 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center text-2xl font-bold shadow-sm">
                <i class="fas fa-calculator"></i>
            </div>
        </div>
    </div>

    <!-- Master Controls & Add Dues Generator -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- SaaS Master Engine Toggle -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h3 class="text-lg font-bold text-gray-900 mb-1 flex items-center space-x-2">
                <i class="fas fa-sliders-h text-blue-600"></i>
                <span>SaaS Master Engine Configuration</span>
            </h3>
            <p class="text-xs text-gray-500 mb-5">Enable or pause the global ₹1 per booking SaaS commission engine across all shop partners.</p>
            
            <form id="toggle-form" action="{{ route('admin.billing.toggle') }}" method="POST">
                @csrf
                <div class="flex items-center justify-between bg-gray-50 p-4 rounded-xl border border-gray-100">
                    <div>
                        <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block mb-1">Billing Engine Status</span>
                        <span id="toggle-badge" class="px-3 py-1 rounded-full text-xs font-extrabold {{ $billingEnabled === 'true' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800' }}">
                            {{ $billingEnabled === 'true' ? 'ONLINE (ACTIVE)' : 'OFFLINE (DISABLED)' }}
                        </span>
                    </div>
                    <input type="hidden" id="toggle-hidden-val" name="enabled" value="{{ $billingEnabled === 'true' ? 'false' : 'true' }}">
                    <button type="submit" id="toggle-btn" class="px-5 py-2.5 {{ $billingEnabled === 'true' ? 'bg-rose-600 hover:bg-rose-700' : 'bg-blue-600 hover:bg-blue-700' }} text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-2">
                        <i id="toggle-btn-icon" class="fas {{ $billingEnabled === 'true' ? 'fa-pause' : 'fa-play' }}"></i>
                        <span id="toggle-btn-text">{{ $billingEnabled === 'true' ? 'Pause Master Billing' : 'Enable Master Billing' }}</span>
                    </button>
                </div>
            </form>
        </div>

        <!-- ➕ Add Manual Dues Form for Testing & Custom Invoicing -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h3 class="text-lg font-bold text-gray-900 mb-1 flex items-center space-x-2">
                <i class="fas fa-plus-circle text-emerald-600"></i>
                <span>Add Manual Commission Dues to Shop Tenant</span>
            </h3>
            <p class="text-xs text-gray-500 mb-5">Select a shop partner and add custom pending dues to test Razorpay payment checkout & invoice generation.</p>

            <form id="add-dues-form" action="{{ route('admin.billing.add-dues') }}" method="POST" class="space-y-4">
                @csrf
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-gray-700 mb-1">Target Shop Partner</label>
                        <select id="tenant-select" name="tenant_id" required class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 text-xs font-semibold text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none">
                            <option value="">-- Select Shop Tenant --</option>
                            @foreach($tenantsWithLedger as $t)
                                <option value="{{ $t->id }}">{{ $t->business_name }} (Current Due: ₹{{ number_format($t->due_amount, 2) }})</option>
                            @endforeach
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold text-gray-700 mb-1">Amount (₹)</label>
                        <input type="number" step="0.01" min="1" name="amount" value="10.00" required class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 text-xs font-semibold text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none" placeholder="e.g. 10.00">
                    </div>
                </div>

                <div class="flex items-center space-x-3">
                    <input type="text" name="description" placeholder="Description e.g. Manual Test Dues (+₹10.00)" class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 text-xs font-medium text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none">
                    <button type="submit" class="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition shadow-sm whitespace-nowrap flex items-center space-x-2">
                        <i class="fas fa-plus"></i>
                        <span>Add Dues Now</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Shop Partners Outstanding Dues Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
        <div class="px-6 py-4 border-b border-gray-100 bg-gray-50/50 flex justify-between items-center">
            <h3 class="text-sm font-bold text-gray-900">Shop Partners Outstanding Dues Breakdown</h3>
            <span id="shop-count" class="text-xs text-gray-500 font-semibold">{{ $tenantsWithLedger->count() }} Registered Shops</span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-3 font-semibold">Shop Name</th>
                        <th class="px-6 py-3 font-semibold">Business Type</th>
                        <th class="px-6 py-3 font-semibold">Total Bookings</th>
                        <th class="px-6 py-3 font-semibold">Current Pending Dues</th>
                        <th class="px-6 py-3 font-semibold text-right">Quick Action</th>
                    </tr>
                </thead>
                <tbody id="tenants-table-body" class="divide-y divide-gray-100 text-sm">
                    @foreach($tenantsWithLedger as $tenant)
                    <tr class="hover:bg-gray-50/50 transition-colors">
                        <td class="px-6 py-3.5 font-bold text-gray-900">{{ $tenant->business_name }}</td>
                        <td class="px-6 py-3.5 text-xs text-gray-500 font-medium">{{ $tenant->business_type }}</td>
                        <td class="px-6 py-3.5 font-semibold text-gray-700">{{ $tenant->total_bookings }}</td>
                        <td class="px-6 py-3.5">
                            <span class="font-black {{ $tenant->due_amount > 0 ? 'text-amber-600' : 'text-emerald-600' }}">
                                ₹{{ number_format($tenant->due_amount, 2) }}
                            </span>
                        </td>
                        <td class="px-6 py-3.5 text-right">
                            <form action="{{ route('admin.billing.add-dues') }}" method="POST" class="quick-dues-form inline-flex items-center space-x-2">
                                @csrf
                                <input type="hidden" name="tenant_id" value="{{ $tenant->id }}">
                                <input type="hidden" name="amount" value="10.00">
                                <button type="submit" class="px-3 py-1 bg-amber-50 hover:bg-amber-100 text-amber-800 text-xs font-bold rounded-lg border border-amber-200 transition">
                                    + ₹10 Dues
                                </button>
                            </form>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    <!-- Live Platform SaaS Transaction Ledger Statement -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 class="text-base font-bold text-gray-900">Platform SaaS Ledger Statement</h3>
            <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg border border-gray-200 font-semibold">
                Live Transaction Log (Past 6 Months)
            </span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">Date</th>
                        <th class="px-6 py-4 font-semibold">Salon Business</th>
                        <th class="px-6 py-4 font-semibold">Description</th>
                        <th class="px-6 py-4 font-semibold">Type</th>
                        <th class="px-6 py-4 font-semibold">Amount</th>
                        <th class="px-6 py-4 font-semibold text-right">Status</th>
                    </tr>
                </thead>
                <tbody id="invoices-table-body" class="divide-y divide-gray-100 text-sm">
                    @forelse($invoices as $invoice)
                    <tr class="hover:bg-gray-50/50 transition-colors">
                        <td class="px-6 py-4 text-xs text-gray-500 font-medium whitespace-nowrap">{{ $invoice->created_at->format('M d, Y • H:i') }}</td>
                        <td class="px-6 py-4 font-bold text-gray-900">{{ $invoice->tenant->business_name ?? 'Tenant Salon' }}</td>
                        <td class="px-6 py-4 text-gray-700 text-xs">{{ $invoice->description }}</td>
                        <td class="px-6 py-4">
                            @if($invoice->type === 'DEBIT')
                                <span class="px-2 py-0.5 rounded text-xs font-semibold bg-amber-100 text-amber-800">Commission Fee</span>
                            @else
                                <span class="px-2 py-0.5 rounded text-xs font-semibold bg-emerald-100 text-emerald-800">Payment Received</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 font-black text-gray-900">₹{{ number_format($invoice->amount, 2) }}</td>
                        <td class="px-6 py-4 text-right">
                            @if($invoice->status === 'SETTLED')
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Settled</span>
                            @else
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">Pending</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-receipt text-4xl mb-3 text-gray-300"></i>
                            <p>No billing ledger transactions recorded yet.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- ⚡ Silent Real-Time AJAX Script (5-Second Auto-Poll & No-Reload Form Submissions) -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '{{ csrf_token() }}';

            // 1. Silent Master Engine Toggle Submit
            const toggleForm = document.getElementById('toggle-form');
            if (toggleForm) {
                toggleForm.addEventListener('submit', function(e) {
                    e.preventDefault();
                    const formData = new FormData(toggleForm);
                    fetch(toggleForm.action, {
                        method: 'POST',
                        headers: {
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': csrfToken
                        },
                        body: formData
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (typeof showToast === 'function') {
                            showToast(data.message || 'Billing status updated!', data.success ? 'success' : 'error', data.raw_error);
                        }
                        if (data.success) {
                            fetchLiveData();
                        }
                    })
                    .catch(err => {
                        if (typeof showToast === 'function') {
                            showToast('Toggle request failed.', 'error', err.toString());
                        }
                    });
                });
            }

            // 2. Silent Add Manual Dues Form Submit
            const addDuesForm = document.getElementById('add-dues-form');
            if (addDuesForm) {
                addDuesForm.addEventListener('submit', function(e) {
                    e.preventDefault();
                    const formData = new FormData(addDuesForm);
                    fetch(addDuesForm.action, {
                        method: 'POST',
                        headers: {
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': csrfToken
                        },
                        body: formData
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (typeof showToast === 'function') {
                            showToast(data.message || 'Manual dues added!', data.success ? 'success' : 'error', data.raw_error);
                        }
                        if (data.success) {
                            fetchLiveData();
                            const descInput = addDuesForm.querySelector('input[name="description"]');
                            if (descInput) descInput.value = '';
                        }
                    })
                    .catch(err => {
                        if (typeof showToast === 'function') {
                            showToast('Failed to add manual dues.', 'error', err.toString());
                        }
                    });
                });
            }

            // 3. Delegate Quick +₹10 Dues Buttons
            document.addEventListener('submit', function(e) {
                if (e.target && e.target.classList.contains('quick-dues-form')) {
                    e.preventDefault();
                    const form = e.target;
                    const formData = new FormData(form);
                    fetch(form.action, {
                        method: 'POST',
                        headers: {
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': csrfToken
                        },
                        body: formData
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (typeof showToast === 'function') {
                            showToast(data.message || 'Dues added!', data.success ? 'success' : 'error', data.raw_error);
                        }
                        if (data.success) {
                            fetchLiveData();
                        }
                    })
                    .catch(err => {
                        if (typeof showToast === 'function') {
                            showToast('Quick dues request failed.', 'error', err.toString());
                        }
                    });
                }
            });

            // 4. Real-time 5-Second Background Polling Function
            function fetchLiveData() {
                fetch('{{ route("admin.billing.live-data") }}', {
                    headers: { 'Accept': 'application/json' }
                })
                .then(res => res.json())
                .then(data => {
                    if (!data.success) return;

                    // Update Top Stats
                    document.getElementById('stat-total-collected').textContent = '₹' + data.formatted_total_collected;
                    document.getElementById('stat-outstanding').textContent = '₹' + data.formatted_total_outstanding;

                    // Update Toggle Controls
                    const isEnabled = (data.billing_enabled === 'true' || data.billing_enabled === '1');
                    const badge = document.getElementById('toggle-badge');
                    const btn = document.getElementById('toggle-btn');
                    const btnText = document.getElementById('toggle-btn-text');
                    const btnIcon = document.getElementById('toggle-btn-icon');
                    const hiddenVal = document.getElementById('toggle-hidden-val');

                    if (isEnabled) {
                        badge.className = 'px-3 py-1 rounded-full text-xs font-extrabold bg-emerald-100 text-emerald-800';
                        badge.textContent = 'ONLINE (ACTIVE)';
                        btn.className = 'px-5 py-2.5 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-2';
                        btnIcon.className = 'fas fa-pause';
                        btnText.textContent = 'Pause Master Billing';
                        hiddenVal.value = 'false';
                    } else {
                        badge.className = 'px-3 py-1 rounded-full text-xs font-extrabold bg-rose-100 text-rose-800';
                        badge.textContent = 'OFFLINE (DISABLED)';
                        btn.className = 'px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-2';
                        btnIcon.className = 'fas fa-play';
                        btnText.textContent = 'Enable Master Billing';
                        hiddenVal.value = 'true';
                    }

                    // Update Tenants Breakdown Table
                    const tenantsTbody = document.getElementById('tenants-table-body');
                    const tenantSelect = document.getElementById('tenant-select');
                    let tenantRowsHtml = '';
                    let selectOptionsHtml = '<option value="">-- Select Shop Tenant --</option>';

                    data.tenants.forEach(t => {
                        const dueClass = t.due_amount > 0 ? 'text-amber-600' : 'text-emerald-600';
                        tenantRowsHtml += `
                            <tr class="hover:bg-gray-50/50 transition-colors">
                                <td class="px-6 py-3.5 font-bold text-gray-900">${t.business_name}</td>
                                <td class="px-6 py-3.5 text-xs text-gray-500 font-medium">${t.business_type}</td>
                                <td class="px-6 py-3.5 font-semibold text-gray-700">${t.total_bookings}</td>
                                <td class="px-6 py-3.5">
                                    <span class="font-black ${dueClass}">
                                        ₹${t.formatted_due}
                                    </span>
                                </td>
                                <td class="px-6 py-3.5 text-right">
                                    <form action="{{ route('admin.billing.add-dues') }}" method="POST" class="quick-dues-form inline-flex items-center space-x-2">
                                        <input type="hidden" name="_token" value="${csrfToken}">
                                        <input type="hidden" name="tenant_id" value="${t.id}">
                                        <input type="hidden" name="amount" value="10.00">
                                        <button type="submit" class="px-3 py-1 bg-amber-50 hover:bg-amber-100 text-amber-800 text-xs font-bold rounded-lg border border-amber-200 transition">
                                            + ₹10 Dues
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        `;

                        selectOptionsHtml += `<option value="${t.id}">${t.business_name} (Current Due: ₹${t.formatted_due})</option>`;
                    });

                    if (tenantsTbody) tenantsTbody.innerHTML = tenantRowsHtml;
                    if (tenantSelect && document.activeElement !== tenantSelect) {
                        const currentSel = tenantSelect.value;
                        tenantSelect.innerHTML = selectOptionsHtml;
                        tenantSelect.value = currentSel;
                    }

                    // Update Invoices Statement Log Table
                    const invoicesTbody = document.getElementById('invoices-table-body');
                    if (data.invoices.length === 0) {
                        invoicesTbody.innerHTML = `
                            <tr>
                                <td colspan="6" class="px-6 py-12 text-center text-gray-400">
                                    <i class="fas fa-receipt text-4xl mb-3 text-gray-300"></i>
                                    <p>No billing ledger transactions recorded yet.</p>
                                </td>
                            </tr>
                        `;
                    } else {
                        let invRowsHtml = '';
                        data.invoices.forEach(inv => {
                            const typeBadge = inv.type === 'DEBIT' 
                                ? '<span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Fee Debit</span>'
                                : '<span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Payment Credit</span>';
                            
                            const statusBadge = inv.status === 'SETTLED'
                                ? '<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Settled</span>'
                                : '<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">Pending</span>';

                            invRowsHtml += `
                                <tr class="hover:bg-gray-50/50 transition-colors">
                                    <td class="px-6 py-4 text-xs text-gray-500 font-medium whitespace-nowrap">${inv.date}</td>
                                    <td class="px-6 py-4 font-bold text-gray-900">${inv.tenant_name}</td>
                                    <td class="px-6 py-4 text-gray-700 text-xs">${inv.description}</td>
                                    <td class="px-6 py-4">${typeBadge}</td>
                                    <td class="px-6 py-4 font-black text-gray-900">₹${inv.formatted_amount}</td>
                                    <td class="px-6 py-4 text-right">${statusBadge}</td>
                                </tr>
                            `;
                        });
                        if (invoicesTbody) invoicesTbody.innerHTML = invRowsHtml;
                    }
                })
                .catch(err => console.error('Live data fetch error:', err));
            }

            // Start 5-Second Real-Time Automatic Polling
            setInterval(fetchLiveData, 5000);
        });
    </script>
@endsection
