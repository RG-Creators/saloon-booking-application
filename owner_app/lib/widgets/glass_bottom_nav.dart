import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded),          // Home (Windows Grid icon)
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded),  // Schedule
    _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded),           // Staff
    _NavItem(icon: Icons.spa_outlined, activeIcon: Icons.spa_rounded),                      // Services
    _NavItem(icon: Icons.widgets_outlined, activeIcon: Icons.widgets_rounded),                // Hub
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 4 : 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: currentIndex.toDouble(), end: currentIndex.toDouble()),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            builder: (context, animIndex, child) {
              return SizedBox(
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: _CurvedNotchClipper(
                      animatedIndex: animIndex,
                      totalItems: _items.length,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: List.generate(_items.length, (i) {
                            final isActive = i == currentIndex;
                            final item = _items[i];

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => onTap(i),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: AnimatedScale(
                                    scale: isActive ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      isActive ? item.activeIcon : item.icon,
                                      size: 24,
                                      color: isActive
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
  });
}

class _CurvedNotchClipper extends CustomClipper<Path> {
  final double animatedIndex;
  final int totalItems;

  _CurvedNotchClipper({
    required this.animatedIndex,
    required this.totalItems,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final itemWidth = w / totalItems;
    final cx = (itemWidth * animatedIndex) + (itemWidth / 2);

    final path = Path();
    const cornerR = 28.0;
    const dipRadius = 24.0;
    const dipDepth = 14.0;

    // Top Left
    path.moveTo(cornerR, 0);

    // Line to dip left
    path.lineTo(cx - dipRadius, 0);

    // Concave U-dip curve
    path.cubicTo(
      cx - (dipRadius * 0.5), 0,
      cx - (dipRadius * 0.4), dipDepth,
      cx, dipDepth,
    );
    path.cubicTo(
      cx + (dipRadius * 0.4), dipDepth,
      cx + (dipRadius * 0.5), 0,
      cx + dipRadius, 0,
    );

    // Line to top right
    path.lineTo(w - cornerR, 0);
    path.quadraticBezierTo(w, 0, w, cornerR);

    // Right edge
    path.lineTo(w, h - cornerR);
    path.quadraticBezierTo(w, h, w - cornerR, h);

    // Bottom edge
    path.lineTo(cornerR, h);
    path.quadraticBezierTo(0, h, 0, h - cornerR);

    // Left edge
    path.lineTo(0, cornerR);
    path.quadraticBezierTo(0, 0, cornerR, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_CurvedNotchClipper oldClipper) {
    return oldClipper.animatedIndex != animatedIndex;
  }
}
