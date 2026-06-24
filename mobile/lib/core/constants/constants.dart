import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Colors.white;
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x14000000);

  static const List<Color> gradientPrimary = [
    Color(0xFF0A1628),
    Color(0xFF1565C0),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFF1565C0),
    Color(0xFF00BCD4),
  ];

  // Operator brand colors
  static const Map<String, Color> operatorColors = {
    'power_tools': Color(0xFFE53935),
    'jordan': Color(0xFF43A047),
    'likili': Color(0xFF7B1FA2),
    'rayon': Color(0xFFFB8C00),
    'oasis': Color(0xFF00897B),
    'madithel': Color(0xFF1565C0),
  };
}

class AppConfig {
  static const String apiBaseUrl = 'http://localhost:4000';
  static const String appName = 'Fleet Mint';
  static const String appTagline = "Zambia's Smart Transport Platform";
  static const String currency = 'ZMW';
  static const int notificationPollSeconds = 30;
}

class AppStrings {
  static const String loginTitle = 'Staff Login';
  static const String loginSubtitle = 'Fleet Mint Ecosystem';
  static const String bookTitle = 'Book a Ticket';
  static const String trackTitle = 'Track Your Bus';
  static const String dashboardTitle = 'Dashboard';
  static const String schedulesTitle = 'Schedules';
  static const String bookingsTitle = 'Bookings';
  static const String fleetTitle = 'Fleet';
  static const String financeTitle = 'Finance';
  static const String moreTitle = 'More';
}

class AppPaymentMethods {
  static const List<String> all = [
    'Cash at Counter',
    'Airtel Money',
    'MTN Mobile Money',
    'Card',
    'Bank Transfer',
  ];
}

class AppBookingStatuses {
  static const String confirmed = 'confirmed';
  static const String checkedIn = 'checked_in';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';
}
