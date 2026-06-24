class LocationUpdateModel {
  final int id;
  final String location;
  final String? notes;
  final DateTime postedAt;
  final String? postedByName;

  const LocationUpdateModel({
    required this.id,
    required this.location,
    this.notes,
    required this.postedAt,
    this.postedByName,
  });

  factory LocationUpdateModel.fromJson(Map<String, dynamic> json) => LocationUpdateModel(
        id: json['id'],
        location: json['location'] ?? '',
        notes: json['notes'],
        postedAt: DateTime.tryParse(json['posted_at'] ?? '') ?? DateTime.now(),
        postedByName: json['posted_by_name'],
      );

  static List<LocationUpdateModel> mockForTracking = [
    LocationUpdateModel(
      id: 1, location: 'Kafue', notes: 'Bus departed on time, all passengers boarded',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      postedByName: 'Joseph Tembo',
    ),
    LocationUpdateModel(
      id: 2, location: 'Chirundu Border', notes: 'Short queue at border, expected 30 min delay',
      postedAt: DateTime.now().subtract(const Duration(hours: 1)),
      postedByName: 'Joseph Tembo',
    ),
    LocationUpdateModel(
      id: 3, location: 'Chirundu',
      postedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      postedByName: 'Miriam Banda',
    ),
  ];
}
