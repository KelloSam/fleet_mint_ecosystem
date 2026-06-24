class ExpenditureModel {
  final int id;
  final DateTime date;
  final String category;
  final double amount;
  final String description;
  final String? approvedBy;

  const ExpenditureModel({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.approvedBy,
  });

  static const List<String> categories = [
    'Fuel', 'Maintenance', 'Driver Allowance', 'Tolls',
    'Tyres', 'Oil & Lubricants', 'Spare Parts', 'Cleaning',
    'Office Supplies', 'Other',
  ];

  factory ExpenditureModel.fromJson(Map<String, dynamic> json) => ExpenditureModel(
        id: json['id'],
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        category: json['category'] ?? 'Other',
        amount: (json['amount'] ?? 0).toDouble(),
        description: json['description'] ?? '',
        approvedBy: json['approved_by'],
      );

  static List<ExpenditureModel> mock = [
    ExpenditureModel(id: 1, date: DateTime.now(), category: 'Fuel',
        amount: 3200, description: 'Diesel for BAC 1234 ZM – Lusaka–Livingstone trip',
        approvedBy: 'Chanda Mwewa'),
    ExpenditureModel(id: 2, date: DateTime.now(), category: 'Driver Allowance',
        amount: 450, description: 'Daily allowance for John Mulenga',
        approvedBy: 'Joseph Tembo'),
    ExpenditureModel(id: 3, date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Maintenance', amount: 1800,
        description: 'Brake pad replacement – BAD 5678 ZM',
        approvedBy: 'Chanda Mwewa'),
    ExpenditureModel(id: 4, date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Tolls', amount: 250,
        description: 'Chirundu border tolls – return trip',
        approvedBy: 'Miriam Banda'),
  ];
}
