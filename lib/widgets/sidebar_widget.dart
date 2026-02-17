import 'package:flutter/material.dart';
import '../models/nav_item.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

class SidebarWidget extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const SidebarWidget({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  final List<NavItem> navItems = [
    NavItem(title: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
    NavItem(title: 'Expense', icon: Icons.home_outlined, route: '/expense'),
    NavItem(title: 'Income', icon: Icons.bar_chart, route: '/income'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Collapsed sidebar when screen width is
    final isCollapsed = screenWidth >= 600 && screenWidth <= 1199;
    final sidebarWidth = isCollapsed ? 70.0 : 220.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCollapsed ? 16 : 0,
              horizontal: isCollapsed ? 8 : 16,
            ),
            child: Image.asset(
              'assets/images/Logo.png',
              width: 138,
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive = widget.currentRoute == item.route;

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 8 : 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.lightOrange : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Tooltip(
                    message: isCollapsed ? item.title : '',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isCollapsed ? 16 : 16,
                        vertical: isCollapsed ? 8 : 0,
                      ),
                      leading: Icon(
                        item.icon,
                        size: 20,
                        color: isActive
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary,
                      ),
                      title: isCollapsed
                          ? null
                          : Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive
                              ? AppColors.primaryOrange
                              : AppColors.textSecondary,
                          fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () => widget.onNavigate(item.route),
                    ),
                  ),
                );
              },
            ),
          ),

          // Help Section
          if (!isCollapsed)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact +92 335 6543330',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}