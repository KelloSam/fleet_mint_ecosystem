import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<OperatorModel> _operators = [];
  List<ScheduleModel> _schedules = [];
  List<int> _takenSeats = [];
  BookingModel? _currentBooking;
  bool _isLoading = false;
  String? _error;

  // Booking form state
  ScheduleModel? _selectedSchedule;
  DateTime _selectedDate = DateTime.now();
  int? _selectedSeat;
  String? _selectedPickupStation;
  String _passengerName = '';
  String _passengerPhone = '';
  String _passengerEmail = '';
  String _paymentMethod = 'Cash at Counter';

  List<OperatorModel> get operators => _operators;
  List<ScheduleModel> get schedules => _schedules;
  List<int> get takenSeats => _takenSeats;
  BookingModel? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ScheduleModel? get selectedSchedule => _selectedSchedule;
  DateTime get selectedDate => _selectedDate;
  int? get selectedSeat => _selectedSeat;
  String? get selectedPickupStation => _selectedPickupStation;
  String get passengerName => _passengerName;
  String get passengerPhone => _passengerPhone;
  String get passengerEmail => _passengerEmail;
  String get paymentMethod => _paymentMethod;

  Future<void> loadOperators() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getOperators();
      _operators = data.map((e) => OperatorModel.fromJson(e)).toList();
    } catch (_) {
      _operators = OperatorModel.mock;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedules(String operatorSlug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getOperatorSchedules(operatorSlug);
      _schedules = data.map((e) => ScheduleModel.fromJson(e)).toList();
    } catch (_) {
      _schedules = ScheduleModel.mockFor(operatorSlug);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTakenSeats(String scheduleId, String date) async {
    try {
      final data = await ApiService().getTakenSeats(scheduleId, date);
      _takenSeats = List<int>.from(data);
    } catch (_) {
      // Mock some taken seats
      _takenSeats = [1, 2, 5, 8, 12, 17, 23, 28, 31];
    }
    notifyListeners();
  }

  void selectSchedule(ScheduleModel schedule) {
    _selectedSchedule = schedule;
    _selectedSeat = null;
    _selectedPickupStation = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSeat = null;
    notifyListeners();
    if (_selectedSchedule != null) {
      loadTakenSeats(_selectedSchedule!.id.toString(),
          date.toIso8601String().split('T')[0]);
    }
  }

  void selectSeat(int seat) {
    _selectedSeat = _selectedSeat == seat ? null : seat;
    notifyListeners();
  }

  void selectPickupStation(String? station) {
    _selectedPickupStation = station;
    notifyListeners();
  }

  void setPassengerDetails({
    required String name,
    required String phone,
    String email = '',
  }) {
    _passengerName = name;
    _passengerPhone = phone;
    _passengerEmail = email;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<BookingModel?> confirmBooking() async {
    if (_selectedSchedule == null || _selectedSeat == null) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService().createBooking({
        'schedule_id': _selectedSchedule!.id,
        'travel_date': _selectedDate.toIso8601String().split('T')[0],
        'seat_number': _selectedSeat,
        'pickup_station': _selectedPickupStation,
        'passenger_name': _passengerName,
        'passenger_phone': _passengerPhone,
        'passenger_email': _passengerEmail.isNotEmpty ? _passengerEmail : null,
        'payment_method': _paymentMethod,
      });
      _currentBooking = BookingModel.fromJson(data);
    } catch (_) {
      // Mock booking confirmation
      _currentBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch,
        reference: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        passengerName: _passengerName,
        passengerPhone: _passengerPhone,
        passengerEmail: _passengerEmail.isNotEmpty ? _passengerEmail : null,
        seatNumber: _selectedSeat!,
        pickupStation: _selectedPickupStation,
        travelDate: _selectedDate,
        farePaid: _selectedSchedule!.fare,
        paymentMethod: _paymentMethod,
        status: 'confirmed',
        createdAt: DateTime.now(),
        schedule: _selectedSchedule,
      );
    }

    _isLoading = false;
    notifyListeners();
    return _currentBooking;
  }

  Future<BookingModel?> getTicket(String reference) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService().getTicket(reference);
      _currentBooking = BookingModel.fromJson(data);
    } catch (_) {
      _currentBooking = BookingModel.mockToday.firstWhere(
        (b) => b.reference == reference,
        orElse: () => BookingModel.mockToday.first,
      );
    }

    _isLoading = false;
    notifyListeners();
    return _currentBooking;
  }

  void resetBookingForm() {
    _selectedSchedule = null;
    _selectedDate = DateTime.now();
    _selectedSeat = null;
    _selectedPickupStation = null;
    _passengerName = '';
    _passengerPhone = '';
    _passengerEmail = '';
    _paymentMethod = 'Cash at Counter';
    _takenSeats = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
