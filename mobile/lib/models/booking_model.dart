import 'schedule_model.dart';

class BookingModel {
  final int id;
  final String reference;
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;
  final int seatNumber;
  final String? pickupStation;
  final DateTime travelDate;
  final double farePaid;
  final String paymentMethod;
  final String? paymentReference;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final ScheduleModel? schedule;

  const BookingModel({
    required this.id,
    required this.reference,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    required this.seatNumber,
    this.pickupStation,
    required this.travelDate,
    required this.farePaid,
    required this.paymentMethod,
    this.paymentReference,
    required this.status,
    this.notes,
    required this.createdAt,
    this.schedule,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCancelled => status == 'cancelled';

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'],
        reference: json['reference'] ?? 'BK-0000000',
        passengerName: json['passenger_name'] ?? '',
        passengerPhone: json['passenger_phone'] ?? '',
        passengerEmail: json['passenger_email'],
        seatNumber: json['seat_number'] ?? 0,
        pickupStation: json['pickup_station'],
        travelDate: DateTime.tryParse(json['travel_date'] ?? '') ?? DateTime.now(),
        farePaid: (json['fare_paid'] ?? 0).toDouble(),
        paymentMethod: json['payment_method'] ?? 'Cash at Counter',
        paymentReference: json['payment_reference'],
        status: json['status'] ?? 'confirmed',
        notes: json['notes'],
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        schedule: json['schedule'] != null ? ScheduleModel.fromJson(json['schedule']) : null,
      );

  static List<BookingModel> mockToday = [
    BookingModel(
      id: 1001, reference: 'BK-0001001', passengerName: 'Grace Phiri',
      passengerPhone: '+260977001234', seatNumber: 14,
      pickupStation: 'Chirundu', travelDate: DateTime.now(),
      farePaid: 850, paymentMethod: 'Airtel Money',
      paymentReference: 'TX-AMZ-12345', status: 'confirmed',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BookingModel(
      id: 1002, reference: 'BK-0001002', passengerName: 'Peter Nkonde',
      passengerPhone: '+260966002345', seatNumber: 7,
      travelDate: DateTime.now(),
      farePaid: 250, paymentMethod: 'Cash at Counter',
      status: 'checked_in', createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookingModel(
      id: 1003, reference: 'BK-0001003', passengerName: 'Mary Lungu',
      passengerPhone: '+260955003456', seatNumber: 22,
      pickupStation: 'Kafue', travelDate: DateTime.now(),
      farePaid: 250, paymentMethod: 'MTN Mobile Money',
      status: 'confirmed', createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    BookingModel(
      id: 1004, reference: 'BK-0001004', passengerName: 'David Mutale',
      passengerPhone: '+260944004567', seatNumber: 35,
      travelDate: DateTime.now(),
      farePaid: 320, paymentMethod: 'Cash at Counter',
      status: 'confirmed', createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];
}
