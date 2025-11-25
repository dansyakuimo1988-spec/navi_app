import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'reservation.dart'; // 予約モデル
import 'widgets/reservation_card.dart'; // 予約カードUI

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> showTestNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test Channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    'テスト通知',
    'これは通知のテストです',
    details,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const MyApp());

  // 起動時にテスト通知を出す
  await showTestNotification();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '予約ナビ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Reservation get reservation => Reservation(
    title: '歯医者の予約',
    place: '長岡市中央クリニック',
    startTime: DateTime(2025, 11, 20, 14, 0),
    duration: Duration(minutes: 30),
    memo: '診察券を忘れない',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日の予約')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ReservationCard(reservation: reservation),
      ),
    );
  }
}
