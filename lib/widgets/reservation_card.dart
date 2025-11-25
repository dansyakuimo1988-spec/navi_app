import 'package:flutter/material.dart';
import '../reservation.dart';
import '../utils/map_utils.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  const ReservationCard({super.key, required this.reservation});

  String _formatDateTime(DateTime dt) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reservation.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(reservation.place),
            Text(_formatDateTime(reservation.startTime)),
            Text(_formatDuration(reservation.duration)),
            if (reservation.memo != null) Text(reservation.memo!),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => openMap(reservation.place),
                  icon: const Icon(Icons.map),
                  label: const Text('地図を開く'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => startNavigation(reservation.place),
                  icon: const Icon(Icons.navigation),
                  label: const Text('ナビ開始'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
