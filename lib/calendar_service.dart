// lib/calendar_service.dart
import 'reservation.dart';
import 'package:device_calendar/device_calendar.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Future<List<Reservation>> fetchReservations() async {
    // 権限チェック
    var permissions = await _deviceCalendarPlugin.hasPermissions();
    if (!(permissions.data ?? false)) {
      await _deviceCalendarPlugin.requestPermissions();
    }

    // カレンダー一覧取得
    var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    var calendars = calendarsResult.data;
    if (calendars == null || calendars.isEmpty) return [];

    // 最初のカレンダーから予定取得
    var eventsResult = await _deviceCalendarPlugin.retrieveEvents(
      calendars.first.id,
      RetrieveEventsParams(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      ),
    );

    // Event → Reservation に変換
    return eventsResult.data?.where((event) =>
        event.start != null && event.end != null).map((event) {
      return Reservation(
        title: event.title ?? '予定',
        place: event.location ?? '',
        startTime: event.start!,
        duration: event.end!.difference(event.start!),
        memo: event.description,
      );
    }).toList() ?? [];
  }
}
