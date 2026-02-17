import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/sidebar_widget.dart';
import '../screens/income_page.dart';
import '../screens/expense_page.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.currentRoute;
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });
    // Close drawer on mobile after navigation
    if (ResponsiveUtils.isMobile(context)) {
      Navigator.of(context).pop();
    }
  }

  Widget _getPageForRoute() {
    switch (_currentRoute) {
      case '/income':
        return const IncomePage();
      case '/expense':
        return const ExpensePage();
      case '/dashboard':
      default:
        return widget.child;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundColor,
      // Drawer for mobile
      drawer: isMobile
          ? Drawer(
        child: SidebarWidget(
          currentRoute: _currentRoute,
          onNavigate: _handleNavigation,
        ),
      )
          : null,
      body: Row(
        children: [
          // Sidebar for tablet and desktop
          if (!isMobile)
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
                  height: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 60.0,
                    desktop: 70.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveValue(
                      context: context,
                      mobile: 16.0,
                      tablet: 24.0,
                      desktop: 32.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Menu button for mobile
                            if (isMobile)
                              IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                            if (isMobile) const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Welcome back, ${widget.userName}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    16,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile)
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {},
                            ),
                          if (!isMobile) const SizedBox(width: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 16 : 18,
                                backgroundColor: AppColors.primaryOrange,
                                child: Text(
                                  widget.userName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                              if (!isMobile) const SizedBox(width: 8),
                              if (!isMobile)
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
                                    Text(
                                      user?.email ?? 'Admin',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              PopupMenuButton<String>(
                                color: Colors.white,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary,
                                  size: isMobile ? 18 : 20,
                                ),
                                offset: const Offset(0, 50),
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _handleLogout(context);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Area (dynamically rendered based on route)
                Expanded(
                  child: _getPageForRoute(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}