import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import 'core/constants/app_routers.dart';
import 'core/utils/app_theme.dart';
import 'presentation/bloc/appointment/appointment_blocs.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/doctor status/doctor_status_bloc.dart';
import 'presentation/bloc/theme/theme_blocs.dart';
import 'presentation/bloc/theme/theme_state.dart';

import 'data/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  // Initialize Firebase services
  await FirebaseService().initialize();

  // Lock device orientation for kiosk
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hide system UI for kiosk mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(KioskApp());
}

// Platform Channel Integration for Kiosk Mode
class KioskChannel {
  static const _channel = MethodChannel('com.kiosk/native');

  // Enable kiosk mode
  static Future<bool> enableKioskMode() async {
    try {
      final result = await _channel.invokeMethod('enableKioskMode');

      // Log to Firebase
      await FirebaseService().logUserSession(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
      );

      return result ?? false;
    } catch (e) {
      print('Error enabling kiosk mode: $e');
      return false;
    }
  }

  // Disable kiosk mode
  static Future<bool> disableKioskMode() async {
    try {
      final result = await _channel.invokeMethod('disableKioskMode');
      return result ?? false;
    } catch (e) {
      print('Error disabling kiosk mode: $e');
      return false;
    }
  }

  // Check if device admin is active
  static Future<bool> checkDeviceAdmin() async {
    try {
      final result = await _channel.invokeMethod('checkDeviceAdmin');
      return result ?? false;
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  // Request device admin permission
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      print('Error requesting device admin: $e');
    }
  }
}

class KioskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => DoctorStatusBloc()),
        BlocProvider(create: (context) => AppointmentBloc()),
        BlocProvider(create: (context) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Telemedicine Kiosk',
            theme: themeState.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
