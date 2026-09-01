import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/customer_shell.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for appointment reminders and booking update banners.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

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
          channelDescription: 'This channel is used for appointment reminders and booking update banners.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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
        notification.title ?? 'Booking Update',
        notification.body ?? '',
        data: message.data,
      );
      showSystemTrayNotification(
        notification.title ?? 'Booking Update',
        notification.body ?? '',
      );
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    messaging.getToken().then((token) {
      if (token != null) {
        ApiService.updateFcmToken(token);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService().addNotification(
          notification.title ?? 'Booking Update',
          notification.body ?? '',
          data: message.data,
        );
        showSystemTrayNotification(
          notification.title ?? 'Booking Update',
          notification.body ?? '',
        );
      }
    });
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final isLoggedIn = await ApiService.loadSavedSession();

  runApp(CustomerApp(isLoggedIn: isLoggedIn));
}

class CustomerApp extends StatelessWidget {
  final bool isLoggedIn;

  const CustomerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: isLoggedIn ? const CustomerShell() : const LoginScreen(),
    );
  }
}
