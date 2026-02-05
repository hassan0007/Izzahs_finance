import 'package:flutter/material.dart';
import '../models/nav_item.dart';
import '../utils/colors.dart';

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
    NavItem(title: 'Sales', icon: Icons.home_outlined, route: '/sales'),
    NavItem(title: 'Reports', icon: Icons.bar_chart, route: '/reports'),
    NavItem(title: 'Tracking', icon: Icons.location_on_outlined, route: '/tracking'),
    NavItem(title: 'Staff', icon: Icons.people_outline, route: '/staff'),
    NavItem(title: 'Inventory', icon: Icons.inventory_2_outlined, route: '/inventory'),
    NavItem(title: 'Promo Codes', icon: Icons.local_offer_outlined, route: '/promo-codes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.white,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'i',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "izzah's",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'COLLECTION',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive = widget.currentRoute == item.route;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.lightOrange : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      item.icon,
                      size: 20,
                      color: isActive ? AppColors.primaryOrange : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? AppColors.primaryOrange : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () => widget.onNavigate(item.route),
                  ),
                );
              },
            ),
          ),
          
          // Help Section
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
