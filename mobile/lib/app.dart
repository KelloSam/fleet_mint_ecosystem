import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/public/home_screen.dart';
import 'screens/public/companies_screen.dart';
import 'screens/public/company_routes_screen.dart';
import 'screens/public/seat_selection_screen.dart';
import 'screens/public/ticket_screen.dart';
import 'screens/public/tracking_screen.dart';
import 'screens/transit/schedules_screen.dart';
import 'screens/transit/schedule_detail_screen.dart';
import 'screens/transit/bookings_screen.dart';
import 'screens/fleet/fleet_screen.dart';
import 'screens/finance/finance_screen.dart';
import 'screens/more/more_screen.dart';
import 'screens/more/operators_screen.dart';
import 'core/theme/app_theme.dart';

class FleetMintApp extends StatefulWidget {
  const FleetMintApp({super.key});

  @override
  State<FleetMintApp> createState() => _FleetMintAppState();
}

class _FleetMintAppState extends State<FleetMintApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router created once; auth is a refreshListenable so redirects re-run on change
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final loc = state.uri.toString();
        final isPublic = loc.startsWith('/home') ||
            loc.startsWith('/book') ||
            loc.startsWith('/track') ||
            loc.startsWith('/ticket') ||
            loc.startsWith('/login') ||
            loc == '/splash';
        if (!auth.initialized) return null;
        if (!auth.isLoggedIn && !isPublic) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, s) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, s) => const LoginScreen()),
        GoRoute(path: '/home', builder: (_, s) => const HomeScreen()),
        GoRoute(path: '/track', builder: (_, state) {
          final ref = state.uri.queryParameters['ref'];
          return TrackingScreen(initialRef: ref);
        }),
        GoRoute(
          path: '/ticket/:ref',
          builder: (_, state) =>
              TicketScreen(reference: state.pathParameters['ref']!),
        ),

        // Public booking flow
        GoRoute(path: '/book', builder: (_, s) => const CompaniesScreen()),
        GoRoute(
          path: '/book/:slug',
          builder: (_, state) =>
              CompanyRoutesScreen(slug: state.pathParameters['slug']!),
        ),
        GoRoute(
          path: '/book/:slug/:scheduleId',
          builder: (_, state) => SeatSelectionScreen(
            slug: state.pathParameters['slug']!,
            scheduleId: state.pathParameters['scheduleId']!,
          ),
        ),

        // Staff shell with bottom navigation
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
                path: '/dashboard', builder: (_, s) => const DashboardScreen()),
            GoRoute(
              path: '/schedules',
              builder: (_, s) => const SchedulesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ScheduleDetailScreen(
                      scheduleId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
                path: '/bookings', builder: (_, s) => const BookingsScreen()),
            GoRoute(
                path: '/finance', builder: (_, s) => const FinanceScreen()),
            GoRoute(path: '/more', builder: (_, s) => const MoreScreen()),
          ],
        ),

        // Outside shell
        GoRoute(path: '/fleet', builder: (_, s) => const FleetScreen()),
        GoRoute(
            path: '/operators', builder: (_, s) => const OperatorsScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fleet Mint Ecosystem',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
