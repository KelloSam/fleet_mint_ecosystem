import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/booking_provider.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String slug;
  final String scheduleId;

  const SeatSelectionScreen({super.key, required this.slug, required this.scheduleId});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<BookingProvider>();
      final date = prov.selectedDate.toIso8601String().split('T')[0];
      prov.loadTakenSeats(widget.scheduleId, date);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (context.read<BookingProvider>().selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a seat first')),
      );
      return;
    }
    final prov = context.read<BookingProvider>();
    prov.setPassengerDetails(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    final booking = await prov.confirmBooking();
    if (!mounted) return;
    if (booking != null) {
      context.go('/ticket/${booking.reference}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error ?? 'Booking failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final schedule = prov.selectedSchedule;
    final route = schedule?.route;
    final capacity = schedule?.vehicle?.seatCapacity ?? 44;
    final stops = route?.intermediateStops ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${route?.startLocation ?? ''} → ${route?.endLocation ?? ''}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/book/${widget.slug}'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Travel date picker
                Text('Travel Date', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: prov.selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (d != null) prov.selectDate(d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          Fmt.date(prov.selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Seat map
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Your Seat', style: Theme.of(context).textTheme.headlineSmall),
                    if (prov.selectedSeat != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: Text('Seat ${prov.selectedSeat}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Legend
                Row(
                  children: [
                    _LegendItem(color: AppColors.success, label: 'Available'),
                    const SizedBox(width: 16),
                    _LegendItem(color: AppColors.primary, label: 'Your Selection'),
                    const SizedBox(width: 16),
                    _LegendItem(color: AppColors.error, label: 'Taken'),
                  ],
                ),
                const SizedBox(height: 12),

                // Bus map
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      // Driver area
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_rounded, color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text('Driver', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _SeatMap(
                          capacity: capacity,
                          takenSeats: prov.takenSeats,
                          selectedSeat: prov.selectedSeat,
                          onSelect: (seat) => prov.selectSeat(seat),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pickup station
                if (stops.isNotEmpty) ...[
                  Text('Boarding Point', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Where will you board the bus?',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [route?.startLocation ?? '', ...stops].map((stop) {
                      final selected = prov.selectedPickupStation == stop ||
                          (prov.selectedPickupStation == null && stop == route?.startLocation);
                      return ChoiceChip(
                        label: Text(stop),
                        selected: selected,
                        onSelected: (_) => prov.selectPickupStation(stop),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Passenger details
                Text('Your Details', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+260...',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Payment method
                Text('Payment Method', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                ...AppPaymentMethods.all.map((method) {
                    final selected = prov.paymentMethod == method;
                    return GestureDetector(
                      onTap: () => prov.setPaymentMethod(method),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.divider,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(method, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: selected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 24),

                // Confirm button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fare', style: Theme.of(context).textTheme.bodyLarge),
                          Text(
                            Fmt.currency(schedule?.fare ?? 0),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (prov.selectedSeat != null) ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Seat', style: Theme.of(context).textTheme.bodyMedium),
                            Text('Seat ${prov.selectedSeat}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: prov.isLoading ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: prov.isLoading
                              ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Confirm Booking · ${Fmt.currency(schedule?.fare ?? 0)}'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatMap extends StatelessWidget {
  final int capacity;
  final List<int> takenSeats;
  final int? selectedSeat;
  final void Function(int) onSelect;

  const _SeatMap({
    required this.capacity,
    required this.takenSeats,
    required this.selectedSeat,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (capacity / 4).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row label
              SizedBox(
                width: 24,
                child: Text(
                  '${rowIndex + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              // Seats A, B
              ...List.generate(2, (col) {
                final seat = rowIndex * 4 + col + 1;
                if (seat > capacity) return const SizedBox(width: 36);
                return _Seat(
                  number: seat,
                  taken: takenSeats.contains(seat),
                  selected: selectedSeat == seat,
                  onTap: () => onSelect(seat),
                );
              }),
              // Aisle
              const SizedBox(width: 20),
              // Seats C, D
              ...List.generate(2, (col) {
                final seat = rowIndex * 4 + col + 3;
                if (seat > capacity) return const SizedBox(width: 36);
                return _Seat(
                  number: seat,
                  taken: takenSeats.contains(seat),
                  selected: selectedSeat == seat,
                  onTap: () => onSelect(seat),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _Seat extends StatelessWidget {
  final int number;
  final bool taken;
  final bool selected;
  final VoidCallback onTap;

  const _Seat({
    required this.number,
    required this.taken,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (taken) {
      bg = AppColors.error.withValues(alpha: 0.15);
      fg = AppColors.error;
    } else if (selected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else {
      bg = AppColors.success.withValues(alpha: 0.1);
      fg = AppColors.success;
    }

    return GestureDetector(
      onTap: taken ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: taken ? AppColors.error.withValues(alpha: 0.3)
                : selected ? AppColors.primary
                : AppColors.success.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
