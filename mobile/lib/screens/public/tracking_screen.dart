import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/api_service.dart';
import '../../models/location_update_model.dart';

class TrackingScreen extends StatefulWidget {
  final String? initialRef;
  const TrackingScreen({super.key, this.initialRef});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _refCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _trackingData;

  @override
  void initState() {
    super.initState();
    if (widget.initialRef != null) {
      _refCtrl.text = widget.initialRef!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) return;
    setState(() { _isLoading = true; _trackingData = null; });
    try {
      final data = await ApiService().trackBooking(ref);
      setState(() { _trackingData = data; _isLoading = false; });
    } catch (_) {
      // Mock tracking data
      setState(() {
        _trackingData = _mockTrackingData(ref);
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mockTrackingData(String ref) {
    return {
      'booking': {
        'reference': ref,
        'passenger_name': 'Grace Phiri',
        'seat_number': 14,
        'travel_date': DateTime.now().toIso8601String(),
        'pickup_station': 'Chirundu',
        'fare_paid': 850.0,
        'payment_method': 'Airtel Money',
        'status': 'confirmed',
      },
      'route': {
        'name': 'Lusaka–Johannesburg',
        'start_location': 'Lusaka',
        'end_location': 'Johannesburg, South Africa',
        'intermediate_stops': ['Kafue', 'Chirundu', 'Beit Bridge', 'Musina', 'Pretoria'],
      },
      'operator': {
        'name': 'Madithel Bus Services',
        'phone': '+260977654321',
      },
      'current_location': 'Chirundu',
      'current_location_note': 'Short queue at border, expected 30 min delay',
      'current_location_time': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
      'current_location_by': 'Miriam Banda',
      'updates': [
        {
          'location': 'Chirundu',
          'notes': 'Short queue at border, expected 30 min delay',
          'posted_at': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
          'posted_by_name': 'Miriam Banda',
        },
        {
          'location': 'Kafue',
          'notes': 'Bus departed on time, all passengers boarded',
          'posted_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'posted_by_name': 'Joseph Tembo',
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Bus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _refCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter booking reference (e.g. BK-0012345)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _track(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _track,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Track'),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trackingData == null
                    ? _EmptyState()
                    : _TrackingResult(data: _trackingData!),
          ),
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
          const Icon(Icons.location_searching_rounded, size: 64, color: AppColors.accent),
          const SizedBox(height: 20),
          Text('Track Your Bus or Parcel',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Enter your booking reference above\nto see live location updates.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TrackingResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TrackingResult({required this.data});

  @override
  Widget build(BuildContext context) {
    final bookingData = data['booking'] as Map<String, dynamic>? ?? {};
    final routeData = data['route'] as Map<String, dynamic>? ?? {};
    final operatorData = data['operator'] as Map<String, dynamic>? ?? {};
    final currentLocation = data['current_location'] as String?;
    final currentNote = data['current_location_note'] as String?;
    final currentTime = data['current_location_time'] as String?;
    final currentBy = data['current_location_by'] as String?;
    final updates = (data['updates'] as List? ?? [])
        .map((e) => LocationUpdateModel.fromJson(e)).toList();

    final allStops = [
      routeData['start_location'] ?? '',
      ...List<String>.from(routeData['intermediate_stops'] ?? []),
      routeData['end_location'] ?? '',
    ];
    final pickupStation = bookingData['pickup_station'] as String?;

    int currentStopIndex = currentLocation != null
        ? allStops.indexWhere((s) => s.toLowerCase() == currentLocation.toLowerCase())
        : -1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current location card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientAccent,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text('Current Location', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentLocation ?? 'Not Yet Departed',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800),
                ),
                if (currentNote != null) ...[
                  const SizedBox(height: 6),
                  Text(currentNote, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                if (currentTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reported ${Fmt.relativeTime(DateTime.parse(currentTime))}${currentBy != null ? " by $currentBy" : ""}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 20),

          // Booking info
          Text('Booking', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                _Row(label: 'Reference', value: bookingData['reference'] ?? ''),
                _Row(label: 'Passenger', value: bookingData['passenger_name'] ?? ''),
                _Row(label: 'Seat', value: 'Seat ${bookingData['seat_number'] ?? ""}'),
                if (pickupStation != null)
                  _Row(label: 'Your Boarding Point', value: '📍 $pickupStation', highlight: true),
                _Row(label: 'Travel Date',
                    value: bookingData['travel_date'] != null
                        ? Fmt.date(DateTime.parse(bookingData['travel_date']))
                        : ''),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Route progress
          Text('Route Progress', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              children: allStops.asMap().entries.map((e) {
                final i = e.key;
                final stop = e.value;
                final isPassed = currentStopIndex >= 0 && i < currentStopIndex;
                final isCurrent = i == currentStopIndex;
                final isPickup = stop == pickupStation;
                final isLast = i == allStops.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? AppColors.success
                                  : isPassed
                                      ? AppColors.primary
                                      : AppColors.background,
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.success
                                    : isPassed
                                        ? AppColors.primary
                                        : AppColors.divider,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isCurrent
                                  ? const Icon(Icons.directions_bus_rounded,
                                      color: Colors.white, size: 12)
                                  : isPassed
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 12)
                                      : null,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2, height: 36,
                              color: isPassed ? AppColors.primary : AppColors.divider,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stop,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                        color: isCurrent ? AppColors.success : AppColors.textPrimary,
                                      ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('HERE NOW',
                                        style: TextStyle(color: Colors.white, fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            if (isPickup)
                              Text('📍 Your pickup point',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.accent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Location history
          if (updates.isNotEmpty) ...[
            Text('Location History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ...updates.map((u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.location,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                            if (u.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(u.notes!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        Fmt.relativeTime(u.postedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                )).toList(),
          ],
          const SizedBox(height: 16),

          // Call operator
          if (operatorData['phone'] != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:${operatorData['phone']}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call_rounded),
                label: Text('Call ${operatorData['name'] ?? 'Bus Company'}'),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Row({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: highlight ? AppColors.primary : AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
