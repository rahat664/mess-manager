import 'package:intl/intl.dart';

class DateFormatter {
  static final _dayFormat = DateFormat('yyyy-MM-dd');
  static final _monthFormat = DateFormat('yyyy-MM');

  static String dayString(DateTime date) => _dayFormat.format(date);
  static String monthString(DateTime date) => _monthFormat.format(date);
}
