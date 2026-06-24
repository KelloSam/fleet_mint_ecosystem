import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/services/api_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<CashingReportModel> _cashingReports = [];
  List<ExpenditureModel> _expenditures = [];
  bool _isLoading = false;
  String? _error;

  List<CashingReportModel> get cashingReports => _cashingReports;
  List<ExpenditureModel> get expenditures => _expenditures;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalExpected => _cashingReports.fold(0, (s, r) => s + r.expectedCashing);
  double get totalReceived => _cashingReports.fold(0, (s, r) => s + r.receivedCashing);
  double get totalVariance => _cashingReports.fold(0, (s, r) => s + r.variance);
  double get totalExpenditures => _expenditures.fold(0, (s, e) => s + e.amount);

  Future<void> loadCashingReports({String? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getCashingReports(date: date);
      _cashingReports = data.map((e) => CashingReportModel.fromJson(e)).toList();
    } catch (_) {
      _cashingReports = CashingReportModel.mock;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExpenditures() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getExpenditures();
      _expenditures = data.map((e) => ExpenditureModel.fromJson(e)).toList();
    } catch (_) {
      _expenditures = ExpenditureModel.mock;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCashingReport(Map<String, dynamic> data) async {
    try {
      await ApiService().createCashingReport(data);
      await loadCashingReports();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
