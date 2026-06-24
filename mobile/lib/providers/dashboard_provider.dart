import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  int _todayBookings = 0;
  double _todayRevenue = 0;
  int _totalVehicles = 0;
  int _activeSchedules = 0;
  List<UserModel> _onDutyStaff = [];
  List<BookingModel> _recentBookings = [];
  List<Map<String, dynamic>> _weeklyRevenue = [];
  bool _isLoading = false;
  String? _error;

  int get todayBookings => _todayBookings;
  double get todayRevenue => _todayRevenue;
  int get totalVehicles => _totalVehicles;
  int get activeSchedules => _activeSchedules;
  List<UserModel> get onDutyStaff => _onDutyStaff;
  List<BookingModel> get recentBookings => _recentBookings;
  List<Map<String, dynamic>> get weeklyRevenue => _weeklyRevenue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stats = await ApiService().getDashboardStats();
      _todayBookings = stats['today_bookings'] ?? 0;
      _todayRevenue = (stats['today_revenue'] ?? 0).toDouble();
      _totalVehicles = stats['total_vehicles'] ?? 0;
      _activeSchedules = stats['active_schedules'] ?? 0;
    } catch (_) {
      _loadMockData();
    }

    try {
      final staffList = await ApiService().getOnDutyStaff();
      _onDutyStaff = staffList.map((e) => UserModel.fromJson(e)).toList();
    } catch (_) {
      _onDutyStaff = UserModel.mockOnDutyStaff;
    }

    try {
      final bookings = await ApiService().getAllBookings(
        date: DateTime.now().toIso8601String().split('T')[0],
      );
      _recentBookings = bookings.map((e) => BookingModel.fromJson(e)).toList();
    } catch (_) {
      _recentBookings = BookingModel.mockToday;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadMockData() {
    _todayBookings = 47;
    _todayRevenue = 28350;
    _totalVehicles = 12;
    _activeSchedules = 8;
    _weeklyRevenue = [
      {'day': 'Mon', 'revenue': 22400.0},
      {'day': 'Tue', 'revenue': 31200.0},
      {'day': 'Wed', 'revenue': 18900.0},
      {'day': 'Thu', 'revenue': 27600.0},
      {'day': 'Fri', 'revenue': 45800.0},
      {'day': 'Sat', 'revenue': 52300.0},
      {'day': 'Sun', 'revenue': 38700.0},
    ];
  }
}
