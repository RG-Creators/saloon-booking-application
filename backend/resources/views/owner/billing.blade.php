@extends('layouts.owner')

@section('title', 'SaaS Billing & Platform Ledger')

@section('content')
    @if(session('success'))
        <div class="mb-6 bg-emerald-50 text-emerald-800 p-4 rounded-xl border border-emerald-200 font-semibold flex items-center space-x-2">
            <i class="fas fa-check-circle text-emerald-600 text-lg"></i>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    <div id="owner-banner-container">
        @if(!$billingEnabled)
            <div class="mb-8 bg-amber-50 border border-amber-200 rounded-2xl p-6 flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <div class="w-12 h-12 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center text-xl font-bold">
                        <i class="fas fa-pause-circle"></i>
                    </div>
                    <div>
                        <h3 class="text-base font-bold text-amber-900">SaaS Platform Billing is Currently Disabled</h3>
                        <p class="text-xs text-amber-700 mt-0.5">The Super Admin has currently turned off commission billing engine.</p>
                    </div>
                </div>
                <span class="px-3 py-1 bg-amber-200 text-amber-900 rounded-full text-xs font-bold uppercase tracking-wider">OFFLINE</span>
            </div>
        @endif
    </div>

    <!-- Summary Header Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        
        <!-- Outstanding Balance Card -->
        <div class="bg-gradient-to-br from-indigo-950 via-slate-900 to-indigo-900 rounded-2xl p-6 shadow-md text-white relative overflow-hidden flex flex-col justify-between">
            <div class="absolute -right-4 -bottom-4 opacity-10 text-white text-8xl font-black">
                <i class="fas fa-coins"></i>
            </div>
            <div>
                <span class="text-xs uppercase font-extrabold text-indigo-300 tracking-wider">Outstanding SaaS Commission</span>
                <h3 id="owner-outstanding-balance" class="text-4xl font-black text-white mt-1">₹{{ number_format($outstandingBalance, 2) }}</h3>
                <p class="text-xs text-slate-300 mt-1">Calculated at flat ₹1.00 per booking • Past 6 Months</p>
            </div>

            <div id="owner-settle-container" class="mt-6 pt-4 border-t border-indigo-800/60">
                <form id="settleForm" action="{{ route('owner.billing.settle') }}" method="POST">
                    @csrf
                    <input type="hidden" name="razorpay_payment_id" id="razorpay_payment_id" value="">
                    @if($outstandingBalance > 0 && $billingEnabled)
                        <button type="button" id="rzp-button1"
                            class="w-full py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-extrabold text-xs uppercase tracking-wider rounded-xl transition shadow-lg flex items-center justify-center space-x-2">
                            <i class="fas fa-bolt text-amber-300"></i>
                            <span>Settle ₹{{ number_format($outstandingBalance, 2) }} via Razorpay</span>
                        </button>
                    @else
                        <button type="button" disabled 
                            class="w-full py-3 bg-slate-800 text-slate-400 font-bold text-xs rounded-xl cursor-not-allowed flex items-center justify-center space-x-2">
                            <i class="fas fa-check-circle text-emerald-400"></i>
                            <span>{{ $outstandingBalance <= 0 ? 'Balance Fully Settled ✓' : 'SaaS Billing Paused' }}</span>
                        </button>
                    @endif
                </form>
            </div>
        </div>

        <!-- Total Completed Bookings -->
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Total Completed Bookings</p>
                <h3 id="owner-completed-bookings" class="text-3xl font-black text-gray-900">{{ $totalCompletedBookings }}</h3>
                <p class="text-xs text-emerald-600 font-bold mt-1"><i class="fas fa-check-circle mr-1"></i> Active Commission Billing</p>
            </div>
            <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-2xl font-bold">
                <i class="fas fa-calendar-check"></i>
            </div>
        </div>

        <!-- Billing Rate -->
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">SaaS Commission Rate</p>
                <h3 class="text-3xl font-black text-gray-900">₹1.00 <span class="text-xs font-normal text-gray-500">/ booking</span></h3>
                <p class="text-xs text-indigo-600 font-bold mt-1"><i class="fas fa-bolt mr-1"></i> Flat Transparent Fee</p>
            </div>
            <div class="w-14 h-14 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center text-2xl font-bold">
                <i class="fas fa-tag"></i>
            </div>
        </div>
    </div>

    <!-- Usage Ledger Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <div>
                <h3 class="text-lg font-bold text-gray-900">Itemized SaaS Ledger Statement</h3>
                <p class="text-xs text-gray-500 mt-0.5">Showing Past 6 Months Ledger Statements</p>
            </div>
            <span class="text-xs font-bold bg-indigo-50 text-indigo-700 px-3 py-1.5 rounded-lg border border-indigo-100">
                <i class="fas fa-receipt mr-1"></i> Past 6 Months
            </span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                        <th class="px-6 py-4 font-semibold">Date & Time</th>
                        <th class="px-6 py-4 font-semibold">Transaction Description</th>
                        <th class="px-6 py-4 font-semibold">Type</th>
                        <th class="px-6 py-4 font-semibold">Amount</th>
                        <th class="px-6 py-4 font-semibold text-right">Status / Invoice</th>
                    </tr>
                </thead>
                <tbody id="owner-ledgers-table-body" class="divide-y divide-gray-100 text-sm">
                    @forelse($ledgers as $ledger)
                    <tr class="hover:bg-gray-50/80 transition">
                        <td class="px-6 py-4 text-xs font-medium text-gray-500 whitespace-nowrap">
                            {{ $ledger->created_at->format('M d, Y • H:i A') }}
                        </td>
                        <td class="px-6 py-4 font-medium text-gray-900">
                            {{ $ledger->description }}
                            @if($ledger->booking_id)
                                <span class="text-xs text-indigo-600 font-bold block">Linked Booking #{{ $ledger->booking_id }}</span>
                            @endif
                        </td>
                        <td class="px-6 py-4">
                            @if($ledger->type === 'DEBIT')
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Fee Debit</span>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Payment Credit</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 font-black {{ $ledger->type === 'DEBIT' ? 'text-gray-900' : 'text-emerald-600' }}">
                            {{ $ledger->type === 'DEBIT' ? '₹' . number_format($ledger->amount, 2) : '- ₹' . number_format($ledger->amount, 2) }}
                        </td>
                        <td class="px-6 py-4 text-right">
                            @if($ledger->status === 'SETTLED')
                                <div class="inline-flex items-center space-x-2">
                                    <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Settled ✓</span>
                                    <a href="/api/v1/business/ledger/{{ $ledger->id }}/invoice" target="_blank" class="px-2.5 py-1 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold rounded-lg border border-indigo-200 transition">
                                        <i class="fas fa-file-download mr-1"></i> Invoice
                                    </a>
                                </div>
                            @else
                                <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Unpaid</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center text-gray-400">
                            <i class="fas fa-file-invoice text-4xl mb-3 text-gray-300"></i>
                            <p>No billing ledger entries in past 6 months.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($ledgers->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $ledgers->links() }}
        </div>
        @endif
    </div>

    <!-- Razorpay JS Checkout Integration -->
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '{{ csrf_token() }}';

            function initRazorpayButton(key, amountInPaise, formattedBalance, isEnabled) {
                const btn = document.getElementById('rzp-button1');
                if (!btn) return;
                btn.onclick = function(e) {
                    e.preventDefault();
                    var options = {
                        "key": key,
                        "amount": amountInPaise,
                        "currency": "INR",
                        "name": "{{ $tenant->business_name }}",
                        "description": "Bookify ₹1 SaaS Commission Ledger Settlement",
                        "handler": function (response){
                            document.getElementById('razorpay_payment_id').value = response.razorpay_payment_id;
                            submitSilentSettlement();
                        },
                        "theme": { "color": "#4F46E5" }
                    };
                    var rzp = new Razorpay(options);
                    rzp.open();
                };
            }

            function submitSilentSettlement() {
                const form = document.getElementById('settleForm');
                if (!form) return;
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
                        showToast(data.message || 'Settlement processed successfully!', data.success ? 'success' : 'error', data.raw_error);
                    }
                    if (data.success) {
                        fetchOwnerLiveData();
                    }
                })
                .catch(err => {
                    if (typeof showToast === 'function') {
                        showToast('Settlement request failed.', 'error', err.toString());
                    }
                });
            }

            const rzpBtn = document.getElementById('rzp-button1');
            if (rzpBtn) {
                initRazorpayButton("{{ $razorpayKey }}", "{{ (int)($outstandingBalance * 100) }}", "{{ number_format($outstandingBalance, 2) }}", {{ $billingEnabled ? 'true' : 'false' }});
            }

            // Real-time 5-Second Background Polling Function for Shop Owner Portal
            function fetchOwnerLiveData() {
                fetch('{{ route("owner.billing.live-data") }}', {
                    headers: { 'Accept': 'application/json' }
                })
                .then(res => res.json())
                .then(data => {
                    if (!data.success) return;

                    // 1. Update Outstanding Balance Text
                    const balEl = document.getElementById('owner-outstanding-balance');
                    if (balEl) balEl.textContent = '₹' + data.formatted_balance;

                    // 2. Update Completed Bookings Text
                    const compEl = document.getElementById('owner-completed-bookings');
                    if (compEl) compEl.textContent = data.total_completed_bookings;

                    // 3. Update Disabled Banner Container
                    const bannerEl = document.getElementById('owner-banner-container');
                    if (bannerEl) {
                        if (!data.billing_enabled) {
                            bannerEl.innerHTML = `
                                <div class="mb-8 bg-amber-50 border border-amber-200 rounded-2xl p-6 flex items-center justify-between">
                                    <div class="flex items-center space-x-4">
                                        <div class="w-12 h-12 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center text-xl font-bold">
                                            <i class="fas fa-pause-circle"></i>
                                        </div>
                                        <div>
                                            <h3 class="text-base font-bold text-amber-900">SaaS Platform Billing is Currently Disabled</h3>
                                            <p class="text-xs text-amber-700 mt-0.5">The Super Admin has currently turned off commission billing engine.</p>
                                        </div>
                                    </div>
                                    <span class="px-3 py-1 bg-amber-200 text-amber-900 rounded-full text-xs font-bold uppercase tracking-wider">OFFLINE</span>
                                </div>
                            `;
                        } else {
                            bannerEl.innerHTML = '';
                        }
                    }

                    // 4. Update Settlement Button
                    const settleContainer = document.getElementById('owner-settle-container');
                    if (settleContainer) {
                        if (data.outstanding_balance > 0 && data.billing_enabled) {
                            const amountInPaise = Math.round(data.outstanding_balance * 100);
                            settleContainer.innerHTML = `
                                <form id="settleForm" action="{{ route('owner.billing.settle') }}" method="POST">
                                    <input type="hidden" name="_token" value="${csrfToken}">
                                    <input type="hidden" name="razorpay_payment_id" id="razorpay_payment_id" value="">
                                    <button type="button" id="rzp-button1"
                                        class="w-full py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-extrabold text-xs uppercase tracking-wider rounded-xl transition shadow-lg flex items-center justify-center space-x-2">
                                        <i class="fas fa-bolt text-amber-300"></i>
                                        <span>Settle ₹${data.formatted_balance} via Razorpay</span>
                                    </button>
                                </form>
                            `;
                            initRazorpayButton("{{ $razorpayKey }}", amountInPaise, data.formatted_balance, true);
                        } else {
                            const label = data.outstanding_balance <= 0 ? 'Balance Fully Settled ✓' : 'SaaS Billing Paused';
                            settleContainer.innerHTML = `
                                <form id="settleForm" action="{{ route('owner.billing.settle') }}" method="POST">
                                    <input type="hidden" name="_token" value="${csrfToken}">
                                    <input type="hidden" name="razorpay_payment_id" id="razorpay_payment_id" value="">
                                    <button type="button" disabled 
                                        class="w-full py-3 bg-slate-800 text-slate-400 font-bold text-xs rounded-xl cursor-not-allowed flex items-center justify-center space-x-2">
                                        <i class="fas fa-check-circle text-emerald-400"></i>
                                        <span>${label}</span>
                                    </button>
                                </form>
                            `;
                        }
                    }

                    // 5. Update Itemized SaaS Ledger Statement Table
                    const tbody = document.getElementById('owner-ledgers-table-body');
                    if (tbody) {
                        if (data.ledgers.length === 0) {
                            tbody.innerHTML = `
                                <tr>
                                    <td colspan="5" class="px-6 py-12 text-center text-gray-400">
                                        <i class="fas fa-file-invoice text-4xl mb-3 text-gray-300"></i>
                                        <p>No billing ledger entries in past 6 months.</p>
                                    </td>
                                </tr>
                            `;
                        } else {
                            let rowsHtml = '';
                            data.ledgers.forEach(l => {
                                const linkedBooking = l.booking_id ? `<span class="text-xs text-indigo-600 font-bold block">Linked Booking #${l.booking_id}</span>` : '';
                                const typeBadge = l.type === 'DEBIT'
                                    ? '<span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Fee Debit</span>'
                                    : '<span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Payment Credit</span>';
                                
                                const amtColor = l.type === 'DEBIT' ? 'text-gray-900' : 'text-emerald-600';
                                const amtPrefix = l.type === 'DEBIT' ? '₹' : '- ₹';

                                const statusCol = l.status === 'SETTLED'
                                    ? `<div class="inline-flex items-center space-x-2">
                                        <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">Settled ✓</span>
                                        <a href="/api/v1/business/ledger/${l.id}/invoice" target="_blank" class="px-2.5 py-1 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold rounded-lg border border-indigo-200 transition">
                                            <i class="fas fa-file-download mr-1"></i> Invoice
                                        </a>
                                       </div>`
                                    : `<span class="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">Unpaid</span>`;

                                rowsHtml += `
                                    <tr class="hover:bg-gray-50/80 transition">
                                        <td class="px-6 py-4 text-xs font-medium text-gray-500 whitespace-nowrap">${l.date}</td>
                                        <td class="px-6 py-4 font-medium text-gray-900">${l.description}${linkedBooking}</td>
                                        <td class="px-6 py-4">${typeBadge}</td>
                                        <td class="px-6 py-4 font-black ${amtColor}">${amtPrefix}${l.formatted_amount}</td>
                                        <td class="px-6 py-4 text-right">${statusCol}</td>
                                    </tr>
                                `;
                            });
                            tbody.innerHTML = rowsHtml;
                        }
                    }
                })
                .catch(err => console.error('Owner live data fetch error:', err));
            }

            // Start 5-Second Real-Time Automatic Polling for Shop Owner Portal
            setInterval(fetchOwnerLiveData, 5000);
        });
    </script>
@endsection
