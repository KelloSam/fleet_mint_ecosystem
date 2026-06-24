import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/schedule_model.dart';
import '../../providers/booking_provider.dart';

class CompanyRoutesScreen extends StatefulWidget {
  final String slug;
  const CompanyRoutesScreen({super.key, required this.slug});

  @override
  State<CompanyRoutesScreen> createState() => _CompanyRoutesScreenState();
}

class _CompanyRoutesScreenState extends State<CompanyRoutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<BookingProvider>();
      prov.loadSchedules(widget.slug);
      if (prov.operators.isEmpty) prov.loadOperators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final operator = booking.operators.where((o) => o.slug == widget.slug).firstOrNull;
    final domestic = booking.schedules.where((s) => s.route?.isInternational == false).toList();
    final international = booking.schedules.where((s) => s.route?.isInternational == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(operator?.name ?? 'Routes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/book'),
        ),
      ),
      body: booking.isLoading
          ? const Center(child: CircularProgressIndicator())
          : booking.schedules.isEmpty
              ? _EmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (domestic.isNotEmpty) ...[
                      _SectionHeader(title: 'Domestic Routes', icon: Icons.flag_outlined),
                      const SizedBox(height: 8),
                      ...domestic.asMap().entries.map((e) =>
                          _ScheduleCard(
                            schedule: e.value,
                            onTap: () {
                              booking.selectSchedule(e.value);
                              context.go('/book/${widget.slug}/${e.value.id}');
                            },
                          ).animate().fadeIn(delay: (e.key * 60).ms).slideY(begin: 0.1, end: 0)),
                    ],
                    if (international.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(
                          title: 'International / Cross-Border', icon: Icons.public_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Passport and valid visa required for all cross-border trips.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...international.asMap().entries.map((e) =>
                          _ScheduleCard(
                            schedule: e.value,
                            onTap: () {
                              booking.selectSchedule(e.value);
                              context.go('/book/${widget.slug}/${e.value.id}');
                            },
                          ).animate().fadeIn(delay: (e.key * 60).ms).slideY(begin: 0.1, end: 0)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onTap;

  const _ScheduleCard({required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final route = schedule.route;
    final vehicle = schedule.vehicle;
    final seatsLeft = schedule.availableSeats;
    final seatColor = seatsLeft == 0
        ? AppColors.error
        : seatsLeft <= 5
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: schedule.isFullyBooked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Route header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route?.startLocation ?? '',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary, fontSize: 15),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                route?.endLocation ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.currency(schedule.fare),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary, fontSize: 16),
                      ),
                      Text('per seat', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: Fmt.timeStr(schedule.departureTime)),
                      const SizedBox(width: 8),
                      if (schedule.estimatedArrivalTime != null)
                        _InfoChip(
                            icon: Icons.timer_outlined,
                            label: route != null
                                ? Fmt.minutesToDuration(route.durationMinutes)
                                : schedule.estimatedArrivalTime!),
                      const SizedBox(width: 8),
                      if (vehicle != null)
                        _InfoChip(icon: Icons.directions_bus_outlined, label: vehicle.plate),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Days of operation
                      ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                        final active = schedule.daysOfOperation.contains(day);
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 30, height: 22,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              day.substring(0, 1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: seatColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          seatsLeft == 0
                              ? 'Fully Booked'
                              : '$seatsLeft seats left',
                          style: TextStyle(
                              color: seatColor, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: schedule.isFullyBooked ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: schedule.isFullyBooked ? AppColors.divider : AppColors.primary,
                        foregroundColor: schedule.isFullyBooked ? AppColors.textSecondary : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(schedule.isFullyBooked ? 'Fully Booked' : 'Select Seat'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('No active schedules', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Check back later for available departures.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
