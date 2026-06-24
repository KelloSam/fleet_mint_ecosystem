import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../../providers/schedule_provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BookingModel> _filtered(List<BookingModel> bookings, String? status) {
    var list = status != null
        ? bookings.where((b) => b.status == status).toList()
        : bookings;
    if (_searchQuery.isNotEmpty) {
      list = list.where((b) =>
          b.passengerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.reference.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.passengerPhone.contains(_searchQuery)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ScheduleProvider>();
    final all = prov.bookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, reference, or phone...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentLight,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                tabs: [
                  Tab(text: 'All (${all.length})'),
                  Tab(text: 'Confirmed (${all.where((b) => b.isConfirmed).length})'),
                  Tab(text: 'Checked In (${all.where((b) => b.isCheckedIn).length})'),
                  Tab(text: 'Cancelled (${all.where((b) => b.isCancelled).length})'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.loadBookings(),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingList(bookings: _filtered(all, null), prov: prov),
                _BookingList(bookings: _filtered(all, 'confirmed'), prov: prov),
                _BookingList(bookings: _filtered(all, 'checked_in'), prov: prov),
                _BookingList(bookings: _filtered(all, 'cancelled'), prov: prov),
              ],
            ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final ScheduleProvider prov;

  const _BookingList({required this.bookings, required this.prov});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.divider),
            SizedBox(height: 12),
            Text('No bookings found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, i) => _BookingCard(
        booking: bookings[i],
        onCheckIn: () async {
          final ok = await prov.updateBookingStatus(bookings[i].reference, 'checked_in');
          if (context.mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passenger checked in'), backgroundColor: AppColors.success));
          }
        },
      ).animate().fadeIn(delay: (i * 40).ms),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCheckIn;

  const _BookingCard({required this.booking, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final statusColor = Fmt.statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seat badge
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '${booking.seatNumber}',
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.passengerName,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(booking.passengerPhone,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(booking.reference,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('· ${Fmt.date(booking.travelDate)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      if (booking.pickupStation != null)
                        Text('📍 ${booking.pickupStation}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        Fmt.statusLabel(booking.status),
                        style: TextStyle(
                            color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Fmt.currency(booking.farePaid),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(booking.paymentMethod,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          if (booking.isConfirmed)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.success, size: 18),
                      label: const Text('Check In',
                          style: TextStyle(color: AppColors.success)),
                    ),
                  ),
                  const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_rounded,
                          color: AppColors.primary, size: 18),
                      label: const Text('View Ticket',
                          style: TextStyle(color: AppColors.primary)),
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
