class VehicleModel {
  final int id;
  final String registrationNumber;
  final String make;
  final String model;
  final int year;
  final String vehicleType; // 'bus' | 'truck'
  final String status; // 'active' | 'maintenance' | 'inactive'
  // Bus-specific
  final int? seatCapacity;
  final String? busType;
  // Truck-specific
  final double? payloadTonnes;
  final String? bodyType;

  const VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.status,
    this.seatCapacity,
    this.busType,
    this.payloadTonnes,
    this.bodyType,
  });

  bool get isBus => vehicleType == 'bus';
  bool get isTruck => vehicleType == 'truck';
  bool get isActive => status == 'active';

  String get displayName => '$make $model ($year)';
  String get plate => registrationNumber;

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'],
        registrationNumber: json['registration_number'] ?? '',
        make: json['make'] ?? '',
        model: json['model'] ?? '',
        year: json['year'] ?? 0,
        vehicleType: json['vehicle_type'] ?? 'bus',
        status: json['status'] ?? 'active',
        seatCapacity: json['seat_capacity'],
        busType: json['bus_type'],
        payloadTonnes: json['payload_tonnes'] != null ? (json['payload_tonnes']).toDouble() : null,
        bodyType: json['body_type'],
      );

  static List<VehicleModel> mock = [
    VehicleModel(id: 1, registrationNumber: 'BAC 1234 ZM', make: 'Scania', model: 'K410',
        year: 2019, vehicleType: 'bus', status: 'active', seatCapacity: 44, busType: 'Luxury Coach'),
    VehicleModel(id: 2, registrationNumber: 'BAD 5678 ZM', make: 'Volvo', model: 'B8R',
        year: 2021, vehicleType: 'bus', status: 'active', seatCapacity: 49, busType: 'Standard Coach'),
    VehicleModel(id: 3, registrationNumber: 'BAE 9012 ZM', make: 'Yutong', model: 'ZK6122H',
        year: 2020, vehicleType: 'bus', status: 'maintenance', seatCapacity: 55, busType: 'Standard'),
    VehicleModel(id: 4, registrationNumber: 'BAF 3456 ZM', make: 'Mercedes', model: 'Sprinter',
        year: 2022, vehicleType: 'bus', status: 'active', seatCapacity: 22, busType: 'Minibus'),
    VehicleModel(id: 5, registrationNumber: 'GCF 7890 ZM', make: 'MAN', model: 'TGS 26.440',
        year: 2018, vehicleType: 'truck', status: 'active', payloadTonnes: 30, bodyType: 'Flatbed'),
    VehicleModel(id: 6, registrationNumber: 'GCG 1234 ZM', make: 'Volvo', model: 'FH16',
        year: 2020, vehicleType: 'truck', status: 'active', payloadTonnes: 25, bodyType: 'Enclosed'),
  ];
}
