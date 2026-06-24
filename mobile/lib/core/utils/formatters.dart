import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Fmt {
  static final _zmw = NumberFormat.currency(locale: 'en_ZM', symbol: 'ZMW ', decimalDigits: 2);
  static final _date = DateFormat('dd MMM yyyy');
  static final _time = DateFormat('HH:mm');
  static final _dateTime = DateFormat('dd MMM yyyy · HH:mm');

  static String currency(double amount) => _zmw.format(amount);
  static String date(DateTime d) => _date.format(d);
  static String time(DateTime d) => _time.format(d);

  static String timeStr(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return _time.format(DateTime(2000, 1, 1, h, m));
    } catch (_) {
      return t;
    }
  }

  static String dateTime(DateTime d) => _dateTime.format(d);

  static String minutesToDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String staffId(int id) => 'STAFF-${id.toString().padLeft(4, '0')}';
  static String scheduleCode(int id) => 'SCH-${id.toString().padLeft(5, '0')}';
  static String bookingRef(int id) => 'BK-${id.toString().padLeft(7, '0')}';

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return date(dt);
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF43A047);
      case 'checked_in':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'no_show':
        return const Color(0xFFFB8C00);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }
}
