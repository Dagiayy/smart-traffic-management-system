import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'alerts/alerts_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'payments/payments_screen.dart';
import 'profile/profile_screen.dart';
import 'violations/violations_screen.dart';

/// 5-tab bottom navigation shell as required by UI/UX spec:
/// Dashboard | Violations | Alerts | Payments | Profile
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    ViolationsScreen(),
    AlertsScreen(),
    PaymentsScreen(),
    ProfileScreen(),
  ];

  static const _tabs = <(IconData, IconData, String)>[
    (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    (Icons.fact_check_outlined, Icons.fact_check, 'Violations'),
    (Icons.alt_route_outlined, Icons.alt_route, 'Alerts'),
    (Icons.payments_outlined, Icons.payments, 'Pay'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final isActive = _index == i;
                final tab = _tabs[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? tab.$2 : tab.$1,
                          size: 22,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.gray500,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.$3,
                          style: AppTypography.caption.copyWith(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.gray500,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
