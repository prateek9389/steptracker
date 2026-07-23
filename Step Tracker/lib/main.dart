import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/permissions/permissions_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/profile_setup/edit_profile_screen.dart';
import 'screens/dashboard/dashboard_shell.dart';
import 'screens/walk/live_tracking_screen.dart';
import 'screens/dashboard/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/background_task_service.dart';


import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('GEMINI_API_KEY', dotenv.env['GEMINI_API_KEY'] ?? '');

  // Initialize background tasks and notifications
  await NotificationService().initialize();
  await BackgroundTaskService().initialize();
  // Register background tasks
  await BackgroundTaskService().registerStepReminderTask();
  await BackgroundTaskService().registerRewardNotificationTask();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    const ProviderScope(
      child: StrideAIApp(),
    ),
  );
}

class StrideAIApp extends ConsumerWidget {
  const StrideAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Step Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/dashboard': (context) => const DashboardShell(),
        '/live-tracking': (context) => const LiveTrackingScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
