/// Tiện ích cho planner routine 7 ngày (T2–CN, index 0–6).
abstract final class WeeklyPlannerUtils {
  static const weekDayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// Thứ trong tuần hiện tại: 0 = T2 (Monday), 6 = CN (Sunday).
  static int get todayWeekIndex => (DateTime.now().weekday - 1) % 7;

  /// Chỉ cho phép setup các ngày sau hôm nay trong tuần.
  static bool isDayEditable(int dayIndex) => dayIndex > todayWeekIndex;

  /// Ngày mặc định khi mở planner — ngày sớm nhất có thể chỉnh.
  static int firstEditableDayIndex() {
    for (var i = 0; i < 7; i++) {
      if (isDayEditable(i)) return i;
    }
    return todayWeekIndex;
  }

  /// Backend dùng 1=Mon … 7=Sun.
  static int toApiDayOfWeek(int dayIndex) => dayIndex + 1;

  static int fromApiDayOfWeek(int apiDay) => apiDay - 1;

  static bool isCatalogRoutineId(String id) {
    final guid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return guid.hasMatch(id);
  }
}
