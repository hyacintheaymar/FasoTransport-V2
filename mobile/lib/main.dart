import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/passenger/onboarding_screen.dart';
import 'screens/passenger/login_screen.dart';
import 'screens/passenger/home_screen.dart';
import 'screens/passenger/profile_screen.dart';
import 'screens/passenger/trip_screens.dart';
import 'screens/ticket_screen.dart';
import 'screens/agent/agent_screens.dart';
import 'screens/role_selection_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/startup_router_screen.dart';

void main() {
  runApp(const FasoTransportApp());
}

class FasoTransportApp extends StatelessWidget {
  const FasoTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FasoTransport',
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const StartupRouterScreen(),
        '/role': (_) => const RoleSelectionScreen(),
        '/passenger/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/results': (_) => const ResultsScreen(),
        '/seat': (_) => const SeatSelectionScreen(),
        '/payment': (_) => const PaymentScreen(seatNumber: 1),
        '/ticket': (_) => const TicketScreen(),
        '/tickets': (_) => const MyTicketsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/agent/login': (_) => const AgentLoginScreen(),
        '/agent/trips': (_) => const AgentTripsScreen(),
        '/agent/scanner': (_) => const QrScannerScreen(),
        '/chat': (_) => const ChatScreen(),
      },
    );
  }
}
