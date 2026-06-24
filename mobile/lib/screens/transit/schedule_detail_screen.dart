import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/schedule_provider.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;
  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedStop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadScheduleDetail(widget.scheduleId);
    });
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _postUpdate() async {
    final location = _locationCtrl.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')));
      return;
    }
    final ok = await context.read<ScheduleProvider>()
        .postLocationUpdate(widget.scheduleId, location, notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null);
    if (!mounted) return;
    if (ok) {
      _locationCtrl.clear();
      _notesCtrl.clear();
      setState(() => _selectedStop = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location update posted'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ScheduleProvider>();
    final schedule = prov.selectedSchedule;

    if (prov.isLoading || schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = schedule.route;
    final allStops = route?.allStops ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/schedules'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(schedule.code,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          schedule.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${route?.startLocation ?? ''} → ${route?.endLocation ?? ''}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoPill(label: Fmt.timeStr(schedule.departureTime),
                          icon: Icons.access_time_rounded),
                      const SizedBox(width: 8),
                      _InfoPill(label: Fmt.currency(schedule.fare), icon: Icons.payments_outlined),
                      const SizedBox(width: 8),
                      _InfoPill(label: '${schedule.availableSeats} seats',
                          icon: Icons.event_seat_rounded),
                    ],
                  ),
                  if (schedule.vehicle != null) ...[
                    const SizedBox(height: 8),
                    _InfoPill(
                        label: schedule.vehicle!.registrationNumber,
                        icon: Icons.directions_bus_outlined),
                  ],
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
            const SizedBox(height: 20),

            // Current location
            Text('Post Location Update', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Quick-pick a stop:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allStops.map((stop) {
                final selected = _selectedStop == stop;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedStop = stop);
                    _locationCtrl.text = stop;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(
                      stop,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location (or type a custom location)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional, e.g. "Border delay — 2 hours")',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: prov.isLoading ? null : _postUpdate,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Post Location Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location history
            if (schedule.locationUpdates.isNotEmpty) ...[
              Text('Location History', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ...schedule.locationUpdates.asMap().entries.map((e) {
                final update = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.accent, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(update.location,
                                style: Theme.of(context).textTheme.titleLarge),
                            if (update.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(update.notes!,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Fmt.time(update.postedAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          if (update.postedByName != null)
                            Text(update.postedByName!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (e.key * 60).ms);
              }).toList(),
            ] else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text('No location updates posted yet.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
