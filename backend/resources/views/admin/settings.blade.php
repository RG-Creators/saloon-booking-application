@extends('layouts.admin')

@section('title', 'Platform Settings & App Remote Controls')

@section('content')
<div class="space-y-8">
    
    <!-- Top Welcome & Status Banner -->
    <div class="bg-gradient-to-r from-indigo-600 to-blue-600 rounded-3xl p-6 md:p-8 text-white shadow-lg shadow-indigo-100 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
            <div class="inline-flex items-center space-x-2 bg-white/20 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider mb-2 text-indigo-100">
                <i class="fas fa-magic"></i>
                <span>Server-Driven Realtime Control</span>
            </div>
            <h2 class="text-2xl font-black">App & Platform Command Center</h2>
            <p class="text-indigo-100 text-xs md:text-sm mt-1 max-w-xl">
                Changes saved here update all Owner & Customer Mobile Apps in real-time without needing a Play Store / App Store release.
            </p>
        </div>
        <div class="flex items-center space-x-3 bg-white/10 backdrop-blur-md px-4 py-3 rounded-2xl border border-white/20">
            <div class="w-3 h-3 rounded-full bg-emerald-400 animate-pulse"></div>
            <div>
                <div class="text-[10px] uppercase font-bold text-indigo-200">System Status</div>
                <div class="text-xs font-black">{{ (isset($settings['maintenance_mode']) && $settings['maintenance_mode']->value === 'true') ? '⚠️ Maintenance Mode Active' : '🟢 Live & Operational' }}</div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        <!-- CARD 1: 🌐 API & Server Connectivity -->
        <div class="bg-white rounded-3xl p-6 md:p-7 border border-gray-100 shadow-sm hover:shadow-md transition space-y-6">
            <div class="flex items-center justify-between border-b border-gray-100 pb-4">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold text-lg">
                        <i class="fas fa-network-wired"></i>
                    </div>
                    <div>
                        <h3 class="text-base font-extrabold text-gray-900">API & Server Connection</h3>
                        <p class="text-xs text-gray-500">Configure where your mobile apps send and receive data.</p>
                    </div>
                </div>
                <span class="bg-indigo-50 text-indigo-700 text-[10px] font-black uppercase px-2.5 py-1 rounded-full">Core Endpoint</span>
            </div>

            <form action="{{ route('admin.settings.api') }}" method="POST" class="space-y-4">
                @csrf
                
                <!-- API Base URL -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5 flex items-center justify-between">
                        <span>API Base URL (Live Endpoint)</span>
                        <span class="text-[10px] text-gray-400 font-normal">Must include /api/v1</span>
                    </label>
                    <div class="relative">
                        <input type="url" name="api_base_url" id="api_base_url_input" required
                               value="{{ $settings['api_base_url']->value ?? 'http://10.21.170.176:8000/api/v1' }}"
                               placeholder="https://bookingsaas.visticafeandrestaurant.com/api/v1"
                               class="w-full pl-3.5 pr-20 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-mono font-bold text-gray-900 outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition">
                        <button type="button" onclick="copyToClipboard('api_base_url_input')"
                                class="absolute right-2 top-2 px-2.5 py-1 bg-white border border-gray-200 hover:bg-gray-50 text-gray-600 text-[11px] font-bold rounded-lg transition shadow-xs">
                            <i class="fas fa-copy mr-1"></i> Copy
                        </button>
                    </div>
                    <div class="mt-1.5 flex flex-wrap gap-2 text-[11px]">
                        <button type="button" onclick="document.getElementById('api_base_url_input').value='https://bookingsaas.visticafeandrestaurant.com/api/v1'"
                                class="text-indigo-600 hover:underline font-bold">
                            Set Production Subdomain
                        </button>
                        <span class="text-gray-300">•</span>
                        <button type="button" onclick="document.getElementById('api_base_url_input').value='http://10.21.170.176:8000/api/v1'"
                                class="text-indigo-600 hover:underline font-bold">
                            Set Localhost IP
                        </button>
                    </div>
                </div>

                <!-- API Secret Key -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5 flex items-center justify-between">
                        <span>App Security Secret Key</span>
                        <span class="text-[10px] text-gray-400 font-normal">X-Api-Secret Header Verification</span>
                    </label>
                    <div class="relative">
                        <input type="text" name="api_secret" id="api_secret_input" required
                               value="{{ $settings['api_secret']->value ?? 'saas_secret_key_v1' }}"
                               placeholder="e.g. saas_secret_key_v1"
                               class="w-full pl-3.5 pr-28 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-mono font-bold text-gray-900 outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition">
                        <div class="absolute right-2 top-2 flex items-center space-x-1">
                            <button type="button" onclick="generateRandomKey('api_secret_input')"
                                    class="px-2 py-1 bg-white border border-gray-200 hover:bg-gray-50 text-gray-600 text-[10px] font-bold rounded-lg transition shadow-xs" title="Generate New Key">
                                <i class="fas fa-sync-alt"></i>
                            </button>
                            <button type="button" onclick="copyToClipboard('api_secret_input')"
                                    class="px-2.5 py-1 bg-white border border-gray-200 hover:bg-gray-50 text-gray-600 text-[11px] font-bold rounded-lg transition shadow-xs">
                                <i class="fas fa-copy"></i>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- In-App Announcement / Notice -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5">In-App Banner Notice (Optional)</label>
                    <input type="text" name="app_announcement" value="{{ $settings['app_announcement']->value ?? '' }}"
                           placeholder="e.g. System upgrade scheduled tonight at 11 PM"
                           class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs text-gray-900 outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition">
                </div>

                <!-- Emergency Maintenance Control Box -->
                @php
                    $isMaintOn = isset($settings['maintenance_mode']) && $settings['maintenance_mode']->value === 'true';
                @endphp
                <div class="p-4 bg-amber-50/70 border border-amber-200 rounded-2xl space-y-3">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-3">
                            <div class="w-8 h-8 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center">
                                <i class="fas fa-tools"></i>
                            </div>
                            <div>
                                <div class="text-xs font-bold text-amber-900">Maintenance Mode</div>
                                <div class="text-[11px] text-amber-700">Display maintenance screen on all mobile apps</div>
                            </div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="maintenance_mode" value="true" id="maint_toggle"
                                   {{ $isMaintOn ? 'checked' : '' }}
                                   onchange="document.getElementById('maint_details').classList.toggle('hidden', !this.checked)"
                                   class="sr-only peer">
                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-amber-500"></div>
                        </label>
                    </div>

                    <!-- Maintenance Extended Fields -->
                    <div id="maint_details" class="{{ $isMaintOn ? '' : 'hidden' }} space-y-3 pt-2 border-t border-amber-200/60">
                        <div>
                            <label class="block text-[11px] font-bold text-amber-900 mb-1">Estimated Completion Time (ETA)</label>
                            <input type="text" name="maintenance_eta" value="{{ $settings['maintenance_eta']->value ?? '' }}"
                                   placeholder="e.g. Tonight at 11:30 PM / in 45 minutes"
                                   class="w-full px-3 py-2 bg-white border border-amber-300 rounded-xl text-xs text-gray-900 outline-none focus:ring-2 focus:ring-amber-500">
                        </div>

                        <div>
                            <label class="block text-[11px] font-bold text-amber-900 mb-1">Maintenance Message</label>
                            <textarea name="maintenance_message" rows="2" placeholder="e.g. We are performing scheduled server upgrades to enhance performance."
                                      class="w-full px-3 py-2 bg-white border border-amber-300 rounded-xl text-xs text-gray-900 outline-none focus:ring-2 focus:ring-amber-500">{{ $settings['maintenance_message']->value ?? 'We are performing scheduled maintenance to enhance system performance. Please check back shortly.' }}</textarea>
                        </div>

                        <label class="flex items-center space-x-2 cursor-pointer bg-white p-2.5 rounded-xl border border-amber-200">
                            <input type="checkbox" name="notify_users" value="1" class="text-amber-600 rounded">
                            <span class="text-xs font-bold text-amber-900">🔔 Broadcast Push Notification to all users about this downtime</span>
                        </label>
                    </div>
                </div>

                <div class="pt-2 flex justify-end">
                    <button type="submit" class="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-2">
                        <i class="fas fa-save"></i>
                        <span>Save API & Server Settings</span>
                    </button>
                </div>
            </form>
        </div>

        <!-- CARD 2: 🎨 App Branding & Visual Theme -->
        <div class="bg-white rounded-3xl p-6 md:p-7 border border-gray-100 shadow-sm hover:shadow-md transition space-y-6">
            <div class="flex items-center justify-between border-b border-gray-100 pb-4">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold text-lg">
                        <i class="fas fa-paint-brush"></i>
                    </div>
                    <div>
                        <h3 class="text-base font-extrabold text-gray-900">App Theme & Branding</h3>
                        <p class="text-xs text-gray-500">Customize colors, typography and mobile layout styling.</p>
                    </div>
                </div>
                <span class="bg-emerald-50 text-emerald-700 text-[10px] font-black uppercase px-2.5 py-1 rounded-full">Server Driven UI</span>
            </div>

            <form action="{{ route('admin.settings.theme') }}" method="POST" enctype="multipart/form-data" class="space-y-4">
                @csrf

                <!-- App Logo & Branding Management -->
                <div class="p-4 bg-gray-50/80 rounded-2xl border border-gray-200 space-y-3">
                    <div class="flex items-center justify-between">
                        <div>
                            <label class="block text-xs font-bold text-gray-900">App Header Logo & Branding</label>
                            <p class="text-[11px] text-gray-500">Upload custom PNG/SVG logo, or keep the default colorless Flutter icon.</p>
                        </div>
                        @if(!empty($themeData['app_logo']))
                            <span class="text-[10px] font-black text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">Custom Logo Active</span>
                        @else
                            <span class="text-[10px] font-black text-indigo-700 bg-indigo-100 px-2 py-0.5 rounded-full">Default: Colorless Flutter Icon</span>
                        @endif
                    </div>

                    <div class="flex items-center space-x-4 pt-1">
                        <!-- Logo Visual Preview -->
                        <div class="relative group">
                            @if(!empty($themeData['app_logo']))
                                <div class="w-14 h-14 rounded-2xl bg-white border border-gray-200 p-2 shadow-xs flex items-center justify-center overflow-hidden">
                                    <img src="{{ asset($themeData['app_logo']) }}" alt="App Logo" class="max-w-full max-h-full object-contain">
                                </div>
                            @else
                                <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center p-3 shadow-xs">
                                    <!-- Colorless Monochrome Flutter Icon -->
                                    <svg class="w-full h-full text-white fill-current" viewBox="0 0 166 202">
                                        <path d="M100.3 0L0 100.3l30.1 30.1L160.5 0h-60.2z" opacity="0.95"/>
                                        <path d="M100.3 67.8L38.4 129.7l30.1 30.1 61.9-61.9h-30.1z" opacity="0.8"/>
                                        <path d="M68.5 159.8L100.3 191.6l60.2-60.2h-60.2l-31.8 28.4z" opacity="0.55"/>
                                        <path d="M100.3 131.4l28.4-28.4h60.2L128.7 163l-28.4-31.6z" opacity="0.9"/>
                                    </svg>
                                </div>
                            @endif
                        </div>

                        <!-- Upload Input & Remove Button -->
                        <div class="flex-1 space-y-1.5">
                            <input type="file" name="app_logo" accept="image/png,image/jpeg,image/svg+xml,image/webp,image/gif"
                                   class="block w-full text-xs text-gray-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100 cursor-pointer">
                            <div class="flex items-center justify-between text-[10px] text-gray-400">
                                <span>Supports PNG, SVG, JPG, WebP (Max 5MB)</span>
                                @if(!empty($themeData['app_logo']))
                                    <button type="submit" name="remove_logo" value="1" onclick="return confirm('Reset App Logo back to the default colorless Flutter icon?')"
                                            class="text-rose-600 font-bold hover:text-rose-800 transition">
                                        <i class="fas fa-trash-alt mr-1"></i>Reset to Default Flutter Icon
                                    </button>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Primary Brand Color -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5">Primary Accent Color</label>
                    <div class="flex items-center space-x-3">
                        <input type="color" id="primary_color_picker" name="primary_color"
                               value="{{ $themeData['primary_color'] ?? '#4F46E5' }}"
                               onchange="document.getElementById('primary_color_text').value=this.value"
                               class="w-10 h-10 rounded-xl cursor-pointer border-0 p-0 bg-transparent">
                        <input type="text" id="primary_color_text" name="primary_color"
                               value="{{ $themeData['primary_color'] ?? '#4F46E5' }}"
                               oninput="document.getElementById('primary_color_picker').value=this.value"
                               class="w-32 px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-mono font-bold text-gray-900 uppercase outline-none focus:ring-2 focus:ring-emerald-500">
                    </div>

                    <!-- Quick Palette Presets -->
                    <div class="mt-2.5 flex items-center space-x-2">
                        <span class="text-[11px] text-gray-400 font-semibold">Presets:</span>
                        <button type="button" onclick="setColor('#4F46E5')" class="w-6 h-6 rounded-full bg-[#4F46E5] ring-2 ring-offset-1 ring-transparent hover:ring-indigo-400 transition" title="Indigo"></button>
                        <button type="button" onclick="setColor('#059669')" class="w-6 h-6 rounded-full bg-[#059669] ring-2 ring-offset-1 ring-transparent hover:ring-emerald-400 transition" title="Emerald"></button>
                        <button type="button" onclick="setColor('#D97706')" class="w-6 h-6 rounded-full bg-[#D97706] ring-2 ring-offset-1 ring-transparent hover:ring-amber-400 transition" title="Amber Gold"></button>
                        <button type="button" onclick="setColor('#E11D48')" class="w-6 h-6 rounded-full bg-[#E11D48] ring-2 ring-offset-1 ring-transparent hover:ring-rose-400 transition" title="Rose"></button>
                        <button type="button" onclick="setColor('#2563EB')" class="w-6 h-6 rounded-full bg-[#2563EB] ring-2 ring-offset-1 ring-transparent hover:ring-blue-400 transition" title="Royal Blue"></button>
                        <button type="button" onclick="setColor('#7C3AED')" class="w-6 h-6 rounded-full bg-[#7C3AED] ring-2 ring-offset-1 ring-transparent hover:ring-purple-400 transition" title="Violet"></button>
                    </div>
                </div>

                <!-- Font Family -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5">Mobile App Font Family</label>
                    <select name="font_family" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold text-gray-800 outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition">
                        <option value="Poppins" {{ ($themeData['font_family'] ?? 'Poppins') === 'Poppins' ? 'selected' : '' }}>Poppins (Modern & Premium)</option>
                        <option value="Inter" {{ ($themeData['font_family'] ?? '') === 'Inter' ? 'selected' : '' }}>Inter (Clean & Minimal)</option>
                        <option value="Plus Jakarta Sans" {{ ($themeData['font_family'] ?? '') === 'Plus Jakarta Sans' ? 'selected' : '' }}>Plus Jakarta Sans (Contemporary)</option>
                        <option value="Roboto" {{ ($themeData['font_family'] ?? '') === 'Roboto' ? 'selected' : '' }}>Roboto (Classic Android)</option>
                    </select>
                </div>

                <!-- Corner Radius -->
                <div>
                    <label class="block text-xs font-bold text-gray-800 mb-1.5">Button & Card Corner Radius (px)</label>
                    <div class="grid grid-cols-3 gap-3">
                        <label class="flex items-center space-x-2 p-2.5 bg-gray-50 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-100 transition">
                            <input type="radio" name="button_border_radius" value="8" {{ ($themeData['button_border_radius'] ?? 14) == 8 ? 'checked' : '' }} class="text-emerald-600">
                            <span class="text-xs font-bold text-gray-800">8px (Sharp)</span>
                        </label>
                        <label class="flex items-center space-x-2 p-2.5 bg-gray-50 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-100 transition">
                            <input type="radio" name="button_border_radius" value="14" {{ ($themeData['button_border_radius'] ?? 14) == 14 ? 'checked' : '' }} class="text-emerald-600">
                            <span class="text-xs font-bold text-gray-800">14px (Smooth)</span>
                        </label>
                        <label class="flex items-center space-x-2 p-2.5 bg-gray-50 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-100 transition">
                            <input type="radio" name="button_border_radius" value="24" {{ ($themeData['button_border_radius'] ?? 14) == 24 ? 'checked' : '' }} class="text-emerald-600">
                            <span class="text-xs font-bold text-gray-800">24px (Pill)</span>
                        </label>
                    </div>
                </div>

                <!-- Dashboard Revenue Card Toggle -->
                <div class="p-3.5 bg-gray-50 rounded-2xl flex items-center justify-between border border-gray-200">
                    <div>
                        <div class="text-xs font-bold text-gray-900">Show Revenue Metric Cards</div>
                        <div class="text-[11px] text-gray-500">Display today's revenue on owner home screen</div>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" name="show_revenue_card" value="1"
                               {{ !empty($themeData['show_revenue_card']) ? 'checked' : '' }}
                               class="sr-only peer">
                        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600"></div>
                    </label>
                </div>

                <div class="pt-2 flex justify-end">
                    <button type="submit" class="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-2">
                        <i class="fas fa-paint-roller"></i>
                        <span>Apply Theme Changes</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- CARD 3: ⚡ Remote Feature Switches (Non-Tech Controls) -->
    <div class="bg-white rounded-3xl p-6 md:p-8 border border-gray-100 shadow-sm">
        <div class="flex flex-col md:flex-row md:items-center justify-between border-b border-gray-100 pb-5 gap-4">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold text-lg">
                    <i class="fas fa-toggle-on"></i>
                </div>
                <div>
                    <h3 class="text-base font-extrabold text-gray-900">Remote Feature Flags & Modules</h3>
                    <p class="text-xs text-gray-500">Instantly enable or disable specific features across the mobile application.</p>
                </div>
            </div>
            <button onclick="document.getElementById('add-flag-modal').classList.remove('hidden')"
                    class="px-4 py-2 bg-gray-900 hover:bg-black text-white text-xs font-bold rounded-xl transition shadow-sm flex items-center space-x-1.5 self-start md:self-auto">
                <i class="fas fa-plus"></i>
                <span>Add Custom Flag</span>
            </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 pt-6">
            @php
                $featureIcons = [
                    'enable_offline_mode' => ['icon' => 'fa-wifi-slash', 'color' => 'indigo', 'title' => 'Offline Caching', 'desc' => 'Allows owner app to load cached data without active internet.'],
                    'enable_booking_chat' => ['icon' => 'fa-comments', 'color' => 'blue', 'title' => 'Customer Chat', 'desc' => 'Direct in-app messaging between customers and staff.'],
                    'enable_multi_branch' => ['icon' => 'fa-store-alt', 'color' => 'emerald', 'title' => 'Multi-Branch Support', 'desc' => 'Allows owners to manage up to 4 branch locations.'],
                    'enable_customer_reviews' => ['icon' => 'fa-star', 'color' => 'amber', 'title' => 'Customer Reviews', 'desc' => 'Enables verified appointment reviews & star ratings.'],
                    'enable_auto_slot_locking' => ['icon' => 'fa-lock', 'color' => 'purple', 'title' => 'Auto Slot Locking', 'desc' => 'Locks slots for 5 mins during customer checkout.'],
                    'enable_combo_packages' => ['icon' => 'fa-layer-group', 'color' => 'rose', 'title' => 'Combos & Packages', 'desc' => 'Enables discounted bundled multi-service packages.'],
                ];
            @endphp

            @forelse($featureFlags as $flag)
            @php
                $info = $featureIcons[$flag->feature_name] ?? ['icon' => 'fa-cube', 'color' => 'gray', 'title' => ucwords(str_replace('_', ' ', $flag->feature_name)), 'desc' => 'Remote feature rollout setting.'];
            @endphp
            <div class="p-5 rounded-2xl border border-gray-100 bg-gray-50/50 flex flex-col justify-between space-y-4 hover:border-gray-200 transition">
                <div class="flex items-start justify-between">
                    <div class="flex items-center space-x-3">
                        <div class="w-9 h-9 rounded-xl bg-white shadow-xs flex items-center justify-center text-gray-700 border border-gray-100">
                            <i class="fas {{ $info['icon'] }}"></i>
                        </div>
                        <div>
                            <div class="text-xs font-black text-gray-900">{{ $info['title'] }}</div>
                            <div class="font-mono text-[10px] text-gray-400">{{ $flag->feature_name }}</div>
                        </div>
                    </div>
                    <form action="{{ route('admin.settings.flags.toggle', $flag) }}" method="POST">
                        @csrf
                        <button type="submit" class="px-2.5 py-1 rounded-full text-[11px] font-black transition {{ $flag->enabled ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200' : 'bg-gray-200 text-gray-600 hover:bg-gray-300' }}">
                            {{ $flag->enabled ? 'ON' : 'OFF' }}
                        </button>
                    </form>
                </div>
                <div class="text-xs text-gray-500 leading-relaxed">{{ $info['desc'] }}</div>
                <div class="flex items-center justify-between text-[11px] text-gray-400 border-t border-gray-100 pt-3">
                    <span>Rollout Target:</span>
                    <span class="font-bold text-gray-700">{{ $flag->rollout_percentage }}% of users</span>
                </div>
            </div>
            @empty
            <div class="col-span-3 py-8 text-center text-gray-400 text-xs">No feature flags configured.</div>
            @endforelse
        </div>
    </div>

    <!-- CARD 4: 💳 Platform Fees & SaaS Billing Engine -->
    <div class="bg-white rounded-3xl p-6 md:p-8 border border-gray-100 shadow-sm space-y-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between border-b border-gray-100 pb-5 gap-4">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center font-bold text-lg">
                    <i class="fas fa-coins"></i>
                </div>
                <div>
                    <h3 class="text-base font-extrabold text-gray-900">SaaS Billing Engine & Monetization</h3>
                    <p class="text-xs text-gray-500">Enable or disable commission billing, and adjust platform fees and thresholds.</p>
                </div>
            </div>
            
            <!-- Master Billing Engine Toggle Button -->
            @php 
                $isBillingOn = isset($settings['billing_enabled']) && ($settings['billing_enabled']->value === 'true' || $settings['billing_enabled']->value === '1');
            @endphp
            <form action="{{ route('admin.settings.billing.toggle') }}" method="POST">
                @csrf
                <button type="submit" class="px-4 py-2 rounded-xl text-xs font-black transition flex items-center space-x-2 shadow-sm {{ $isBillingOn ? 'bg-emerald-600 hover:bg-emerald-700 text-white' : 'bg-gray-200 hover:bg-gray-300 text-gray-700' }}">
                    <i class="fas {{ $isBillingOn ? 'fa-toggle-on text-emerald-200' : 'fa-toggle-off text-gray-500' }} text-base"></i>
                    <span>{{ $isBillingOn ? 'Billing Engine: ACTIVE' : 'Billing Engine: DISABLED' }}</span>
                </button>
            </form>
        </div>

        <!-- Master Billing Notice Banner -->
        <div class="p-4 rounded-2xl border {{ $isBillingOn ? 'bg-emerald-50/50 border-emerald-200 text-emerald-900' : 'bg-amber-50/70 border-amber-200 text-amber-900' }} flex items-start space-x-3 text-xs">
            <div class="w-6 h-6 rounded-lg {{ $isBillingOn ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700' }} flex items-center justify-center shrink-0 mt-0.5">
                <i class="fas {{ $isBillingOn ? 'fa-check-circle' : 'fa-exclamation-triangle' }}"></i>
            </div>
            <div>
                <div class="font-bold">{{ $isBillingOn ? 'SaaS Commission Engine is Live' : 'SaaS Commission Engine is Currently Paused' }}</div>
                <div class="text-[11px] opacity-80 mt-0.5">
                    {{ $isBillingOn 
                        ? 'Shop owners are automatically charged the per-booking commission fee upon appointment completion. Dues are tracked in real-time.' 
                        : 'Billing is disabled. All salon appointments are free of platform commission, and shop owners will not accumulate dues.' }}
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
            @if(isset($settings['booking_commission_fee']))
            <div class="p-4 bg-gray-50 rounded-2xl border border-gray-200 space-y-2">
                <div class="text-xs font-bold text-gray-900">Per-Booking Commission Fee (₹)</div>
                <div class="text-[11px] text-gray-500">Commission charged per completed customer appointment.</div>
                <form action="{{ route('admin.settings.update', $settings['booking_commission_fee']) }}" method="POST" class="flex items-center space-x-2 pt-2">
                    @csrf
                    <div class="relative w-full">
                        <span class="absolute left-3 top-2 text-xs font-bold text-gray-400">₹</span>
                        <input type="number" step="0.5" name="value" value="{{ $settings['booking_commission_fee']->value }}" class="pl-7 pr-3 py-1.5 bg-white border border-gray-200 rounded-xl text-xs font-bold text-gray-900 outline-none focus:ring-2 focus:ring-purple-500 w-full">
                    </div>
                    <button type="submit" class="px-4 py-1.5 bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold rounded-xl transition">
                        Update
                    </button>
                </form>
            </div>
            @endif

            @if(isset($settings['billing_due_threshold']))
            <div class="p-4 bg-gray-50 rounded-2xl border border-gray-200 space-y-2">
                <div class="text-xs font-bold text-gray-900">Auto-Pay Due Threshold (₹)</div>
                <div class="text-[11px] text-gray-500">Amount at which a shop owner is prompted to settle dues.</div>
                <form action="{{ route('admin.settings.update', $settings['billing_due_threshold']) }}" method="POST" class="flex items-center space-x-2 pt-2">
                    @csrf
                    <div class="relative w-full">
                        <span class="absolute left-3 top-2 text-xs font-bold text-gray-400">₹</span>
                        <input type="number" step="50" name="value" value="{{ $settings['billing_due_threshold']->value }}" class="pl-7 pr-3 py-1.5 bg-white border border-gray-200 rounded-xl text-xs font-bold text-gray-900 outline-none focus:ring-2 focus:ring-purple-500 w-full">
                    </div>
                    <button type="submit" class="px-4 py-1.5 bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold rounded-xl transition">
                        Update
                    </button>
                </form>
            </div>
            @endif
        </div>
    </div>
</div>

<!-- Modal: Add Feature Flag -->
<div id="add-flag-modal" class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 hidden">
    <div class="bg-white rounded-3xl max-w-md w-full p-6 shadow-xl border border-gray-100 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-base font-extrabold text-gray-900 flex items-center space-x-2">
                <span class="w-8 h-8 rounded-xl bg-gray-100 text-gray-700 flex items-center justify-center">
                    <i class="fas fa-flag"></i>
                </span>
                <span>Create Remote Feature Flag</span>
            </h3>
            <button onclick="document.getElementById('add-flag-modal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times"></i>
            </button>
        </div>

        <form action="{{ route('admin.settings.flags.store') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-bold text-gray-700 mb-1">Feature Name (Snake Case)</label>
                <input type="text" name="feature_name" required placeholder="e.g. enable_loyalty_rewards"
                       class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-mono outline-none focus:ring-2 focus:ring-indigo-500">
            </div>

            <div>
                <label class="block text-xs font-bold text-gray-700 mb-1">Rollout Percentage (0 - 100%)</label>
                <input type="number" min="0" max="100" name="rollout_percentage" value="100" required
                       class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs outline-none focus:ring-2 focus:ring-indigo-500">
            </div>

            <div class="flex items-center justify-end space-x-3 pt-2">
                <button type="button" onclick="document.getElementById('add-flag-modal').classList.add('hidden')"
                        class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-bold rounded-xl transition">
                    Cancel
                </button>
                <button type="submit" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-xl transition shadow-sm">
                    Create Flag
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    function copyToClipboard(elementId) {
        const copyText = document.getElementById(elementId);
        copyText.select();
        copyText.setSelectionRange(0, 99999);
        navigator.clipboard.writeText(copyText.value);
        alert('Copied to clipboard: ' + copyText.value);
    }

    function generateRandomKey(elementId) {
        const rand = 'saas_secret_' + Math.random().toString(36).substring(2, 12) + '_' + Date.now().toString(36);
        document.getElementById(elementId).value = rand;
    }

    function setColor(hex) {
        document.getElementById('primary_color_picker').value = hex;
        document.getElementById('primary_color_text').value = hex;
    }
</script>
@endsection
