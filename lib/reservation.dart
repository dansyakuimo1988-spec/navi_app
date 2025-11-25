// lib/reservation.dart
class Reservation {
  final String title; // 予約タイトル
  final String place; // 場所（施設名や住所）
  final DateTime startTime; // 開始日時
  final Duration duration; // 所要時間
  final String? memo; // メモ（任意）

  const Reservation({
    required this.title,
    required this.place,
    required this.startTime,
    required this.duration,
    this.memo,
  });
}
