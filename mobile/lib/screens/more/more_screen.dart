import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../providers/auth_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.3),
                  radius: 30,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Staff Member',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(user?.staffId ?? '',
                          style: const TextStyle(color: AppColors.accentLight, fontSize: 13)),
                      Text(
                        '${_capitalize(user?.role ?? '')} · ${user?.email ?? ''}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      if (user?.phone != null)
                        Text(user!.phone!,
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // Menu sections
          _Section(title: 'Operations', items: [
            _MenuItem(icon: Icons.directions_bus_rounded, label: 'Fleet Management',
                onTap: () => context.go('/fleet')),
            _MenuItem(icon: Icons.business_rounded, label: 'Bus Companies / Operators',
                onTap: () => context.go('/operators')),
            _MenuItem(icon: Icons.people_alt_rounded, label: 'Staff Management',
                onTap: () {}, badge: user?.isAdmin == true ? null : 'Admin only'),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Reports', items: [
            _MenuItem(icon: Icons.picture_as_pdf_rounded, label: 'Daily PDF Report',
                onTap: () {}),
            _MenuItem(icon: Icons.bar_chart_rounded, label: 'Weekly Revenue Report',
                onTap: () {}),
            _MenuItem(icon: Icons.receipt_long_rounded, label: 'Expenditure Report',
                onTap: () {}),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Public Portal', items: [
            _MenuItem(icon: Icons.confirmation_number_outlined, label: 'Book a Ticket',
                onTap: () => context.go('/home')),
            _MenuItem(icon: Icons.location_on_outlined, label: 'Track a Bus',
                onTap: () => context.go('/track')),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Account', items: [
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: AppColors.error,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text('Logout')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/home');
                }
              },
            ),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Fleet Mint Ecosystem v1.0\n© ${DateTime.now().year} Madithel Bus Services',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            )
          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.divider),
    );
  }
}
