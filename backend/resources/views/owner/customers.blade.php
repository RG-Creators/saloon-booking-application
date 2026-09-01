@extends('layouts.owner')

@section('title', 'Customers & CRM Management')

@section('content')
    @if(session('success'))
        <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-check-circle text-emerald-500 text-lg mr-3"></i> {{ session('success') }}
        </div>
    @endif

    @if(session('error'))
        <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-2xl text-xs font-bold flex items-center shadow-sm">
            <i class="fas fa-exclamation-circle text-red-500 text-lg mr-3"></i> {{ session('error') }}
        </div>
    @endif

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
        
        <!-- Add New Customer to CRM Card -->
        <div class="lg:col-span-1 bg-white rounded-3xl p-6 shadow-sm border border-gray-100 h-fit">
            <div class="border-b border-gray-100 pb-4 mb-5">
                <h3 class="text-lg font-bold text-gray-900 flex items-center">
                    <i class="fas fa-user-plus text-blue-600 mr-2"></i> Add / Pre-Approve Customer
                </h3>
                <p class="text-xs text-gray-500 mt-0.5">Pre-approve customers so they can book when "Added Customers Only" or "Free Booking for Added Users" policy is enabled.</p>
            </div>

            <form action="{{ route('owner.customers.add') }}" method="POST">
                @csrf
                <div class="mb-5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Customer Email or Mobile Number</label>
                    <input type="text" name="email_or_mobile" required placeholder="customer@glamora.com or +91 9876543210" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl text-xs font-bold outline-none focus:ring-2 focus:ring-blue-500">
                </div>

                <button type="submit" class="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-2xl transition shadow-md">
                    <i class="fas fa-plus mr-1"></i> Add to Approved CRM List
                </button>
            </form>
        </div>

        <!-- Customer CRM Directory -->
        <div class="lg:col-span-2 bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <div>
                    <h3 class="text-lg font-bold text-gray-900">Registered Customer List</h3>
                    <p class="text-xs text-gray-500 mt-0.5">Manage customer access rules for {{ $tenant->business_name }}</p>
                </div>
                <span class="text-xs font-bold bg-blue-100 text-blue-800 px-3 py-1 rounded-full border border-blue-200">
                    {{ count($addedCustomerIds) }} Approved VIP Customer(s)
                </span>
            </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-white text-gray-400 text-xs uppercase tracking-wider border-b border-gray-100">
                            <th class="px-6 py-4 font-semibold">Customer Identity</th>
                            <th class="px-6 py-4 font-semibold">Contact & Location</th>
                            <th class="px-6 py-4 font-semibold">CRM Status</th>
                            <th class="px-6 py-4 font-semibold text-right">Action</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        @forelse($allCustomers as $customer)
                        @php $isAdded = in_array($customer->id, $addedCustomerIds); @endphp
                        <tr class="hover:bg-gray-50/80 transition">
                            <td class="px-6 py-4 font-medium text-gray-900">
                                <div class="flex items-center">
                                    <div class="w-9 h-9 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold mr-3 text-sm shadow-sm">
                                        {{ substr($customer->name, 0, 1) }}
                                    </div>
                                    <div>
                                        <div class="font-bold text-gray-900">{{ $customer->name }}</div>
                                        <div class="text-[11px] text-gray-400">Registered Client</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-xs text-gray-600">
                                <div class="font-bold text-gray-900">{{ $customer->email }}</div>
                                <div class="text-[11px] mt-0.5 text-gray-500 font-mono">
                                    <i class="fas fa-phone text-blue-500 mr-1"></i> {{ $customer->mobile ?? 'N/A' }} • PIN: {{ $customer->pin_code ?? '110001' }}
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                @if($isAdded)
                                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                                        <i class="fas fa-check-circle text-emerald-600 mr-1.5"></i> ADDED / VIP REGULAR
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-600 border border-gray-200">
                                        NEW / NON-ADDED
                                    </span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-right">
                                <form action="{{ route('owner.customers.toggle', $customer) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition shadow-sm {{ $isAdded ? 'bg-red-50 hover:bg-red-100 text-red-600 border border-red-200' : 'bg-emerald-600 hover:bg-emerald-700 text-white' }}">
                                        <i class="fas {{ $isAdded ? 'fa-user-minus mr-1' : 'fa-user-plus mr-1' }}"></i>
                                        {{ $isAdded ? 'Remove from Approved' : '+ Add to Customer List' }}
                                    </button>
                                </form>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="px-6 py-12 text-center text-gray-400">
                                <i class="fas fa-users-slash text-4xl mb-3 text-gray-300"></i>
                                <p>No registered customers found in the system.</p>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

    </div>
@endsection
