import 'package:flutter/material.dart';
import 'screens/dashboard_home.dart';
import 'widgets/dashboard_shell.dart';
import 'utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Izzah's Collection Dashboard",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const DashboardShell(
        userName: 'Hassan',
        currentRoute: '/dashboard',
        child: DashboardHome(),
      ),
    );
  }
}
