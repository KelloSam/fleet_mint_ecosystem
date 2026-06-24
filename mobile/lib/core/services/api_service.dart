import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // AUTH
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DASHBOARD
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await _dio.get('/api/dashboard/stats');
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // OPERATORS
  Future<List<dynamic>> getOperators() async {
    try {
      final res = await _dio.get('/api/operators');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // SCHEDULES (public — for a specific operator)
  Future<List<dynamic>> getOperatorSchedules(String slug) async {
    try {
      final res = await _dio.get('/api/operators/$slug/schedules');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // SCHEDULES (staff — all schedules)
  Future<List<dynamic>> getAllSchedules({String? date}) async {
    try {
      final res = await _dio.get('/api/schedules', queryParameters: date != null ? {'date': date} : null);
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSchedule(String id) async {
    try {
      final res = await _dio.get('/api/schedules/$id');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // SEAT AVAILABILITY
  Future<List<dynamic>> getTakenSeats(String scheduleId, String date) async {
    try {
      final res = await _dio.get('/api/schedules/$scheduleId/seats', queryParameters: {'date': date});
      return res.data['taken_seats'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // BOOKINGS (public)
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/bookings', data: data);
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTicket(String reference) async {
    try {
      final res = await _dio.get('/api/bookings/$reference');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // TRACKING
  Future<Map<String, dynamic>> trackBooking(String reference) async {
    try {
      final res = await _dio.get('/api/track/$reference');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // BOOKINGS (staff)
  Future<List<dynamic>> getAllBookings({String? date, String? status}) async {
    try {
      final res = await _dio.get('/api/admin/bookings', queryParameters: {
        if (date != null) 'date': date,
        if (status != null) 'status': status,
      });
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateBookingStatus(String reference, String status) async {
    try {
      await _dio.patch('/api/admin/bookings/$reference', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // LOCATION UPDATE
  Future<void> postLocationUpdate(String scheduleId, Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/schedules/$scheduleId/location', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FLEET
  Future<List<dynamic>> getVehicles() async {
    try {
      final res = await _dio.get('/api/fleet/vehicles');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getRoutes() async {
    try {
      final res = await _dio.get('/api/fleet/routes');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FINANCE
  Future<List<dynamic>> getCashingReports({String? date}) async {
    try {
      final res = await _dio.get('/api/finance/cashing_reports', queryParameters: date != null ? {'date': date} : null);
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createCashingReport(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/finance/cashing_reports', data: data);
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getExpenditures({String? fromDate, String? toDate}) async {
    try {
      final res = await _dio.get('/api/finance/expenditures', queryParameters: {
        if (fromDate != null) 'from': fromDate,
        if (toDate != null) 'to': toDate,
      });
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ON DUTY STAFF
  Future<List<dynamic>> getOnDutyStaff() async {
    try {
      final res = await _dio.get('/api/staff/on_duty');
      return res.data['data'] ?? res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) return data['error'];
      if (data is Map && data.containsKey('message')) return data['message'];
      return 'Server error (${e.response!.statusCode})';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet.';
    }
    return 'Network error. Please try again.';
  }
}
