@extends('layouts.owner')

@section('title', 'CRM Marketing & Offers')

@section('content')
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Campaign Composer -->
        <div class="lg:col-span-1 bg-white rounded-2xl p-6 shadow-sm border border-gray-100 h-fit">
            <h3 class="text-lg font-bold text-gray-900 mb-4 pb-3 border-b border-gray-100 flex items-center">
                <i class="fas fa-bullhorn text-pink-600 mr-2"></i> New Campaign
            </h3>

            <form action="{{ route('owner.marketing.send') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Target Segment</label>
                    <select name="target_segment" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-pink-500 outline-none">
                        <option value="ALL">All Customers ({{ $totalCustomers }})</option>
                        <option value="VIP">VIP & Added CRM Members ({{ $vipCustomers }})</option>
                        <option value="INACTIVE">Inactive Customers</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Campaign Title (Push Notification Header)</label>
                    <input type="text" name="campaign_title" required placeholder="e.g. 50% Off Weekend Special!" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-pink-500 outline-none">
                </div>

                <div class="mb-6">
                    <label class="block text-xs font-semibold uppercase text-gray-500 mb-1">Promotional Message</label>
                    <textarea name="campaign_message" required rows="4" placeholder="Type your offer details here... This will be sent directly to your customers' phones!" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-pink-500 outline-none resize-none"></textarea>
                    <p class="text-[10px] text-gray-400 mt-1">Keep it short and exciting! Emojis are supported. 🚀</p>
                </div>

                <button type="submit" class="w-full py-3 bg-pink-600 hover:bg-pink-700 text-white font-semibold rounded-xl transition text-sm shadow-sm flex items-center justify-center">
                    <i class="fas fa-paper-plane mr-2"></i> Dispatch Campaign Now
                </button>
            </form>
        </div>

        <!-- Recent Campaigns & Stats -->
        <div class="lg:col-span-2 space-y-8">
            
            <div class="grid grid-cols-2 gap-4">
                <div class="bg-gradient-to-br from-white to-pink-50/50 rounded-2xl p-6 shadow-sm border border-pink-100 flex items-center justify-between">
                    <div>
                        <p class="text-xs font-bold uppercase tracking-wider text-pink-600 mb-1">Reach Potential</p>
                        <h4 class="text-3xl font-black text-gray-900">{{ $totalCustomers }}</h4>
                    </div>
                    <div class="w-12 h-12 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center text-xl shadow-inner">
                        <i class="fas fa-users"></i>
                    </div>
                </div>

                <div class="bg-gradient-to-br from-white to-purple-50/50 rounded-2xl p-6 shadow-sm border border-purple-100 flex items-center justify-between">
                    <div>
                        <p class="text-xs font-bold uppercase tracking-wider text-purple-600 mb-1">VIP & Added Members</p>
                        <h4 class="text-3xl font-black text-gray-900">{{ $vipCustomers }}</h4>
                    </div>
                    <div class="w-12 h-12 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center text-xl shadow-inner">
                        <i class="fas fa-crown"></i>
                    </div>
                </div>
            </div>

            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <div class="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <h3 class="text-lg font-bold text-gray-900">Recent Dispatches</h3>
                </div>
                
                <div class="divide-y divide-gray-100">
                    @forelse($recentCampaigns as $log)
                        <div class="p-6 hover:bg-gray-50 transition flex items-start">
                            <div class="w-10 h-10 rounded-xl bg-pink-50 text-pink-600 flex items-center justify-center text-lg mr-4 shrink-0 shadow-sm border border-pink-100">
                                <i class="fas fa-bolt"></i>
                            </div>
                            <div>
                                <h4 class="text-sm font-bold text-gray-900 mb-1">Promotional Campaign Sent</h4>
                                <p class="text-xs text-gray-600 leading-relaxed">{{ $log->description }}</p>
                                <p class="text-[10px] text-gray-400 mt-2 font-semibold">{{ $log->created_at->diffForHumans() }}</p>
                            </div>
                        </div>
                    @empty
                        <div class="p-12 text-center text-gray-400">
                            <i class="fas fa-inbox text-4xl mb-3 text-gray-300"></i>
                            <p>No past campaigns found. Create your first offer to boost bookings!</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
@endsection
