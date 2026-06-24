class RouteModel {
  final int id;
  final String name;
  final String startLocation;
  final String endLocation;
  final double distanceKm;
  final int durationMinutes;
  final double baseFare;
  final String status;
  final String? description;
  final List<String> intermediateStops;

  const RouteModel({
    required this.id,
    required this.name,
    required this.startLocation,
    required this.endLocation,
    required this.distanceKm,
    required this.durationMinutes,
    required this.baseFare,
    required this.status,
    this.description,
    required this.intermediateStops,
  });

  bool get isActive => status == 'active';

  bool get isInternational {
    final dest = endLocation.toLowerCase();
    return dest.contains('south africa') ||
        dest.contains('zimbabwe') ||
        dest.contains('botswana') ||
        dest.contains('namibia') ||
        dest.contains('mozambique') ||
        dest.contains('tanzania') ||
        dest.contains('malawi') ||
        dest.contains('congo') ||
        dest.contains('angola');
  }

  List<String> get allStops => [startLocation, ...intermediateStops, endLocation];

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'],
        name: json['name'] ?? '',
        startLocation: json['start_location'] ?? '',
        endLocation: json['end_location'] ?? '',
        distanceKm: (json['distance_km'] ?? 0).toDouble(),
        durationMinutes: json['duration_minutes'] ?? 0,
        baseFare: (json['base_fare'] ?? 0).toDouble(),
        status: json['status'] ?? 'active',
        description: json['description'],
        intermediateStops: List<String>.from(json['intermediate_stops'] ?? []),
      );

  static List<RouteModel> mock = [
    RouteModel(id: 1, name: 'Lusaka–Livingstone Express', startLocation: 'Lusaka',
        endLocation: 'Livingstone', distanceKm: 472, durationMinutes: 360,
        baseFare: 250, status: 'active', intermediateStops: ['Kafue', 'Mazabuka', 'Monze', 'Choma']),
    RouteModel(id: 2, name: 'Lusaka–Johannesburg', startLocation: 'Lusaka',
        endLocation: 'Johannesburg, South Africa', distanceKm: 1900, durationMinutes: 1200,
        baseFare: 850, status: 'active', intermediateStops: ['Kafue', 'Chirundu', 'Beit Bridge', 'Musina', 'Pretoria']),
    RouteModel(id: 3, name: 'Lusaka–Ndola', startLocation: 'Lusaka',
        endLocation: 'Ndola', distanceKm: 321, durationMinutes: 270,
        baseFare: 180, status: 'active', intermediateStops: ['Kabwe', 'Kapiri Mposhi']),
    RouteModel(id: 4, name: 'Lusaka–Chipata', startLocation: 'Lusaka',
        endLocation: 'Chipata', distanceKm: 570, durationMinutes: 480,
        baseFare: 320, status: 'active', intermediateStops: ['Luangwa Bridge', 'Petauke', 'Sinda']),
    RouteModel(id: 5, name: 'Lusaka–Harare', startLocation: 'Lusaka',
        endLocation: 'Harare, Zimbabwe', distanceKm: 876, durationMinutes: 720,
        baseFare: 650, status: 'active', intermediateStops: ['Kafue', 'Chirundu', 'Kariba', 'Makuti']),
  ];
}
