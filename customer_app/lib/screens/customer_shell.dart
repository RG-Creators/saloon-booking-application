import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'notifications_inbox_screen.dart';
import 'customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;
  Timer? _notificationPollTimer;
  final _notificationService = NotificationService();

  final List<Widget> _pages = const [
    HomeScreen(),
    MyBookingsScreen(),
    NotificationsInboxScreen(),
    CustomerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onServiceUpdate);
    ApiService.fetchNotifications();
    // Sync notifications every 30 seconds
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ApiService.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    _notificationService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notificationService.unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFEEF2FF),
            elevation: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF4F46E5)),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF4F46E5)),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  backgroundColor: const Color(0xFF4F46E5),
                  child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  backgroundColor: const Color(0xFF4F46E5),
                  child: const Icon(Icons.notifications_rounded, color: Color(0xFF4F46E5)),
                ),
                label: 'Inbox',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF4F46E5)),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
