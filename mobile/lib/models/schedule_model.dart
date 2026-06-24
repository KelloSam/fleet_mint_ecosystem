import 'route_model.dart';
import 'vehicle_model.dart';
import 'operator_model.dart';
import 'location_update_model.dart';

class ScheduleModel {
  final int id;
  final String code;
  final OperatorModel? operator;
  final RouteModel? route;
  final VehicleModel? vehicle;
  final String departureTime;
  final String? estimatedArrivalTime;
  final double fare;
  final int availableSeats;
  final List<String> daysOfOperation;
  final String status;
  final String? notes;
  final List<LocationUpdateModel> locationUpdates;

  const ScheduleModel({
    required this.id,
    required this.code,
    this.operator,
    this.route,
    this.vehicle,
    required this.departureTime,
    this.estimatedArrivalTime,
    required this.fare,
    required this.availableSeats,
    required this.daysOfOperation,
    required this.status,
    this.notes,
    this.locationUpdates = const [],
  });

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isFullyBooked => availableSeats <= 0;
  bool get isAlmostFull => availableSeats <= 5 && availableSeats > 0;

  String get scheduleCode => 'SCH-${id.toString().padLeft(5, '0')}';

  LocationUpdateModel? get latestLocation =>
      locationUpdates.isNotEmpty ? locationUpdates.first : null;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
        id: json['id'],
        code: json['code'] ?? 'SCH-${json['id'].toString().padLeft(5, '0')}',
        operator: json['operator'] != null ? OperatorModel.fromJson(json['operator']) : null,
        route: json['route'] != null ? RouteModel.fromJson(json['route']) : null,
        vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
        departureTime: json['departure_time'] ?? '00:00',
        estimatedArrivalTime: json['estimated_arrival_time'],
        fare: (json['fare'] ?? 0).toDouble(),
        availableSeats: json['available_seats'] ?? 0,
        daysOfOperation: List<String>.from(json['days_of_operation'] ?? []),
        status: json['status'] ?? 'active',
        notes: json['notes'],
        locationUpdates: (json['location_updates'] as List? ?? [])
            .map((e) => LocationUpdateModel.fromJson(e))
            .toList(),
      );

  static List<ScheduleModel> mockFor(String operatorSlug) {
    final route1 = RouteModel.mock[0];
    final route2 = RouteModel.mock[1];
    final vehicle1 = VehicleModel.mock[0];
    final vehicle2 = VehicleModel.mock[1];
    final op = OperatorModel.mock.firstWhere((o) => o.slug == operatorSlug,
        orElse: () => OperatorModel.mock[0]);

    return [
      ScheduleModel(
        id: 101, code: 'SCH-00101', operator: op, route: route1, vehicle: vehicle1,
        departureTime: '06:00', estimatedArrivalTime: '12:00',
        fare: 250, availableSeats: 32,
        daysOfOperation: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        status: 'active', notes: 'Express service, no stops',
      ),
      ScheduleModel(
        id: 102, code: 'SCH-00102', operator: op, route: route2, vehicle: vehicle2,
        departureTime: '07:30', estimatedArrivalTime: '27:30',
        fare: 850, availableSeats: 5,
        daysOfOperation: ['Mon', 'Wed', 'Fri'],
        status: 'active',
      ),
      ScheduleModel(
        id: 103, code: 'SCH-00103', operator: op, route: RouteModel.mock[2], vehicle: vehicle1,
        departureTime: '08:00', estimatedArrivalTime: '12:30',
        fare: 180, availableSeats: 0,
        daysOfOperation: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        status: 'active',
      ),
      ScheduleModel(
        id: 104, code: 'SCH-00104', operator: op, route: RouteModel.mock[3], vehicle: vehicle2,
        departureTime: '13:00', estimatedArrivalTime: '21:00',
        fare: 320, availableSeats: 18,
        daysOfOperation: ['Tue', 'Thu', 'Sat'],
        status: 'active',
      ),
    ];
  }
}
