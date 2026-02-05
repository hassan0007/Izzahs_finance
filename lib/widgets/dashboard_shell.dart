import 'package:flutter/material.dart';
import '../widgets/sidebar_widget.dart';
import '../utils/colors.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  final String userName;
  final String currentRoute;

  const DashboardShell({
    super.key,
    required this.child,
    required this.userName,
    this.currentRoute = '/dashboard',
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  String _currentRoute = '/dashboard';

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.currentRoute;
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });
    // In a real app, you would navigate to the actual route here
    // Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Row(
        children: [
          // Sidebar
          SidebarWidget(
            currentRoute: _currentRoute,
            onNavigate: _handleNavigation,
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // App Bar
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome back, ${widget.userName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryOrange,
                                child: Text(
                                  widget.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content Area (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: widget.child,
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
