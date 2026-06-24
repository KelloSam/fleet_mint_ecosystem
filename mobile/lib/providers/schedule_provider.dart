import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/services/api_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleModel> _schedules = [];
  List<BookingModel> _bookings = [];
  ScheduleModel? _selectedSchedule;
  bool _isLoading = false;
  String? _error;
  String? _selectedDate;

  List<ScheduleModel> get schedules => _schedules;
  List<BookingModel> get bookings => _bookings;
  ScheduleModel? get selectedSchedule => _selectedSchedule;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getAllSchedules(date: _selectedDate);
      _schedules = data.map((e) => ScheduleModel.fromJson(e)).toList();
    } catch (_) {
      _schedules = [
        ...ScheduleModel.mockFor('madithel'),
        ...ScheduleModel.mockFor('jordan'),
      ].take(8).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadScheduleDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getSchedule(id);
      _selectedSchedule = ScheduleModel.fromJson(data);
    } catch (_) {
      _selectedSchedule = ScheduleModel.mockFor('madithel').first;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBookings({String? date, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getAllBookings(date: date, status: status);
      _bookings = data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (_) {
      _bookings = BookingModel.mockToday;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> postLocationUpdate(String scheduleId, String location, {String? notes}) async {
    try {
      await ApiService().postLocationUpdate(scheduleId, {
        'location': location,
        'notes': notes,
      });
      await loadScheduleDetail(scheduleId);
      return true;
    } catch (_) {
      // Mock update applied locally
      if (_selectedSchedule != null) {
        final update = LocationUpdateModel(
          id: DateTime.now().millisecondsSinceEpoch,
          location: location,
          notes: notes,
          postedAt: DateTime.now(),
          postedByName: 'You',
        );
        final updated = [update, ..._selectedSchedule!.locationUpdates];
        _selectedSchedule = ScheduleModel(
          id: _selectedSchedule!.id,
          code: _selectedSchedule!.code,
          operator: _selectedSchedule!.operator,
          route: _selectedSchedule!.route,
          vehicle: _selectedSchedule!.vehicle,
          departureTime: _selectedSchedule!.departureTime,
          estimatedArrivalTime: _selectedSchedule!.estimatedArrivalTime,
          fare: _selectedSchedule!.fare,
          availableSeats: _selectedSchedule!.availableSeats,
          daysOfOperation: _selectedSchedule!.daysOfOperation,
          status: _selectedSchedule!.status,
          notes: _selectedSchedule!.notes,
          locationUpdates: updated,
        );
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> updateBookingStatus(String reference, String status) async {
    try {
      await ApiService().updateBookingStatus(reference, status);
      await loadBookings();
      return true;
    } catch (_) {
      _bookings = _bookings.map((b) {
        if (b.reference == reference) {
          return BookingModel(
            id: b.id, reference: b.reference, passengerName: b.passengerName,
            passengerPhone: b.passengerPhone, seatNumber: b.seatNumber,
            travelDate: b.travelDate, farePaid: b.farePaid,
            paymentMethod: b.paymentMethod, status: status, createdAt: b.createdAt,
          );
        }
        return b;
      }).toList();
      notifyListeners();
      return true;
    }
  }
}
