import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello/firebase_options.dart';
import 'screens/auth/login.dart';
import 'screens/dashboard_home.dart';
import 'widgets/dashboard_shell.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your custom button color
    const Color customButtonColor = Color(0xFFFF6B35); // This is the color 0xFFFF6B35

    return MaterialApp(
      title: "Izc Finance",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(customButtonColor),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // This is where you define the global "box shadow" for cards
        cardTheme: CardThemeData(
          elevation: 5, // Controls the intensity and spread of the shadow
          shadowColor: Colors.black.withOpacity(0.2), // Controls the color of the shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          );
        }

        // If user is logged in, show dashboard with user info
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

          return DashboardShell(
            userName: userName,
            currentRoute: '/dashboard',
            child: const DashboardHome(),
          );
        }

        // Otherwise, show login page
        return const LoginPage();
      },
    );
  }
}