import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/budgets/budget_history_screen.dart';
import '../../screens/forecast/forecast_screen.dart';
import '../../screens/alerts/alerts_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String budgetHistory = '/budget-history';
  static const String forecast = '/forecast';
  static const String alerts = '/alerts';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        main: (context) => const MainScreen(),
        budgetHistory: (context) => const BudgetHistoryScreen(),
        forecast: (context) => const ForecastScreen(),
        alerts: (context) => const AlertsScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case budgetHistory:
        return MaterialPageRoute(
          builder: (context) => const BudgetHistoryScreen(),
          settings: settings,
        );
      case forecast:
        return MaterialPageRoute(
          builder: (context) => const ForecastScreen(),
          settings: settings,
        );
      case alerts:
        return MaterialPageRoute(
          builder: (context) => const AlertsScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  // Navigation helpers
  static void navigateToBudgetHistory(BuildContext context) {
    Navigator.pushNamed(context, budgetHistory);
  }

  static void navigateToForecast(BuildContext context) {
    Navigator.pushNamed(context, forecast);
  }

  static void navigateToMain(BuildContext context, {int? initialTab}) {
    Navigator.pushReplacementNamed(
      context,
      main,
      arguments: {'initialTab': initialTab},
    );
  }

  static void navigateToMainWithTab(BuildContext context, int tabIndex) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(initialTab: tabIndex),
      ),
      (route) => false,
    );
  }

  static void navigateToAlerts(BuildContext context) {
    Navigator.pushNamed(context, alerts);
  }
}
