// lib/calendar_service.dart
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'reservation.dart';

class CalendarService {
  Future<List<Reservation>> fetchReservations() async {
    if (kIsWeb) {
      // Webではカレンダー取得不可 → ダミー返す
      return [
        Reservation(
          title: 'Webではカレンダー未対応',
          place: 'ダミー',
          startTime: DateTime.now(),
          duration: const Duration(minutes: 30),
          memo: 'これはサンプルです',
        ),
      ];
    }

    // iOS/Android用の device_calendar 処理を書く場所
    // （ここは実機で動かすときに実装）
    final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

    Future<List<Reservation>> fetchReservations() async {
      // 権限チェック
      var permissions = await _deviceCalendarPlugin.hasPermissions();
      if (!(permissions.data ?? false)) {
        await _deviceCalendarPlugin.requestPermissions();
      }

      // カレンダー一覧
      var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      var calendars = calendarsResult.data;
      if (calendars == null || calendars.isEmpty) return [];
  
      // 予定取得（とりあえず最初のカレンダー）
      var eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendars.first.id,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      // Event → Reservation に変換
      return eventsResult.data?.map((event) {
        return Reservation(
          title: event.title ?? '予定',
          place: event.location ?? '',
          startTime: event.start!,
          duration: event.end!.difference(event.start!),
          memo: event.description,
        );
      }).toList() ?? [];
    }
    return [];
  }
}
