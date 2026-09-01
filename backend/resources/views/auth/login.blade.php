<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glamora Portal & Registration</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #f8fafc; }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen bg-gray-50 py-12 px-4">

    <div class="w-full max-w-xl p-8 bg-white rounded-3xl shadow-xl border border-gray-100">
        <div class="text-center mb-6">
            <h1 class="text-3xl font-black text-blue-600 mb-1 flex items-center justify-center">
                <i class="fas fa-scissors mr-2 text-blue-600"></i> Glamora
            </h1>
            <p class="text-xs text-gray-400 font-medium">Multi-Tenant Barber & Salon SaaS Platform</p>
        </div>

        <!-- Mode Navigation Tabs -->
        <div class="flex bg-gray-100 p-1.5 rounded-2xl mb-8 border border-gray-200/60">
            <button id="tab-login" onclick="switchTab('login')" class="flex-1 py-2.5 text-xs font-bold rounded-xl transition text-blue-600 bg-white shadow-sm">
                <i class="fas fa-sign-in-alt mr-1"></i> Sign In
            </button>
            <button id="tab-cust-register" onclick="switchTab('cust-register')" class="flex-1 py-2.5 text-xs font-bold rounded-xl transition text-gray-500 hover:text-gray-900">
                <i class="fas fa-user-plus mr-1 text-blue-600"></i> Customer Register
            </button>
            <button id="tab-shop-register" onclick="switchTab('shop-register')" class="flex-1 py-2.5 text-xs font-bold rounded-xl transition text-gray-500 hover:text-gray-900">
                <i class="fas fa-store mr-1 text-emerald-600"></i> Register Shop
            </button>
        </div>

        @if(session('success_registration'))
            <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-semibold flex items-center shadow-sm">
                <i class="fas fa-check-circle text-emerald-500 text-lg mr-3"></i>
                <div>{{ session('success_registration') }}</div>
            </div>
        @endif

        @if($errors->any())
            <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-600 rounded-2xl text-xs font-medium">
                {{ $errors->first() }}
            </div>
        @endif

        <!-- ================= 1. LOGIN FORM ================= -->
        <div id="form-login">
            <form action="{{ route('login.submit') }}" method="POST">
                @csrf
                
                <div class="mb-4">
                    <label for="email" class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Email Address</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                            <i class="fas fa-envelope text-gray-400 text-sm"></i>
                        </div>
                        <input type="email" name="email" id="email" value="{{ old('email') }}" required 
                            class="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all outline-none"
                            placeholder="user@glamora.com">
                    </div>
                </div>

                <div class="mb-5">
                    <label for="password" class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Password</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                            <i class="fas fa-lock text-gray-400 text-sm"></i>
                        </div>
                        <input type="password" name="password" id="password" required 
                            class="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all outline-none"
                            placeholder="••••••••">
                    </div>
                </div>

                <div class="flex items-center justify-between mb-6">
                    <div class="flex items-center">
                        <input id="remember" name="remember" type="checkbox" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded">
                        <label for="remember" class="ml-2 block text-xs font-semibold text-gray-600">Remember me</label>
                    </div>
                </div>

                <button type="submit" class="w-full py-3.5 px-4 rounded-xl shadow-lg text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all">
                    Sign In to Dashboard
                </button>
            </form>
        </div>

        <!-- ================= 2. CUSTOMER REGISTRATION FORM ================= -->
        <div id="form-cust-register" class="hidden">
            <div class="bg-blue-50/70 border border-blue-100 p-4 rounded-2xl mb-5 text-xs text-blue-900 font-medium">
                <i class="fas fa-map-marker-alt text-blue-600 mr-1.5"></i> Enter your location PIN Code to automatically fetch and discover nearby salons around you.
            </div>

            <form action="{{ route('register.customer') }}" method="POST">
                @csrf

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Full Name</label>
                        <input type="text" name="name" required placeholder="Alex Smith" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Email Address</label>
                        <input type="email" name="email" required placeholder="alex@gmail.com" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Mobile Number</label>
                        <input type="text" name="mobile" required placeholder="+91 9876543210" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">PIN Code (Location)</label>
                        <div class="relative">
                            <input type="text" name="pin_code" id="cust_pincode" required placeholder="e.g. 110001" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                            <button type="button" onclick="autofetchPincode()" class="absolute right-2 top-2 px-2.5 py-1 bg-blue-100 hover:bg-blue-200 text-blue-700 text-[10px] font-bold rounded-lg transition" title="Autofetch Location">
                                <i class="fas fa-location-arrow"></i> Auto
                            </button>
                        </div>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">City</label>
                        <input type="text" name="city" id="cust_city" required placeholder="New Delhi" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Password</label>
                        <input type="password" name="password" required placeholder="••••••••" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <button type="submit" class="w-full py-3.5 px-4 rounded-xl shadow-lg text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none transition-all">
                    Register Customer Account & Explore
                </button>
            </form>
        </div>

        <!-- ================= 3. SHOP OWNER REGISTRATION FORM ================= -->
        <div id="form-shop-register" class="hidden">
            <div class="bg-blue-50/70 border border-blue-100 p-4 rounded-2xl mb-5 text-xs text-blue-900 font-medium">
                <i class="fas fa-info-circle text-blue-600 mr-1.5"></i> Submit your salon details & shop verification image proof for SaaS Super Admin review.
            </div>

            <form action="{{ route('register.shop') }}" method="POST" enctype="multipart/form-data">
                @csrf

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Salon Business Name</label>
                        <input type="text" name="business_name" required placeholder="e.g. Royal Grooming Lounge" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Business Type</label>
                        <select name="business_type" required class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                            <option value="Barbershop">Barbershop</option>
                            <option value="Hair Salon">Hair Salon</option>
                            <option value="Beauty Spa">Beauty Spa</option>
                            <option value="Unisex Grooming">Unisex Grooming</option>
                        </select>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Owner Full Name</label>
                        <input type="text" name="owner_name" required placeholder="Owner Name" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Owner Email Address</label>
                        <input type="email" name="email" required placeholder="owner@mysalon.com" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Password</label>
                        <input type="password" name="password" required placeholder="••••••••" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">City Location</label>
                        <input type="text" name="city" required placeholder="e.g. New Delhi" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <div class="mb-4">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Branch Address & PIN Code</label>
                    <input type="text" name="address" required placeholder="e.g. Shop #12, Main Market Road (PIN: 110001)" class="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-blue-500">
                </div>

                <div class="mb-6">
                    <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">
                        <i class="fas fa-camera text-blue-600 mr-1"></i> Upload Shop Verification Image (Proof of Business)
                    </label>
                    <input type="file" name="shop_image" accept="image/*" class="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs outline-none file:mr-4 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-blue-100 file:text-blue-700 hover:file:bg-blue-200">
                    <p class="text-[10px] text-gray-400 mt-1">Or provide image URL directly below if test image file is unavailable:</p>
                    <input type="url" name="shop_image_url" placeholder="https://example.com/shop-photo.jpg" class="w-full mt-1.5 px-3.5 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs outline-none">
                </div>

                <button type="submit" class="w-full py-3.5 px-4 rounded-xl shadow-lg text-sm font-bold text-white bg-emerald-600 hover:bg-emerald-700 focus:outline-none transition-all">
                    Submit Shop Application for Approval
                </button>
            </form>
        </div>

        <!-- ⚡ Development Quick One-Click Login -->
        <div class="mt-8 pt-6 border-t border-gray-100">
            <p class="text-[11px] font-bold uppercase tracking-wider text-gray-400 mb-3 text-center">⚡ Dev Quick 1-Click Role Login</p>
            <div class="grid grid-cols-2 gap-2">
                <button type="button" onclick="quickLogin('ronitgoswami453@gmail.com', 'Password@2426')" class="w-full text-left px-3 py-2 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg hover:border-blue-400 transition text-xs font-medium text-blue-900 flex items-center">
                    <i class="fas fa-crown text-amber-500 mr-2"></i> Super Admin
                </button>

                <button type="button" onclick="quickLogin('subadmin@glamora.com', 'password')" class="w-full text-left px-3 py-2 bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-200 rounded-lg hover:border-purple-400 transition text-xs font-medium text-purple-900 flex items-center">
                    <i class="fas fa-user-shield text-purple-500 mr-2"></i> Subadmin
                </button>

                <button type="button" onclick="quickLogin('owner@glamora.com', 'password')" class="w-full text-left px-3 py-2 bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-lg hover:border-emerald-400 transition text-xs font-medium text-emerald-900 flex items-center">
                    <i class="fas fa-store text-emerald-500 mr-2"></i> Shop Owner
                </button>

                <button type="button" onclick="quickLogin('staff@glamora.com', 'password')" class="w-full text-left px-3 py-2 bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-lg hover:border-amber-400 transition text-xs font-medium text-amber-900 flex items-center">
                    <i class="fas fa-cut text-amber-500 mr-2"></i> Staff / Stylist
                </button>
            </div>

            <div class="mt-2">
                <button type="button" onclick="quickLogin('customer@glamora.com', 'password')" class="w-full text-left px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg hover:border-gray-300 transition text-xs font-medium text-gray-700 flex items-center justify-center">
                    <i class="fas fa-user text-gray-500 mr-2"></i> Customer Demo Account
                </button>
            </div>
        </div>
    </div>

    <script>
        function switchTab(tab) {
            const loginForm = document.getElementById('form-login');
            const custRegisterForm = document.getElementById('form-cust-register');
            const shopRegisterForm = document.getElementById('form-shop-register');
            
            const tabLogin = document.getElementById('tab-login');
            const tabCustRegister = document.getElementById('tab-cust-register');
            const tabShopRegister = document.getElementById('tab-shop-register');

            loginForm.classList.add('hidden');
            custRegisterForm.classList.add('hidden');
            shopRegisterForm.classList.add('hidden');

            tabLogin.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-gray-500 hover:text-gray-900';
            tabCustRegister.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-gray-500 hover:text-gray-900';
            tabShopRegister.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-gray-500 hover:text-gray-900';

            if (tab === 'login') {
                loginForm.classList.remove('hidden');
                tabLogin.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-blue-600 bg-white shadow-sm';
            } else if (tab === 'cust-register') {
                custRegisterForm.classList.remove('hidden');
                tabCustRegister.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-blue-600 bg-white shadow-sm';
            } else {
                shopRegisterForm.classList.remove('hidden');
                tabShopRegister.className = 'flex-1 py-2.5 text-xs font-bold rounded-xl transition text-emerald-700 bg-white shadow-sm';
            }
        }

        function autofetchPincode() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(pos) {
                    document.getElementById('cust_pincode').value = '110001';
                    document.getElementById('cust_city').value = 'New Delhi';
                    alert('Location autofetched! PIN Code set to 110001 (New Delhi).');
                }, function(err) {
                    document.getElementById('cust_pincode').value = '110001';
                    document.getElementById('cust_city').value = 'New Delhi';
                    alert('Default location PIN Code set to 110001 (New Delhi).');
                });
            } else {
                document.getElementById('cust_pincode').value = '110001';
                document.getElementById('cust_city').value = 'New Delhi';
            }
        }

        function quickLogin(email, password) {
            switchTab('login');
            document.getElementById('email').value = email;
            document.getElementById('password').value = password;
            document.getElementById('form-login').querySelector('form').submit();
        }
    </script>
</body>
</html>
