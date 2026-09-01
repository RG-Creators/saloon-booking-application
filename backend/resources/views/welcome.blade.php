<!DOCTYPE html>
<html lang="en" class="scroll-smooth antialiased">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
    <title>Bookify — Next-Gen Salon & Spa SaaS Operating System</title>
    <meta name="description" content="The smartest salon & spa operating system. Real-time booking, multi-staff scheduling, dynamic surge pricing, and effortless customer booking.">
    <meta name="theme-color" content="#0B0F19">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    
    <!-- Preconnect & DNS-Prefetch for lightning-fast asset loading -->
    <link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="dns-prefetch" href="https://cdn.tailwindcss.com">
    <link rel="dns-prefetch" href="https://checkout.razorpay.com">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,400;1,600&family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800;900&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    
    <!-- Razorpay Checkout SDK -->
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['"Poppins"', '"Plus Jakarta Sans"', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
                        display: ['"Plus Jakarta Sans"', '"Poppins"', 'sans-serif'],
                        mono: ['"Space Grotesk"', 'monospace'],
                    },
                    colors: {
                        brand: {
                            50: '#EEF2FF',
                            100: '#E0E7FF',
                            500: '#6366F1',
                            600: '#4F46E5',
                            700: '#4338CA',
                            cyan: '#0EA5E9',
                            teal: '#14B8A6',
                            emerald: '#10B981',
                            slate: '#64748B',
                        }
                    },
                }
            }
        }
    </script>
    
    <style>
        /* Hardware Acceleration & Ultra-Smooth Touch Scroll */
        *, *::before, *::after {
            box-sizing: border-box;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        html {
            scroll-behavior: smooth;
            -webkit-overflow-scrolling: touch;
        }

        body {
            background-color: #0B0F19;
            overflow-x: hidden;
            text-rendering: optimizeSpeed;
        }

        /* Glassmorphism Panels with Mobile-Optimized Blur */
        .glass-panel {
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            transform: translateZ(0);
        }
        .glass-panel-light {
            background: rgba(30, 41, 59, 0.6);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.09);
        }
        .glass-btn {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .glass-btn:hover {
            background: rgba(255, 255, 255, 0.1);
            border-color: rgba(255, 255, 255, 0.2);
        }
        
        .aurora-bg {
            background: radial-gradient(circle at 50% 0%, rgba(79, 70, 229, 0.22) 0%, rgba(14, 165, 233, 0.08) 38%, rgba(11, 15, 25, 1) 75%);
        }
        .glow-indigo {
            box-shadow: 0 8px 30px -8px rgba(99, 102, 241, 0.35);
        }
        .glow-teal {
            box-shadow: 0 8px 30px -8px rgba(20, 184, 166, 0.35);
        }

        .text-gradient {
            background: linear-gradient(135deg, #FFFFFF 20%, #C7D2FE 60%, #7DD3FC 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .text-gradient-teal {
            background: linear-gradient(135deg, #A7F3D0 0%, #34D399 50%, #38BDF8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .text-gradient-lavender {
            background: linear-gradient(135deg, #E0E7FF 0%, #A5B4FC 50%, #C084FC 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .mesh-grid {
            background-size: 32px 32px;
            background-image: linear-gradient(to right, rgba(255, 255, 255, 0.025) 1px, transparent 1px),
                              linear-gradient(to bottom, rgba(255, 255, 255, 0.025) 1px, transparent 1px);
        }

        /* Lightweight 60FPS Scroll Reveal Transitions */
        .reveal-item {
            opacity: 0;
            transform: translate3d(0, 16px, 0);
            transition: opacity 0.5s ease-out, transform 0.5s ease-out;
        }
        .reveal-item.revealed {
            opacity: 1;
            transform: translate3d(0, 0, 0);
        }

        .reveal-scale {
            opacity: 0;
            transform: scale3d(0.97, 0.97, 1) translate3d(0, 12px, 0);
            transition: opacity 0.5s ease-out, transform 0.5s ease-out;
        }
        .reveal-scale.revealed {
            opacity: 1;
            transform: scale3d(1, 1, 1) translate3d(0, 0, 0);
        }

        /* 3D Soft Tilt (Desktop only) */
        @media (hover: hover) and (pointer: fine) {
            .card-tilt {
                transition: transform 0.25s ease, box-shadow 0.25s ease;
            }
            .card-tilt:hover {
                transform: translateY(-3px);
            }
        }

        /* Mobile Specific Blur Reductions to ensure 120Hz smooth scrolling */
        @media (max-width: 768px) {
            .glass-panel, .glass-panel-light, .glass-btn {
                backdrop-filter: none !important;
                -webkit-backdrop-filter: none !important;
                background: rgba(17, 24, 39, 0.92) !important;
            }
            .parallax-layer {
                display: none !important;
            }
        }
    </style>
</head>

<body class="bg-[#0B0F19] text-slate-100 font-sans antialiased selection:bg-indigo-500 selection:text-white">

    <!-- Ambient Glowing Orbs (Desktop Parallax) -->
    <div class="fixed inset-0 pointer-events-none z-0 overflow-hidden hidden md:block">
        <div id="orb1" class="parallax-layer absolute -top-36 left-1/4 w-[500px] h-[500px] bg-indigo-600/15 rounded-full blur-[120px]"></div>
        <div id="orb2" class="parallax-layer absolute top-1/3 -right-40 w-[400px] h-[400px] bg-sky-500/10 rounded-full blur-[110px]"></div>
        <div id="orb3" class="parallax-layer absolute -bottom-20 left-1/3 w-[450px] h-[450px] bg-teal-500/10 rounded-full blur-[120px]"></div>
    </div>

    <!-- Navigation Header -->
    <header class="sticky top-0 z-50 w-full border-b border-white/5 bg-[#0B0F19]/90 backdrop-blur-md transition-all duration-300">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-14 sm:h-16 flex items-center justify-between">
            
            <!-- Brand Logo -->
            <a href="/" class="flex items-center space-x-2.5 group">
                <div class="relative flex items-center justify-center w-8 h-8 sm:w-9 sm:h-9 rounded-xl bg-gradient-to-tr from-indigo-500 via-sky-500 to-teal-400 p-[1px] shadow-md shadow-indigo-500/20 group-hover:scale-105 transition-transform duration-300">
                    <div class="w-full h-full bg-[#0B0F19] rounded-[11px] flex items-center justify-center">
                        <svg class="w-4 h-4 sm:w-5 sm:h-5 text-indigo-300 group-hover:text-sky-300 transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                        </svg>
                    </div>
                </div>
                <div class="flex items-center space-x-1.5">
                    <span class="text-lg sm:text-xl font-black tracking-tight text-white font-mono">Bookify</span>
                    <span class="px-1.5 py-0.2 text-[8px] sm:text-[9px] font-black uppercase tracking-wider bg-indigo-500/20 text-indigo-200 border border-indigo-500/30 rounded-full">SaaS 2.0</span>
                </div>
            </a>

            <!-- Desktop Nav Links -->
            <nav class="hidden md:flex items-center space-x-6 text-xs font-bold text-slate-300">
                <a href="#features" class="hover:text-white transition-colors">Platform Superpowers</a>
                <a href="#apps" class="hover:text-white transition-colors">Our Apps</a>
                <a href="#roadmap" class="hover:text-indigo-300 transition-colors flex items-center space-x-1">
                    <svg class="w-3.5 h-3.5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/></svg>
                    <span>Roadmap</span>
                </a>
                <a href="#contribute" class="hover:text-teal-300 transition-colors flex items-center space-x-1">
                    <svg class="w-3.5 h-3.5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                    <span>Contribute</span>
                </a>
                <a href="#how-it-works" class="hover:text-white transition-colors">How It Works</a>
                <a href="#faq" class="hover:text-white transition-colors">FAQ</a>
            </nav>

            <!-- Action Button -->
            <div class="flex items-center space-x-2.5">
                <a href="#contribute" class="hidden sm:inline-flex items-center px-3 py-1.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-200 text-xs font-bold hover:bg-indigo-500/20 transition">
                    <svg class="w-3.5 h-3.5 mr-1.5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                    Support
                </a>
                <a href="#apps" class="px-3.5 py-1.5 sm:px-4 sm:py-2 rounded-xl bg-gradient-to-r from-indigo-600 to-sky-600 text-white text-xs font-black shadow-md shadow-indigo-600/25 hover:opacity-95 active:scale-95 transition-all flex items-center space-x-1.5">
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                    <span>Get Apps</span>
                </a>
            </div>

        </div>
    </header>

    <!-- HERO SECTION (MOBILE TOP-ALIGNED • DESKTOP SCREEN FIT) -->
    <section class="relative z-10 pt-4 pb-6 sm:py-8 md:min-h-[calc(100vh-4rem)] md:flex md:flex-col md:justify-center aurora-bg mesh-grid">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 text-center flex flex-col justify-center items-center">
            
            <!-- Live Status Badge -->
            <div class="reveal-item inline-flex items-center space-x-2 px-3 py-1 rounded-full glass-panel border-white/10 text-[11px] sm:text-xs font-bold text-indigo-300 mb-3 sm:mb-4 shadow-sm">
                <span class="flex h-2 w-2 relative">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-sky-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-2 w-2 bg-sky-500"></span>
                </span>
                <span>Hyper-Synchronized Cloud Operating System</span>
                <span class="px-1.5 py-0.2 text-[8px] font-black bg-indigo-500/30 text-indigo-200 rounded-full font-mono">v2.0</span>
            </div>

            <!-- Main Headline -->
            <h1 class="reveal-item text-2xl sm:text-4xl md:text-5xl lg:text-6xl font-black tracking-tight leading-[1.14] mb-2.5 sm:mb-3.5 max-w-4xl mx-auto">
                The Smartest OS For <br class="hidden sm:inline">
                <span class="text-gradient">Salons, Stylists & Clients</span>
            </h1>

            <!-- Subtitle -->
            <p class="reveal-item text-xs sm:text-sm md:text-base lg:text-lg text-slate-300 font-normal max-w-2xl mx-auto leading-relaxed mb-5 sm:mb-7">
                Empower salon owners with multi-staff scheduling, live queue slot locking, dynamic surge pricing, and automated customer engagement. Enjoy 0% double-booking and effortless customer checkouts.
            </p>

            <!-- DUAL DOWNLOAD BUTTONS -->
            <div class="reveal-item flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-5 w-full max-w-xl mx-auto mb-5 sm:mb-7">
                
                <!-- 🟣 PARTNER APP BUTTON -->
                <button onclick="openModal('partnerModal')" class="w-full sm:w-1/2 group relative p-[1.5px] rounded-2xl bg-gradient-to-r from-indigo-500 via-indigo-600 to-sky-600 shadow-lg shadow-indigo-600/20 hover:shadow-indigo-500/40 hover:scale-[1.01] active:scale-[0.98] transition-all text-left cursor-pointer">
                    <div class="px-4 py-3 sm:px-5 sm:py-3.5 rounded-[14.5px] bg-[#111827] flex items-center justify-between h-full group-hover:bg-[#151c2e] transition-colors">
                        <div class="flex items-center space-x-3">
                            <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-indigo-500/15 text-indigo-400 flex items-center justify-center text-lg group-hover:bg-indigo-600 group-hover:text-white transition-all shrink-0">
                                <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
                                </svg>
                            </div>
                            <div>
                                <span class="block text-[9px] sm:text-[10px] font-extrabold uppercase tracking-wider text-indigo-300 font-mono">For Owners & Staff</span>
                                <span class="block text-xs sm:text-base font-black text-white leading-tight">Partner App</span>
                            </div>
                        </div>
                        <div class="text-slate-500 group-hover:text-white transition-colors shrink-0">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7"/>
                            </svg>
                        </div>
                    </div>
                </button>

                <!-- 🟢 CUSTOMER APP BUTTON -->
                <button onclick="openModal('customerModal')" class="w-full sm:w-1/2 group relative p-[1.5px] rounded-2xl bg-gradient-to-r from-teal-500 via-emerald-600 to-sky-500 shadow-lg shadow-teal-600/20 hover:shadow-teal-500/40 hover:scale-[1.01] active:scale-[0.98] transition-all text-left cursor-pointer">
                    <div class="px-4 py-3 sm:px-5 sm:py-3.5 rounded-[14.5px] bg-[#111827] flex items-center justify-between h-full group-hover:bg-[#132223] transition-colors">
                        <div class="flex items-center space-x-3">
                            <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-teal-500/15 text-teal-400 flex items-center justify-center text-lg group-hover:bg-teal-600 group-hover:text-white transition-all shrink-0">
                                <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <rect x="5" y="2" width="14" height="20" rx="3" ry="3" stroke-width="2"></rect>
                                    <line x1="12" y1="18" x2="12.01" y2="18" stroke-width="2.5"></line>
                                </svg>
                            </div>
                            <div>
                                <span class="block text-[9px] sm:text-[10px] font-extrabold uppercase tracking-wider text-teal-300 font-mono">For Clients & Guests</span>
                                <span class="block text-xs sm:text-base font-black text-white leading-tight">Customer App</span>
                            </div>
                        </div>
                        <div class="text-slate-500 group-hover:text-white transition-colors shrink-0">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7"/>
                            </svg>
                        </div>
                    </div>
                </button>

            </div>

            <!-- Trust Badges -->
            <div class="reveal-item flex flex-wrap items-center justify-center gap-3 sm:gap-6 text-[11px] sm:text-xs font-semibold text-slate-400 mb-4 sm:mb-6">
                <div class="flex items-center space-x-1.5">
                    <svg class="w-3.5 h-3.5 text-teal-400" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                    </svg>
                    <span>Instant Android APK</span>
                </div>
                <div class="flex items-center space-x-1.5">
                    <svg class="w-3.5 h-3.5 text-indigo-400" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                    </svg>
                    <span>FCM v1 Push Sync</span>
                </div>
                <div class="flex items-center space-x-1.5">
                    <svg class="w-3.5 h-3.5 text-sky-400" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd"></path>
                    </svg>
                    <span>0% Double-Booking</span>
                </div>
            </div>

            <!-- Scroll Cue Indicator -->
            <a href="#apps" class="reveal-item inline-flex flex-col items-center text-[10px] sm:text-[11px] font-bold text-slate-400 hover:text-white transition-colors group">
                <span class="mb-0.5">Explore Bookify</span>
                <svg class="w-3.5 h-3.5 text-indigo-400 group-hover:translate-y-1 transition-transform animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
                </svg>
            </a>

        </div>
    </section>

    <!-- SECTION 1: INTERACTIVE APP PREVIEW TABS -->
    <section id="apps" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            
            <div class="reveal-item text-center max-w-3xl mx-auto mb-8 sm:mb-12">
                <span class="text-xs font-black tracking-widest text-indigo-400 uppercase font-mono">Dedicated Experience For Everyone</span>
                <h2 class="text-xl sm:text-3xl lg:text-4xl font-black text-white mt-1.5">
                    Two Purpose-Built Apps. <br>
                    <span class="text-gradient">One Unified Real-Time Engine.</span>
                </h2>
            </div>

            <!-- Tab Switch Buttons -->
            <div class="reveal-item flex justify-center mb-8 sm:mb-10">
                <div class="p-1.5 rounded-2xl glass-panel flex space-x-2 border-white/10">
                    <button id="tabBtnPartner" onclick="switchAppTab('partner')" class="px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 active:scale-95 flex items-center space-x-2 cursor-pointer">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                        <span>Partner & Staff App</span>
                    </button>
                    <button id="tabBtnCustomer" onclick="switchAppTab('customer')" class="px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all text-slate-400 hover:text-white active:scale-95 flex items-center space-x-2 cursor-pointer">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><rect x="5" y="2" width="14" height="20" rx="3" ry="3" stroke-width="2"></rect><line x1="12" y1="18" x2="12.01" y2="18" stroke-width="2.5"></line></svg>
                        <span>Customer Booking App</span>
                    </button>
                </div>
            </div>

            <!-- Tab 1 Content: Partner App -->
            <div id="tabContentPartner" class="reveal-scale grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-10 items-center">
                <div class="space-y-4 sm:space-y-5 text-left">
                    <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-lg bg-indigo-500/10 text-indigo-300 text-xs font-bold border border-indigo-500/20">
                        <span>For Salon Owners, Managers & Stylists</span>
                    </div>
                    <h3 class="text-xl sm:text-3xl font-black text-white">Full Business Command from the Palm of Your Hand</h3>
                    <p class="text-slate-300 leading-relaxed text-xs sm:text-sm">
                        Eliminate paper registers and confusion. Manage stylist shifts, toggle real-time chair availability, create special combo packages with discounts, and keep salon occupancy at maximum.
                    </p>
                    
                    <ul class="space-y-2.5 text-xs sm:text-sm text-slate-200">
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-indigo-500/20 text-indigo-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Live Queue & Slot Locking:</strong> Reserve 30-min slots with 0% overlap risk.</span>
                        </li>
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-indigo-500/20 text-indigo-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Stylist Commission & Shifts:</strong> Individual stylist accounts and instant customer dialer.</span>
                        </li>
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-indigo-500/20 text-indigo-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Rush Hour Surge Pricing:</strong> Set auto multiplier rules for weekends and peak hours.</span>
                        </li>
                    </ul>

                    <div class="pt-2">
                        <button onclick="openModal('partnerModal')" class="px-5 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-extrabold text-xs sm:text-sm transition shadow-lg shadow-indigo-600/30 flex items-center space-x-2 active:scale-95 cursor-pointer">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                            <span>Download Partner APK</span>
                        </button>
                    </div>
                </div>

                <!-- Partner Preview Mockup Card -->
                <div class="glass-panel p-5 sm:p-7 rounded-3xl border-indigo-500/30 glow-indigo text-left card-tilt">
                    <div class="flex items-center justify-between mb-4 sm:mb-5 pb-3 border-b border-white/10">
                        <div class="text-xs font-mono text-indigo-300 font-bold">BOOKIFY PARTNER EDITION</div>
                        <div class="text-xs font-bold text-teal-400 flex items-center space-x-1.5">
                            <span class="w-2 h-2 rounded-full bg-teal-400 animate-ping"></span>
                            <span>Live Sync</span>
                        </div>
                    </div>
                    <div class="space-y-3">
                        <div class="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
                            <div class="text-xs text-slate-400">Today's Completed Volume</div>
                            <div class="text-xl sm:text-2xl font-black text-white font-mono mt-0.5">₹52,400 <span class="text-xs font-normal text-teal-400">↑ 18% vs yesterday</span></div>
                        </div>
                        <div class="p-3.5 rounded-2xl bg-indigo-950/40 border border-indigo-500/30 flex items-center justify-between">
                            <div>
                                <div class="text-xs font-bold text-white">Vikram S. (Master Stylist)</div>
                                <div class="text-[11px] text-indigo-300">Shift: 10:00 AM - 08:00 PM • 6 Bookings</div>
                            </div>
                            <span class="px-2.5 py-1 text-[10px] font-black rounded-md bg-teal-500/20 text-teal-300">ACTIVE</span>
                        </div>
                        <div class="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800 flex items-center justify-between">
                            <div>
                                <div class="text-xs font-bold text-white">Dynamic Surge Active: Weekend Rush (+15%)</div>
                                <div class="text-[11px] text-slate-400">Applies 04:00 PM - 09:00 PM</div>
                            </div>
                            <span class="text-xs font-bold text-indigo-300 font-mono">Surge 1.15x</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab 2 Content: Customer App (Hidden by default) -->
            <div id="tabContentCustomer" class="hidden grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-10 items-center">
                <div class="space-y-4 sm:space-y-5 text-left">
                    <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-lg bg-teal-500/10 text-teal-300 text-xs font-bold border border-teal-500/20">
                        <span>For Salon Clients & Customers</span>
                    </div>
                    <h3 class="text-xl sm:text-3xl font-black text-white">Book Your Favorite Stylist in Under 30 Seconds</h3>
                    <p class="text-slate-300 leading-relaxed text-xs sm:text-sm">
                        No more waiting in long salon lines or calling multiple times. Discover top-rated salons nearby via GPS, view verified reviews, pick individual stylists, and confirm your preferred time slot instantly.
                    </p>
                    
                    <ul class="space-y-2.5 text-xs sm:text-sm text-slate-200">
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-teal-500/20 text-teal-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Hyperlocal Radius Map:</strong> Search top salons near your GPS location or PIN code.</span>
                        </li>
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-teal-500/20 text-teal-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Direct Stylist Selection:</strong> Choose your favorite barber or stylist profile.</span>
                        </li>
                        <li class="flex items-center space-x-3">
                            <span class="w-5 h-5 rounded-full bg-teal-500/20 text-teal-400 flex items-center justify-center text-xs font-bold shrink-0">✓</span>
                            <span><strong>Instant Ticket & Reminders:</strong> Push alerts before appointment so you never miss a slot.</span>
                        </li>
                    </ul>

                    <div class="pt-2">
                        <button onclick="openModal('customerModal')" class="px-5 py-3 rounded-xl bg-teal-600 hover:bg-teal-500 text-white font-extrabold text-xs sm:text-sm transition shadow-lg shadow-teal-600/30 flex items-center space-x-2 active:scale-95 cursor-pointer">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                            <span>Download Customer APK</span>
                        </button>
                    </div>
                </div>

                <!-- Customer Preview Mockup Card -->
                <div class="glass-panel p-5 sm:p-7 rounded-3xl border-teal-500/30 glow-teal text-left card-tilt">
                    <div class="flex items-center justify-between mb-4 sm:mb-5 pb-3 border-b border-white/10">
                        <div class="text-xs font-mono text-teal-400 font-bold">BOOKIFY CUSTOMER EDITION</div>
                        <div class="text-xs font-bold text-sky-400">Indiranagar (0.8 km)</div>
                    </div>
                    <div class="space-y-3">
                        <div class="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800">
                            <div class="flex items-center justify-between">
                                <h5 class="text-xs font-extrabold text-white">Glamour Lounge & Spa</h5>
                                <span class="text-xs font-bold text-amber-300 font-mono">★ 4.9 (1.2k)</span>
                            </div>
                            <p class="text-[11px] text-slate-400 mt-0.5">Select Services • Hair, Beard, Facial, Massage</p>
                        </div>
                        <div class="p-3.5 rounded-2xl bg-teal-950/40 border border-teal-500/30">
                            <div class="text-xs text-teal-300 font-bold">Confirmed Slot Ticket</div>
                            <div class="text-sm font-black text-white mt-0.5">Saturday, 11:30 AM (Vikram S.)</div>
                            <div class="text-[11px] text-slate-300">Booking ID: #BK-98421 • Reserved Chair</div>
                        </div>
                        <div class="p-3.5 rounded-2xl bg-slate-900/90 border border-slate-800 flex items-center justify-between">
                            <span class="text-xs text-slate-300">Live Status:</span>
                            <span class="text-xs font-bold text-teal-400">Ready for Arrival (No Waiting)</span>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </section>

    <!-- SECTION 2: THE 6 CORE SUPERPOWERS GRID -->
    <section id="features" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]/90 mesh-grid">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            
            <div class="reveal-item text-center max-w-3xl mx-auto mb-10 sm:mb-16">
                <span class="text-xs font-black tracking-widest text-sky-400 uppercase font-mono">Engineered For Performance</span>
                <h2 class="text-xl sm:text-3xl lg:text-4xl font-black text-white mt-1.5">
                    Platform Superpowers Built For <br>
                    <span class="text-gradient">Modern High-Velocity Salons</span>
                </h2>
            </div>

            <!-- 6 Grid Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6 text-left">
                
                <!-- Superpower 1 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-indigo-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-indigo-500/15 text-indigo-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-indigo-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">Real-Time 30-Min Slot Lock</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        Automatic slot collision engine guarantees that when a customer selects a slot, it locks in real-time across all devices with 0% double-booking risk.
                    </p>
                </div>

                <!-- Superpower 2 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-indigo-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-indigo-500/15 text-indigo-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-indigo-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">Multi-Staff & Commission Roster</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        Assign individual staff profiles, set bookable switches, customize shifts, track service commissions, and enable single-tap client dialers.
                    </p>
                </div>

                <!-- Superpower 3 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-sky-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-sky-500/15 text-sky-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-sky-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">Combos & Dynamic Surge Pricing</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        Bundle services into attractive high-margin packages and activate automated peak-hour surge multipliers during high-traffic weekend periods.
                    </p>
                </div>

                <!-- Superpower 4 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-sky-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-sky-500/15 text-sky-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-sky-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">Hyperlocal GPS Discovery</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        Automatic geocoding and PIN code radius engine connects walk-in clients with the nearest open salons in under 2 seconds.
                    </p>
                </div>

                <!-- Superpower 5 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-teal-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-teal-500/15 text-teal-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-teal-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">FCM v1 Push & Offline Sync</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        Instant push notification delivery even when the app is in background, with automatic database queuing for 100% offline catch-up delivery.
                    </p>
                </div>

                <!-- Superpower 6 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 hover:border-teal-500/40 transition-all duration-300 group card-tilt">
                    <div class="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-teal-500/15 text-teal-300 flex items-center justify-center text-xl mb-4 sm:mb-5 group-hover:scale-105 group-hover:bg-teal-600 group-hover:text-white transition-all">
                        <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                        </svg>
                    </div>
                    <h3 class="text-base sm:text-lg font-bold text-white mb-2">Zero Hidden Fees & Clarity</h3>
                    <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">
                        No massive aggregator cuts. Enjoy total financial clarity with real-time audit ledger, dues tracking, and transparent settlement.
                    </p>
                </div>

            </div>

        </div>
    </section>

    <!-- SECTION 3: ROADMAP & PLAYSTORE / APP STORE EXPANSION VISION -->
    <section id="roadmap" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            
            <div class="reveal-item text-center max-w-3xl mx-auto mb-10 sm:mb-16">
                <span class="text-xs font-black tracking-widest text-indigo-300 uppercase font-mono">Future Horizons</span>
                <h2 class="text-xl sm:text-3xl lg:text-4xl font-black text-white mt-1.5">
                    Our Expansion Roadmap & <br>
                    <span class="text-gradient-lavender">Store Release Vision</span>
                </h2>
                <p class="text-xs sm:text-sm text-slate-300 mt-2.5 max-w-2xl mx-auto leading-relaxed">
                    We are building Bookify with relentless precision. As we hit our partner adoption milestones over the next 4 to 5 months, we are scheduled to deploy across all major store ecosystems.
                </p>
            </div>

            <!-- Roadmap Timeline Cards -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5 sm:gap-6 text-left">
                
                <!-- Stage 1 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-teal-500/30 relative card-tilt">
                    <div class="flex items-center justify-between mb-3.5">
                        <span class="px-2.5 py-1 rounded-full text-[10px] font-black bg-teal-500/15 text-teal-300 border border-teal-500/25 font-mono">PHASE 01 • ACTIVE</span>
                        <div class="w-8 h-8 rounded-xl bg-teal-500/15 text-teal-300 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><rect x="5" y="2" width="14" height="20" rx="3" ry="3" stroke-width="2"></rect><line x1="12" y1="18" x2="12.01" y2="18" stroke-width="2.5"></line></svg>
                        </div>
                    </div>
                    <h3 class="text-base sm:text-lg font-black text-white mb-2">Direct APK & Cloud Engine</h3>
                    <p class="text-xs text-slate-300 leading-relaxed mb-3.5">
                        Instant Android APK distribution, real-time slot synchronization, FCM v1 notifications, and multi-staff rosters running live across partner salons.
                    </p>
                    <div class="text-[11px] font-bold text-teal-400 flex items-center space-x-1.5">
                        <span class="w-1.5 h-1.5 rounded-full bg-teal-400"></span>
                        <span>Live & In Production</span>
                    </div>
                </div>

                <!-- Stage 2 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-sky-500/30 relative card-tilt">
                    <div class="flex items-center justify-between mb-3.5">
                        <span class="px-2.5 py-1 rounded-full text-[10px] font-black bg-sky-500/15 text-sky-300 border border-sky-500/25 font-mono">PHASE 02 • MONTHS 4–5</span>
                        <div class="w-8 h-8 rounded-xl bg-sky-500/15 text-sky-300 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                        </div>
                    </div>
                    <h3 class="text-base sm:text-lg font-black text-white mb-2">Official Google Play Store Launch</h3>
                    <p class="text-xs text-slate-300 leading-relaxed mb-3.5">
                        Once adoption milestones and partner feedback are solidified in 4–5 months, Bookify will formally launch on the Google Play Store with automated OTA updates and verified security badges.
                    </p>
                    <div class="text-[11px] font-bold text-sky-300 flex items-center space-x-1.5">
                        <span class="w-1.5 h-1.5 rounded-full bg-sky-300"></span>
                        <span>Scheduled for Month 4–5</span>
                    </div>
                </div>

                <!-- Stage 3 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-indigo-500/30 relative card-tilt">
                    <div class="flex items-center justify-between mb-3.5">
                        <span class="px-2.5 py-1 rounded-full text-[10px] font-black bg-indigo-500/15 text-indigo-300 border border-indigo-500/25 font-mono">PHASE 03 • TARGET</span>
                        <div class="w-8 h-8 rounded-xl bg-indigo-500/15 text-indigo-300 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.85c.65-.8 1.09-1.92.97-3.04-.94.04-2.07.63-2.73 1.4-.58.67-1.1 1.77-.96 2.87 1.05.08 2.07-.43 2.72-1.23z"/>
                            </svg>
                        </div>
                    </div>
                    <h3 class="text-base sm:text-lg font-black text-white mb-2">Native iOS & Apple App Store</h3>
                    <p class="text-xs text-slate-300 leading-relaxed mb-3.5">
                        Dedicated iPhone and iPad editions engineered with Apple Human Interface principles, delivering native iOS booking and salon command to millions of Apple users.
                    </p>
                    <div class="text-[11px] font-bold text-indigo-300 flex items-center space-x-1.5">
                        <span class="w-1.5 h-1.5 rounded-full bg-indigo-300"></span>
                        <span>In Active Architectural Design</span>
                    </div>
                </div>

            </div>

        </div>
    </section>

    <!-- SECTION 4: COMMUNITY CONTRIBUTION / BACKING -->
    <section id="contribute" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]/90 mesh-grid">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
            
            <div class="reveal-item glass-panel p-5 sm:p-10 rounded-3xl border-indigo-500/25 glow-indigo relative overflow-hidden text-left">
                
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 sm:gap-8 items-center">
                    
                    <!-- Left Narrative -->
                    <div class="lg:col-span-6 space-y-3.5 sm:space-y-4">
                        <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-lg bg-indigo-500/10 text-indigo-300 text-xs font-bold border border-indigo-500/20">
                            <svg class="w-3.5 h-3.5 text-indigo-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                            <span>Community Sponsorship & Backing</span>
                        </div>
                        <h2 class="text-xl sm:text-3xl font-black text-white">Back Our Vision & Accelerate The Ecosystem</h2>
                        <p class="text-xs sm:text-sm text-slate-300 leading-relaxed">
                            Bookify is built for real barbers, stylists, and clients with 0% corporate bloat. Your contribution directly funds high-speed cloud infrastructure, Play Store compliance, and native iPhone (iOS) app development.
                        </p>

                        <div class="space-y-2 pt-1 text-xs text-slate-300">
                            <div class="flex items-center space-x-2">
                                <span class="text-teal-400 font-bold">✓</span>
                                <span>100% transparent use of funds towards development</span>
                            </div>
                            <div class="flex items-center space-x-2">
                                <span class="text-teal-400 font-bold">✓</span>
                                <span>Secured via official Razorpay Gateway (UPI, Cards, NetBanking)</span>
                            </div>
                        </div>
                    </div>

                    <!-- Right Interactive Contribution Form -->
                    <div class="lg:col-span-6">
                        <div class="p-5 sm:p-6 rounded-2xl bg-slate-900/90 border border-slate-800 shadow-xl space-y-3.5">
                            
                            <div>
                                <label class="block text-xs font-bold text-slate-300 mb-2">Select Contribution Amount (INR ₹)</label>
                                <div class="grid grid-cols-3 sm:grid-cols-5 gap-2">
                                    <button type="button" onclick="setContributeAmount(100)" class="amount-btn py-2 px-2 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-200 text-xs font-bold hover:border-indigo-400 transition cursor-pointer" data-amt="100">₹100</button>
                                    <button type="button" onclick="setContributeAmount(250)" class="amount-btn py-2 px-2 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-200 text-xs font-bold hover:border-indigo-400 transition cursor-pointer" data-amt="250">₹250</button>
                                    <button type="button" onclick="setContributeAmount(500)" class="amount-btn py-2 px-2 rounded-xl border-indigo-500 bg-indigo-500/20 text-indigo-300 text-xs font-bold hover:border-indigo-400 transition cursor-pointer" data-amt="500">₹500</button>
                                    <button type="button" onclick="setContributeAmount(1000)" class="amount-btn py-2 px-2 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-200 text-xs font-bold hover:border-indigo-400 transition cursor-pointer" data-amt="1000">₹1,000</button>
                                    <button type="button" onclick="setContributeAmount(2500)" class="amount-btn py-2 px-2 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-200 text-xs font-bold hover:border-indigo-400 transition cursor-pointer" data-amt="2500">₹2,500</button>
                                </div>
                            </div>

                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Custom Amount</label>
                                <div class="relative">
                                    <span class="absolute left-3.5 top-2 text-slate-500 font-bold text-sm">₹</span>
                                    <input type="number" id="customAmountInput" value="500" min="1" max="100000" placeholder="Enter custom amount" class="w-full pl-8 pr-4 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white text-sm font-bold font-mono focus:outline-none focus:border-indigo-500 transition">
                                </div>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                <div>
                                    <label class="block text-[11px] font-bold text-slate-400 mb-1">Your Name (Optional)</label>
                                    <input type="text" id="donorName" placeholder="e.g. Rahul Sharma" class="w-full px-3 py-1.5 sm:py-2 rounded-xl bg-slate-950 border border-slate-800 text-white text-xs focus:outline-none focus:border-indigo-500 transition">
                                </div>
                                <div>
                                    <label class="block text-[11px] font-bold text-slate-400 mb-1">Email / Phone (Optional)</label>
                                    <input type="text" id="donorContact" placeholder="For receipt" class="w-full px-3 py-1.5 sm:py-2 rounded-xl bg-slate-950 border border-slate-800 text-white text-xs focus:outline-none focus:border-indigo-500 transition">
                                </div>
                            </div>

                            <div>
                                <label class="block text-[11px] font-bold text-slate-400 mb-1">Encouragement Note (Optional)</label>
                                <input type="text" id="donorNote" placeholder="e.g. Excited for iOS launch! Keep building!" class="w-full px-3 py-1.5 sm:py-2 rounded-xl bg-slate-950 border border-slate-800 text-white text-xs focus:outline-none focus:border-indigo-500 transition">
                            </div>

                            <button type="button" id="payContributeBtn" onclick="initiateContribution()" class="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-indigo-600 via-indigo-500 to-sky-600 hover:from-indigo-500 hover:to-sky-500 text-white font-extrabold text-xs sm:text-sm shadow-lg shadow-indigo-600/25 flex items-center justify-center space-x-2 active:scale-98 transition-all cursor-pointer">
                                <svg class="w-4 h-4 text-indigo-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                                <span>Contribute with Razorpay</span>
                            </button>

                            <div class="flex items-center justify-center space-x-3 text-[10px] text-slate-500 pt-0.5">
                                <span>🔒 256-Bit SSL Encrypted</span>
                                <span>•</span>
                                <span>⚡ Instant UPI & Cards</span>
                            </div>

                        </div>
                    </div>

                </div>

            </div>

        </div>
    </section>

    <!-- SECTION 5: LIVE METRICS & SOCIAL PROOF -->
    <section class="py-12 sm:py-16 relative z-10 border-t border-white/5 bg-[#0B0F19]">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6 text-center">
                
                <div class="reveal-scale glass-panel p-4 sm:p-5 rounded-3xl border-white/5 card-tilt">
                    <div class="text-xl sm:text-3xl lg:text-4xl font-black text-white font-mono text-gradient">50K+</div>
                    <div class="text-[11px] sm:text-xs font-bold text-slate-400 mt-1">Appointments Processed</div>
                </div>

                <div class="reveal-scale glass-panel p-4 sm:p-5 rounded-3xl border-white/5 card-tilt">
                    <div class="text-xl sm:text-3xl lg:text-4xl font-black text-white font-mono text-gradient-teal">1,200+</div>
                    <div class="text-[11px] sm:text-xs font-bold text-slate-400 mt-1">Salon & Stylist Partners</div>
                </div>

                <div class="reveal-scale glass-panel p-4 sm:p-5 rounded-3xl border-white/5 card-tilt">
                    <div class="text-xl sm:text-3xl lg:text-4xl font-black text-sky-300 font-mono">99.9%</div>
                    <div class="text-[11px] sm:text-xs font-bold text-slate-400 mt-1">Cloud Real-time Uptime</div>
                </div>

                <div class="reveal-scale glass-panel p-4 sm:p-5 rounded-3xl border-white/5 card-tilt">
                    <div class="text-xl sm:text-3xl lg:text-4xl font-black text-indigo-300 font-mono">4.9 ★</div>
                    <div class="text-[11px] sm:text-xs font-bold text-slate-400 mt-1">Average App Rating</div>
                </div>

            </div>
        </div>
    </section>

    <!-- SECTION 6: HOW IT WORKS IN 3 STEPS -->
    <section id="how-it-works" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]/80 mesh-grid">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            
            <div class="reveal-item max-w-3xl mx-auto mb-10 sm:mb-16">
                <span class="text-xs font-black tracking-widest text-indigo-400 uppercase font-mono">Simple & Intuitive</span>
                <h2 class="text-xl sm:text-3xl lg:text-4xl font-black text-white mt-1.5">
                    How Bookify Works in <span class="text-gradient">3 Simple Steps</span>
                </h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-5 sm:gap-6 text-left">
                
                <!-- Step 1 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 relative card-tilt">
                    <span class="text-3xl sm:text-4xl font-black text-indigo-500/20 font-mono absolute top-4 sm:top-5 right-4 sm:right-5">01</span>
                    <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-2xl bg-indigo-500/15 text-indigo-300 flex items-center justify-center text-base sm:text-lg font-bold mb-4 sm:mb-5">
                        <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    </div>
                    <h4 class="text-sm sm:text-base font-bold text-white mb-1">Discover Nearby Salons</h4>
                    <p class="text-xs text-slate-400 leading-relaxed">
                        Clients browse nearby top-rated salons, view ratings and reviews, while salon owners set up their catalog in minutes.
                    </p>
                </div>

                <!-- Step 2 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 relative card-tilt">
                    <span class="text-3xl sm:text-4xl font-black text-sky-500/20 font-mono absolute top-4 sm:top-5 right-4 sm:right-5">02</span>
                    <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-2xl bg-sky-500/15 text-sky-300 flex items-center justify-center text-base sm:text-lg font-bold mb-4 sm:mb-5">
                        <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879a3 3 0 11-4.242-4.242L9.757 9.757m0 0L4.879 4.879a3 3 0 10-4.242 4.242l4.242 4.242"/></svg>
                    </div>
                    <h4 class="text-sm sm:text-base font-bold text-white mb-1">Pick Stylist & Combo Deal</h4>
                    <p class="text-xs text-slate-400 leading-relaxed">
                        Select specific stylists, choose catalog services or discounted packages, and select a guaranteed 30-min slot.
                    </p>
                </div>

                <!-- Step 3 -->
                <div class="reveal-item glass-panel p-5 sm:p-7 rounded-3xl border-white/5 relative card-tilt">
                    <span class="text-3xl sm:text-4xl font-black text-teal-500/20 font-mono absolute top-4 sm:top-5 right-4 sm:right-5">03</span>
                    <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-2xl bg-teal-500/15 text-teal-300 flex items-center justify-center text-base sm:text-lg font-bold mb-4 sm:mb-5">
                        <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    </div>
                    <h4 class="text-sm sm:text-base font-bold text-white mb-1">Instant Confirmation & Zero Queue</h4>
                    <p class="text-xs text-slate-400 leading-relaxed">
                        Real-time push alerts confirm the booking. Arrive on time and walk straight to your reserved chair with zero waiting!
                    </p>
                </div>

            </div>

        </div>
    </section>

    <!-- SECTION 7: FAQ ACCORDION -->
    <section id="faq" class="py-14 sm:py-20 relative z-10 border-t border-white/5 bg-[#0B0F19]">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            
            <div class="reveal-item mb-10 sm:mb-14">
                <span class="text-xs font-black tracking-widest text-indigo-400 uppercase font-mono">Answers to Common Inquiries</span>
                <h2 class="text-xl sm:text-3xl lg:text-4xl font-black text-white mt-1.5">Frequently Asked Questions</h2>
            </div>

            <div class="space-y-3 text-left">
                
                <details class="reveal-item glass-panel p-4 sm:p-5 rounded-2xl border-white/10 group cursor-pointer">
                    <summary class="font-bold text-white text-xs sm:text-sm md:text-base flex items-center justify-between list-none">
                        <span>When will Bookify be available on Google Play Store & Apple App Store?</span>
                        <span class="text-indigo-400 group-open:rotate-180 transition-transform duration-200">▼</span>
                    </summary>
                    <p class="text-xs sm:text-sm text-slate-300 mt-2.5 leading-relaxed">
                        After our initial 4 to 5 month rollout and ecosystem stability phase, we will officially publish both Partner and Customer applications to Google Play Store and release the native iOS app on the Apple App Store.
                    </p>
                </details>

                <details class="reveal-item glass-panel p-4 sm:p-5 rounded-2xl border-white/10 group cursor-pointer">
                    <summary class="font-bold text-white text-xs sm:text-sm md:text-base flex items-center justify-between list-none">
                        <span>How does the Partner App help my salon increase revenue?</span>
                        <span class="text-indigo-400 group-open:rotate-180 transition-transform duration-200">▼</span>
                    </summary>
                    <p class="text-xs sm:text-sm text-slate-300 mt-2.5 leading-relaxed">
                        Bookify eliminates walk-in queue chaos by filling idle chair slots during non-peak hours and allowing you to activate weekend surge multipliers. Owners report an average 34% increase in monthly appointment volume.
                    </p>
                </details>

                <details class="reveal-item glass-panel p-4 sm:p-5 rounded-2xl border-white/10 group cursor-pointer">
                    <summary class="font-bold text-white text-xs sm:text-sm md:text-base flex items-center justify-between list-none">
                        <span>How fast can a salon get onboarded?</span>
                        <span class="text-indigo-400 group-open:rotate-180 transition-transform duration-200">▼</span>
                    </summary>
                    <p class="text-xs sm:text-sm text-slate-300 mt-2.5 leading-relaxed">
                        Download the Partner APK, enter your salon branch details and mobile number, add your stylists and services, and your salon is live and bookable in under 5 minutes.
                    </p>
                </details>

            </div>

        </div>
    </section>

    <!-- FOOTER -->
    <footer class="border-t border-white/5 py-8 sm:py-10 relative z-10 bg-[#070A11] text-slate-400 text-xs">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row items-center justify-between gap-5">
            
            <div class="flex items-center space-x-2.5">
                <div class="w-7 h-7 rounded-xl bg-gradient-to-tr from-indigo-500 via-sky-500 to-teal-400 flex items-center justify-center text-white font-mono font-bold text-xs">
                    BK
                </div>
                <div>
                    <span class="text-xs sm:text-sm font-extrabold text-white">Bookify Ecosystem</span>
                    <span class="block text-[10px] sm:text-[11px] text-slate-500">© 2026 Bookify Cloud OS. All rights reserved.</span>
                </div>
            </div>

            <div class="flex flex-wrap items-center gap-4 sm:gap-6 font-semibold text-[11px] sm:text-xs">
                <a href="#features" class="hover:text-white transition">Platform Superpowers</a>
                <a href="#apps" class="hover:text-white transition">Download Apps</a>
                <a href="#roadmap" class="hover:text-indigo-300 transition">Roadmap</a>
                <a href="#contribute" class="hover:text-teal-300 transition">Contribute</a>
                <a href="#faq" class="hover:text-white transition">FAQ</a>
            </div>

        </div>
    </footer>

    <!-- MODAL: PARTNER APP DOWNLOAD -->
    <div id="partnerModal" class="fixed inset-0 z-50 hidden bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
        <div class="glass-panel max-w-md w-full p-5 sm:p-7 rounded-3xl border-indigo-500/40 relative glow-indigo text-left">
            <button onclick="closeModal('partnerModal')" class="absolute top-4 right-4 text-slate-400 hover:text-white text-xl p-1">✕</button>
            
            <div class="flex items-center space-x-3 mb-4">
                <div class="w-10 h-10 rounded-2xl bg-indigo-500/15 text-indigo-300 flex items-center justify-center text-lg">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                </div>
                <div>
                    <h3 class="text-sm sm:text-base font-black text-white">Bookify Partner App</h3>
                    <span class="text-[11px] text-indigo-300">Android APK Edition (v2.0.0)</span>
                </div>
            </div>

            <p class="text-xs text-slate-300 leading-relaxed mb-4">
                Manage your salon, stylists, shifts, combos, and live appointments directly from your Android phone or tablet.
            </p>

            <div class="space-y-2.5">
                <a href="/downloads/bookify-partner.apk" download class="w-full py-2.5 sm:py-3 px-4 rounded-xl bg-gradient-to-r from-indigo-600 to-sky-600 hover:from-indigo-500 hover:to-sky-500 text-white font-extrabold text-xs sm:text-sm flex items-center justify-center space-x-2 shadow-lg shadow-indigo-600/30 transition">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                    <span>Download Partner APK (Direct)</span>
                </a>
            </div>

            <div class="mt-4 pt-3 border-t border-white/10 text-center text-[11px] text-slate-400">
                Requires Android 8.0 or newer • Instant 1-tap install
            </div>
        </div>
    </div>

    <!-- MODAL: CUSTOMER APP DOWNLOAD -->
    <div id="customerModal" class="fixed inset-0 z-50 hidden bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
        <div class="glass-panel max-w-md w-full p-5 sm:p-7 rounded-3xl border-teal-500/40 relative glow-teal text-left">
            <button onclick="closeModal('customerModal')" class="absolute top-4 right-4 text-slate-400 hover:text-white text-xl p-1">✕</button>
            
            <div class="flex items-center space-x-3 mb-4">
                <div class="w-10 h-10 rounded-2xl bg-teal-500/15 text-teal-300 flex items-center justify-center text-lg">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><rect x="5" y="2" width="14" height="20" rx="3" ry="3" stroke-width="2"></rect><line x1="12" y1="18" x2="12.01" y2="18" stroke-width="2.5"></line></svg>
                </div>
                <div>
                    <h3 class="text-sm sm:text-base font-black text-white">Bookify Customer App</h3>
                    <span class="text-[11px] text-teal-300">Android APK Edition (v2.0.0)</span>
                </div>
            </div>

            <p class="text-xs text-slate-300 leading-relaxed mb-4">
                Book top-rated salons, view live available stylist slots, and enjoy queue-free grooming with real-time push reminders.
            </p>

            <div class="space-y-2.5">
                <a href="/downloads/bookify-customer.apk" download class="w-full py-2.5 sm:py-3 px-4 rounded-xl bg-gradient-to-r from-teal-600 to-sky-600 hover:from-teal-500 hover:to-sky-500 text-white font-extrabold text-xs sm:text-sm flex items-center justify-center space-x-2 shadow-lg shadow-teal-600/30 transition">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                    <span>Download Customer APK (Direct)</span>
                </a>
            </div>

            <div class="mt-4 pt-3 border-t border-white/10 text-center text-[11px] text-slate-400">
                Requires Android 8.0 or newer • Zero ads • 100% Free
            </div>
        </div>
    </div>

    <!-- MODAL: CONTRIBUTION SUCCESS -->
    <div id="successModal" class="fixed inset-0 z-50 hidden bg-black/85 backdrop-blur-sm flex items-center justify-center p-4">
        <div class="glass-panel max-w-md w-full p-6 sm:p-8 rounded-3xl border-indigo-500/40 relative glow-indigo text-center">
            <div class="w-14 h-14 rounded-3xl bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 flex items-center justify-center text-xl mx-auto mb-3.5 shadow-lg shadow-indigo-500/20">
                <svg class="w-7 h-7 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
            </div>
            <h3 class="text-lg sm:text-xl font-black text-white">Thank You For Sponsoring!</h3>
            <p id="successMessage" class="text-xs text-slate-300 mt-2 leading-relaxed">
                Your support directly fuels the Play Store release and native iOS development for the Bookify ecosystem.
            </p>
            <div class="mt-5 pt-3.5 border-t border-white/10">
                <button onclick="closeModal('successModal')" class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-black text-xs transition cursor-pointer">
                    Close & Continue
                </button>
            </div>
        </div>
    </div>

    <!-- HIGH PERFORMANCE LIGHTWEIGHT SCRIPT ENGINE -->
    <script>
        // High-Performance Single-Pass IntersectionObserver
        document.addEventListener('DOMContentLoaded', () => {
            const revealElements = document.querySelectorAll('.reveal-item, .reveal-scale');
            
            const observerOptions = {
                root: null,
                rootMargin: '0px 0px -20px 0px',
                threshold: 0.08
            };

            const observer = new IntersectionObserver((entries, observerInstance) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('revealed');
                        observerInstance.unobserve(entry.target); // Unobserve once revealed for 0 runtime overhead
                    }
                });
            }, observerOptions);

            revealElements.forEach(el => observer.observe(el));

            // Desktop-Only Mouse Movement Parallax (Disabled on touch devices for 120FPS native scroll)
            const isDesktop = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
            if (isDesktop) {
                let ticking = false;
                let mouseX = 0, mouseY = 0;
                const orb1 = document.getElementById('orb1');
                const orb2 = document.getElementById('orb2');
                const orb3 = document.getElementById('orb3');

                function updateParallax() {
                    const mOffset1 = mouseX * 0.02;
                    const mOffset2 = mouseY * 0.02;

                    if (orb1) orb1.style.transform = `translate3d(${mOffset1}px, ${mOffset2}px, 0)`;
                    if (orb2) orb2.style.transform = `translate3d(${-mOffset1}px, ${-mOffset2}px, 0)`;
                    if (orb3) orb3.style.transform = `translate3d(${mOffset1 * 0.5}px, ${mOffset2 * 0.5}px, 0)`;

                    ticking = false;
                }

                window.addEventListener('mousemove', (e) => {
                    mouseX = (e.clientX - window.innerWidth / 2);
                    mouseY = (e.clientY - window.innerHeight / 2);
                    if (!ticking) {
                        window.requestAnimationFrame(updateParallax);
                        ticking = true;
                    }
                }, { passive: true });
            }
        });

        // Tab Switching
        function switchAppTab(tab) {
            const partnerBtn = document.getElementById('tabBtnPartner');
            const customerBtn = document.getElementById('tabBtnCustomer');
            const partnerContent = document.getElementById('tabContentPartner');
            const customerContent = document.getElementById('tabContentCustomer');

            if (tab === 'partner') {
                partnerBtn.className = 'px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 active:scale-95 flex items-center space-x-2 cursor-pointer';
                customerBtn.className = 'px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all text-slate-400 hover:text-white active:scale-95 flex items-center space-x-2 cursor-pointer';
                partnerContent.classList.remove('hidden');
                partnerContent.classList.add('grid');
                customerContent.classList.add('hidden');
                customerContent.classList.remove('grid');
                partnerContent.classList.add('revealed');
            } else {
                customerBtn.className = 'px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all bg-teal-600 text-white shadow-lg shadow-teal-600/30 active:scale-95 flex items-center space-x-2 cursor-pointer';
                partnerBtn.className = 'px-4 py-2 sm:px-5 sm:py-2.5 rounded-xl font-extrabold text-xs sm:text-sm transition-all text-slate-400 hover:text-white active:scale-95 flex items-center space-x-2 cursor-pointer';
                customerContent.classList.remove('hidden');
                customerContent.classList.add('grid');
                partnerContent.classList.add('hidden');
                partnerContent.classList.remove('grid');
                customerContent.classList.add('revealed');
            }
        }

        // Contribution Amount Handler
        function setContributeAmount(amt) {
            document.getElementById('customAmountInput').value = amt;
            document.querySelectorAll('.amount-btn').forEach(btn => {
                if (btn.getAttribute('data-amt') == amt) {
                    btn.className = 'amount-btn py-2 px-2 rounded-xl border-indigo-500 bg-indigo-500/20 text-indigo-300 text-xs font-bold hover:border-indigo-400 transition cursor-pointer';
                } else {
                    btn.className = 'amount-btn py-2 px-2 rounded-xl border border-slate-700 bg-slate-800/80 text-slate-200 text-xs font-bold hover:border-indigo-400 transition cursor-pointer';
                }
            });
        }

        // Razorpay Contribution Trigger
        async function initiateContribution() {
            const amount = parseFloat(document.getElementById('customAmountInput').value);
            const name = document.getElementById('donorName').value;
            const contact = document.getElementById('donorContact').value;
            const note = document.getElementById('donorNote').value;
            const btn = document.getElementById('payContributeBtn');

            if (!amount || amount < 1) {
                alert('Please enter a valid contribution amount of at least ₹1.');
                return;
            }

            btn.disabled = true;
            btn.innerHTML = `<span>Processing...</span>`;

            try {
                const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
                const res = await fetch('/contribute/create-order', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        amount: amount,
                        name: name,
                        email: contact,
                        note: note
                    })
                });

                const data = await res.json();

                if (!data.success) {
                    alert('Unable to initialize payment. Please try again.');
                    btn.disabled = false;
                    btn.innerHTML = `<span>Contribute with Razorpay</span>`;
                    return;
                }

                // Initialize Razorpay Popup
                const options = {
                    key: data.key,
                    amount: data.amount,
                    currency: data.currency || 'INR',
                    name: 'Bookify Ecosystem Backing',
                    description: 'Community contribution for Play Store & iOS App development',
                    image: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                    order_id: data.order_id.startsWith('order_mock_') ? undefined : data.order_id,
                    handler: async function (response) {
                        const verifyRes = await fetch('/contribute/verify', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': csrfToken,
                                'Accept': 'application/json'
                            },
                            body: JSON.stringify({
                                razorpay_payment_id: response.razorpay_payment_id,
                                razorpay_order_id: response.razorpay_order_id || data.order_id,
                                razorpay_signature: response.razorpay_signature,
                                amount: amount,
                                name: name,
                                email: contact,
                                note: note
                            })
                        });

                        const verifyData = await verifyRes.json();
                        openModal('successModal');
                        btn.disabled = false;
                        btn.innerHTML = `<span>Contribute with Razorpay</span>`;
                    },
                    prefill: {
                        name: name || '',
                        email: contact.includes('@') ? contact : '',
                        contact: !contact.includes('@') ? contact : ''
                    },
                    theme: {
                        color: '#6366F1'
                    },
                    modal: {
                        ondismiss: function() {
                            btn.disabled = false;
                            btn.innerHTML = `<span>Contribute with Razorpay</span>`;
                        }
                    }
                };

                const rzp = new Razorpay(options);
                rzp.on('payment.failed', function (response) {
                    alert('Payment could not be completed: ' + response.error.description);
                    btn.disabled = false;
                    btn.innerHTML = `<span>Contribute with Razorpay</span>`;
                });
                rzp.open();

            } catch (err) {
                console.error(err);
                alert('An error occurred. Please check your network connection.');
                btn.disabled = false;
                btn.innerHTML = `<span>Contribute with Razorpay</span>`;
            }
        }

        // Modal Controls
        function openModal(id) {
            const modal = document.getElementById(id);
            if (modal) {
                modal.classList.remove('hidden');
                document.body.style.overflow = 'hidden';
            }
        }

        function closeModal(id) {
            const modal = document.getElementById(id);
            if (modal) {
                modal.classList.add('hidden');
                document.body.style.overflow = 'auto';
            }
        }

        window.onclick = function(event) {
            if (event.target.id === 'partnerModal') closeModal('partnerModal');
            if (event.target.id === 'customerModal') closeModal('customerModal');
            if (event.target.id === 'successModal') closeModal('successModal');
        }
    </script>

</body>
</html>
