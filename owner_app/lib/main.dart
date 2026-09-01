import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/remote_config.dart';
import 'config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/notifications_inbox_screen.dart';
import 'screens/maintenance_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for WhatsApp-style heads-up status bar notification popups.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Present System Notification in Android Notification Shade / System Tray
void showSystemTrayNotification(String title, String body, {int id = 0, String? payload}) {
  try {
    flutterLocalNotificationsPlugin.show(
      id != 0 ? id : DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for WhatsApp-style heads-up status bar notification popups.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'accept_booking',
              'Accept',
              titleColor: Color(0xFF059669),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'delay_booking',
              'Delay (15m)',
              titleColor: Color(0xFFD97706),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'decline_booking',
              'Decline',
              titleColor: Color(0xFFDC2626),
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: payload,
    );
  } catch (_) {}
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final notification = message.notification;
    if (notification != null) {
      NotificationService().addNotification(
        notification.title ?? 'Push Alert',
        notification.body ?? '',
      );

      // Explicitly present system tray notification banner when app is in background / closed
      final FlutterLocalNotificationsPlugin backgroundPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      await backgroundPlugin.initialize(const InitializationSettings(android: initAndroid));

      await backgroundPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'WhatsApp-style heads-up status bar notification popups',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'accept_booking',
                'Accept',
                titleColor: Color(0xFF059669),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'delay_booking',
                'Delay (15m)',
                titleColor: Color(0xFFD97706),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'decline_booking',
                'Decline',
                titleColor: Color(0xFFDC2626),
                showsUserInterface: true,
              ),
            ],
          ),
        ),
        payload: message.data['booking_id']?.toString(),
      );
    }
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Setup Global Real-Time Maintenance Mode Switcher
  RemoteConfig.onMaintenanceModeChanged = (bool inMaintenance) {
    if (inMaintenance) {
      if (!RemoteConfig.isOnMaintenanceScreen) {
        RemoteConfig.isOnMaintenanceScreen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          rootNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
            (route) => false,
          );
        });
      }
    } else {
      if (RemoteConfig.isOnMaintenanceScreen) {
        RemoteConfig.isOnMaintenanceScreen = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final token = ApiService.authToken;
          rootNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => (token != null && token.isNotEmpty)
                  ? const HomeShell()
                  : const LoginScreen(),
            ),
            (route) => false,
          );
        });
      }
    }
  };

  // 2. Fetch Remote Config & Theme from Server (and poll every 25 seconds for maintenance & dynamic theme)
  await RemoteConfig.fetchConfig();
  Timer.periodic(const Duration(seconds: 25), (_) {
    RemoteConfig.fetchConfig();
  });

  // 2. Global Error Handling to Laravel Crash Monitor
  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/logs/crash'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'error_message': details.exceptionAsString(),
          'stack_trace': details.stack?.toString(),
          'app_version': '1.0.0', // dynamic in real app
          'os_version': Platform.operatingSystemVersion,
          'device_model': Platform.operatingSystem,
          'user_id': ApiService.currentUserId,
          'tenant_id': ApiService.currentTenantId,
        }),
      );
    } catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      http.post(
        Uri.parse('${AppConfig.baseUrl}/logs/crash'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'error_message': error.toString(),
          'stack_trace': stack.toString(),
          'app_version': '1.0.0',
          'os_version': Platform.operatingSystemVersion,
          'device_model': Platform.operatingSystem,
          'user_id': ApiService.currentUserId,
          'tenant_id': ApiService.currentTenantId,
        }),
      );
    } catch (_) {}
    return true;
  };

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Configure Android Heads-Up System Notification Channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.actionId != null && details.payload != null) {
          final bookingId = int.tryParse(details.payload!);
          if (bookingId != null) {
            String action = 'CONFIRM';
            int? delayMins;
            if (details.actionId == 'delay_booking') {
              action = 'DELAY';
              delayMins = 15;
            } else if (details.actionId == 'decline_booking') {
              action = 'DECLINE';
            }

            // Show a loading snackbar
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Processing booking ${details.actionId}...')),
            );

            // Call API
            final result = await ApiService.respondBooking(
              bookingId: bookingId, 
              action: action, 
              delayMinutes: delayMins,
            );
            
            final success = result['success'] == true;
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(success ? 'Booking updated successfully!' : (result['message'] ?? 'Failed to update booking.')),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
        
        // Tap on Local Notification Banner: Navigate to Notifications Inbox
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
        );
      },
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      ApiService.fcmDeviceToken = token;
    }

    // Handle Notification Tap when App opened from Background / Closed state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
      );
    });

    // Listen for foreground push notifications with STRICT SHOP OWNER GUARD & HEADS-UP BANNER
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final data = message.data;

      // 🛑 STRICT SINGLE-OWNER MATCH GUARD:
      final targetUserIdStr = data['target_user_id'];
      final targetTenantIdStr = data['target_tenant_id'] ?? data['shop_id'];

      if (targetUserIdStr != null && ApiService.currentUserId != null) {
        final targetUserId = int.tryParse(targetUserIdStr.toString());
        if (targetUserId != null && targetUserId != ApiService.currentUserId) {
          debugPrint('🛑 FCM DISCARDED: Target User ID ($targetUserId) != Logged-in User (${ApiService.currentUserId})');
          return;
        }
      }

      if (targetTenantIdStr != null && ApiService.currentTenantId != null) {
        final targetTenantId = int.tryParse(targetTenantIdStr.toString());
        if (targetTenantId != null && targetTenantId != 0 && targetTenantId != ApiService.currentTenantId) {
          debugPrint('🛑 FCM DISCARDED: Target Tenant ID ($targetTenantId) != Logged-in Shop (${ApiService.currentTenantId})');
          return;
        }
      }

      if (notification != null) {
        final title = notification.title ?? 'Push Notification Alert';
        final body = notification.body ?? '';

        // Add to local notification service state
        NotificationService().addNotification(title, body);

        // Show WhatsApp-style Heads-up Popup Banner in System Tray / Status Bar
        showSystemTrayNotification(
          title, 
          body, 
          id: notification.hashCode,
          payload: data['booking_id']?.toString(),
        );

        final navContext = rootNavigatorKey.currentContext;
        final isBookingNotification = data['type'] == 'BOOKING_REQUEST' || data['booking_id'] != null;

        if (navContext != null) {
          if (isBookingNotification) {
            _showInteractiveBookingDialog(
              context: navContext,
              title: title,
              body: body,
              data: data,
            );
          } else {
            _showStandardNotificationDialog(
              context: navContext,
              title: title,
              body: body,
            );
          }
        }
      }
    });

  } catch (_) {}

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const OwnerApp());
}

/// Standard Push Alert Pop-up Modal
void _showStandardNotificationDialog({
  required BuildContext context,
  required String title,
  required String body,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4F46E5), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    rootNavigatorKey.currentState?.push(
                      MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
                    );
                  },
                  child: const Text('View Inbox', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Interactive Booking Request Pop-up Modal with Accept, Decline & Shift Time (+20, +30, +40 mins)
void _showInteractiveBookingDialog({
  required BuildContext context,
  required String title,
  required String body,
  required Map<String, dynamic> data,
}) {
  final bookingId = int.tryParse(data['booking_id']?.toString() ?? '0') ?? 0;
  final customerName = data['customer_name'] ?? 'Customer';
  final serviceName = data['service_name'] ?? 'Salon Service';
  final originalTime = data['original_time'] ?? '10:00 AM';
  final amount = data['amount'] ?? '499';

  int selectedDelayMins = 0;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.content_cut_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '💈 New Booking Request',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: $customerName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Service: $serviceName (₹$amount)', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text('Requested Time: $originalTime', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⏱️ Delay / Add Extra Time (Optional):',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [0, 15, 20, 30, 40, 60].map((mins) {
                      final isSelected = selectedDelayMins == mins;
                      return ChoiceChip(
                        label: Text(mins == 0 ? 'On Time' : '+$mins Mins'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF4F46E5),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedDelayMins = mins);
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedDelayMins > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        '✨ Shifted Confirmed Time: $originalTime + $selectedDelayMins mins',
                        style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (bookingId > 0) {
                              final res = await ApiService.respondBooking(bookingId: bookingId, action: 'DECLINE');
                              rootScaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(content: Text(res['message'] ?? 'Booking Declined.')),
                              );
                            }
                          },
                          child: const Text('❌ Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (bookingId > 0) {
                              final res = await ApiService.respondBooking(
                                bookingId: bookingId,
                                action: selectedDelayMins > 0 ? 'ADD_TIME' : 'ACCEPT',
                                delayMinutes: selectedDelayMins,
                              );
                              rootScaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF059669),
                                  content: Text(res['message'] ?? 'Booking Confirmed!'),
                                ),
                              );
                            }
                          },
                          child: Text(
                            selectedDelayMins > 0 ? '✅ Confirm (+$selectedDelayMins m)' : '✅ Accept',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: RemoteConfig.maintenanceNotifier,
      builder: (context, inMaintenance, child) {
        return MaterialApp(
          title: 'Bookify Partner',
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(seedColor: RemoteConfig.primaryColor).copyWith(
              primary: RemoteConfig.primaryColor,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
            textTheme: GoogleFonts.getTextTheme(RemoteConfig.fontFamily).apply(
              bodyColor: const Color(0xFF0F172A),
              displayColor: const Color(0xFF0F172A),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFF8FAFC),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.getTextTheme(RemoteConfig.fontFamily).titleLarge?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: RemoteConfig.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RemoteConfig.buttonRadius)),
                textStyle: GoogleFonts.getTextTheme(RemoteConfig.fontFamily).titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: RemoteConfig.primaryColor, width: 1.5),
              ),
              labelStyle: GoogleFonts.getTextTheme(RemoteConfig.fontFamily).bodyMedium?.copyWith(color: const Color(0xFF64748B)),
              prefixIconColor: const Color(0xFF64748B),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF0F172A),
              contentTextStyle: GoogleFonts.getTextTheme(RemoteConfig.fontFamily).bodyMedium?.copyWith(color: Colors.white),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              behavior: SnackBarBehavior.floating,
            ),
            useMaterial3: true,
          ),
          home: inMaintenance ? const MaintenanceScreen() : const LoginScreen(),
        );
      },
    );
  }
}
