import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/booking_provider.dart';

class TicketScreen extends StatefulWidget {
  final String reference;
  const TicketScreen({super.key, required this.reference});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<BookingProvider>();
      if (prov.currentBooking?.reference != widget.reference) {
        prov.getTicket(widget.reference);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final booking = prov.currentBooking;

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Booking not found', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Reference: ${widget.reference}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Booking Confirmed!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.success),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 16),

            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 6))],
              ),
              child: Column(
                children: [
                  // Ticket header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_bus_rounded,
                                color: AppColors.accentLight, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              booking.schedule?.operator?.name ?? 'Fleet Mint',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FROM', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                Text(
                                  booking.schedule?.route?.startLocation ?? '',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.arrow_forward_rounded, color: AppColors.accentLight, size: 28),
                                if (booking.schedule?.route != null)
                                  Text(
                                    Fmt.minutesToDuration(booking.schedule!.route!.durationMinutes),
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TO', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                Text(
                                  booking.schedule?.route?.endLocation ?? '',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dashed divider
                  _TicketDivider(),

                  // QR code
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        QrImageView(
                          data: booking.reference,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primaryDark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          booking.reference,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.primary,
                              ),
                        ),
                        Text('Show this QR code when boarding',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),

                  // Dashed divider
                  _TicketDivider(),

                  // Ticket details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Passenger', value: booking.passengerName),
                        _DetailRow(label: 'Travel Date', value: Fmt.date(booking.travelDate)),
                        _DetailRow(
                          label: 'Departure',
                          value: booking.schedule?.departureTime != null
                              ? Fmt.timeStr(booking.schedule!.departureTime)
                              : '—',
                        ),
                        _DetailRow(label: 'Seat Number',
                            value: 'Seat ${booking.seatNumber}', highlight: true),
                        if (booking.pickupStation != null)
                          _DetailRow(
                            label: 'Boarding Point',
                            value: '📍 ${booking.pickupStation!}',
                            highlight: true,
                          ),
                        _DetailRow(
                          label: 'Fare Paid',
                          value: Fmt.currency(booking.farePaid),
                          highlight: true,
                        ),
                        _DetailRow(label: 'Payment', value: booking.paymentMethod),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Actions
            ElevatedButton.icon(
              onPressed: () => context.go('/track?ref=${booking.reference}'),
              icon: const Icon(Icons.location_on_rounded),
              label: const Text('Track This Bus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/book'),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Book Another Journey'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 20),
            // Operator contact
            if (booking.schedule?.operator?.phone != null)
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:${booking.schedule!.operator!.phone!}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                label: Text(
                  'Call ${booking.schedule!.operator!.name}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TicketDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            color: AppColors.background, shape: BoxShape.circle),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (_) => const SizedBox(
                    width: 5, height: 1,
                    child: DecoratedBox(decoration: BoxDecoration(color: AppColors.divider)),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            color: AppColors.background, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? AppColors.primary : AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
