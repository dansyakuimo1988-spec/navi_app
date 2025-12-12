// lib/main.dart
import 'package:flutter/material.dart';
import 'reservation.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CalendarService _calendarService = CalendarService();
  List<Reservation> _reservations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final data = await _calendarService.fetchReservations();
    setState(() {
      _reservations = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日の予約')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('予定はありません'))
              : ListView.builder(
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    return ReservationCard(reservation: _reservations[index]);
                  },
                ),
    );
  }
}
// 予約を見やすく表示するカードUI
class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  const ReservationCard({super.key, required this.reservation});

  String _formatDateTime(DateTime dt) {
    // シンプルな日本語フォーマット（後でintl導入してもOK）
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  String _formatDuration(Duration dur) {
    if (dur.inHours >= 1 && dur.inMinutes % 60 != 0) {
      return '${dur.inHours}時間${dur.inMinutes % 60}分';
    } else if (dur.inHours >= 1) {
      return '${dur.inHours}時間';
    }
    return '${dur.inMinutes}分';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル行
            Row(
              children: [
                const Icon(Icons.event, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 場所
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation.place,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 開始時間
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(reservation.startTime),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 所要時間
            Row(
              children: [
                const Icon(Icons.timelapse, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(reservation.duration),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // メモ（任意）
            if (reservation.memo != null && reservation.memo!.isNotEmpty) ...[
              Text(
                'メモ',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.indigo),
              ),
              const SizedBox(height: 4),
              Text(
                reservation.memo!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],

            // ボタン列
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _openMap(reservation.place);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('地図を開く'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _startNavigation(reservation.place);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('ナビ開始'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMap(String place) async {
  final query = Uri.encodeComponent(place);
  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw '地図を開けません: $url';
  }
}

Future<void> _startNavigation(String place) async {
  // 目的地をURLに組み込む
  final query = Uri.encodeComponent(place);
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$query',
  );

  // URLを開けるか確認してから実行
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'ナビを開始できません: $url';
  }
}
