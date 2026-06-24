class CashingReportModel {
  final int id;
  final DateTime reportDate;
  final double expectedCashing;
  final double receivedCashing;
  final double variance;
  final String? transactionId;
  final double debtBalance;
  final double expenditure;
  final String? description;
  final String? createdByName;

  const CashingReportModel({
    required this.id,
    required this.reportDate,
    required this.expectedCashing,
    required this.receivedCashing,
    required this.variance,
    this.transactionId,
    required this.debtBalance,
    required this.expenditure,
    this.description,
    this.createdByName,
  });

  bool get hasVariance => variance.abs() > 0.01;
  bool get isShortfall => variance < 0;
  bool get isSurplus => variance > 0;

  factory CashingReportModel.fromJson(Map<String, dynamic> json) => CashingReportModel(
        id: json['id'],
        reportDate: DateTime.tryParse(json['report_date'] ?? '') ?? DateTime.now(),
        expectedCashing: (json['expected_cashing'] ?? 0).toDouble(),
        receivedCashing: (json['received_cashing'] ?? 0).toDouble(),
        variance: (json['variance'] ?? 0).toDouble(),
        transactionId: json['transaction_id'],
        debtBalance: (json['debt_balance'] ?? 0).toDouble(),
        expenditure: (json['expenditure'] ?? 0).toDouble(),
        description: json['description'],
        createdByName: json['created_by_name'],
      );

  static List<CashingReportModel> mock = [
    CashingReportModel(
      id: 1, reportDate: DateTime.now(),
      expectedCashing: 12500, receivedCashing: 12500, variance: 0,
      transactionId: 'AM-2026-001', debtBalance: 0, expenditure: 450,
      description: 'Lusaka–Livingstone run, 50 passengers',
      createdByName: 'Miriam Banda',
    ),
    CashingReportModel(
      id: 2, reportDate: DateTime.now().subtract(const Duration(days: 1)),
      expectedCashing: 8500, receivedCashing: 8200, variance: -300,
      transactionId: 'AM-2026-002', debtBalance: 300, expenditure: 320,
      description: 'Lusaka–Ndola, slight shortfall noted',
      createdByName: 'Miriam Banda',
    ),
    CashingReportModel(
      id: 3, reportDate: DateTime.now().subtract(const Duration(days: 2)),
      expectedCashing: 17000, receivedCashing: 17000, variance: 0,
      transactionId: 'MTN-2026-003', debtBalance: 0, expenditure: 600,
      description: 'Lusaka–Johannesburg, full bus',
      createdByName: 'Joseph Tembo',
    ),
  ];
}
