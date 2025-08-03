import 'package:go_router/go_router.dart';
import 'package:kiosk_app/presentation/pages/doctor_status_screen.dart';

import '../../presentation/pages/book_appointment_screen.dart';
import '../../presentation/pages/home_screen.dart';
import '../../presentation/pages/login_screen.dart';
import '../../presentation/pages/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(
        path: '/doctor-status',
        builder: (context, state) => DoctorStatusScreen(),
      ),
      GoRoute(
        path: '/book-appointment',
        builder: (context, state) => BookAppointmentScreen(),
      ),
    ],
  );
}
