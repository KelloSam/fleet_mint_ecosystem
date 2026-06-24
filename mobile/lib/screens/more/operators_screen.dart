import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../models/operator_model.dart';
import '../../providers/booking_provider.dart';

class OperatorsScreen extends StatefulWidget {
  const OperatorsScreen({super.key});

  @override
  State<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends State<OperatorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadOperators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Companies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/more'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: prov.loadOperators),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.operators.length,
              itemBuilder: (context, i) => _OperatorCard(operator: prov.operators[i])
                  .animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, end: 0),
            ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  final OperatorModel operator;
  const _OperatorCard({required this.operator});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: operator.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: operator.color.withValues(alpha: 0.3),
                          blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(operator.initial,
                        style: const TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(operator.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(operator.tagline,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${operator.activeRoutesCount ?? 0} routes',
                                style: const TextStyle(color: AppColors.success,
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: operator.active
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              operator.active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color: operator.active ? AppColors.success : AppColors.error,
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (operator.phone != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:${operator.phone!}');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: const Text('Call'),
                    ),
                  ),
                if (operator.email != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('mailto:${operator.email!}');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.email_outlined, size: 16),
                      label: const Text('Email'),
                    ),
                  ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => context.go('/book/${operator.slug}'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View Routes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
