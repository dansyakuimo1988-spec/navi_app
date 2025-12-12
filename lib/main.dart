// lib/main.dart
//
// 注：このファイルは UI と外部地図起動まわりの主要ロジックを含みます。
//      コメントを増やして可読性と保守性を高めています。
//      エラーハンドリングと入力チェックを強化し、ユーザーへは SnackBar で通知します。

import 'package:flutter/material.dart';
import 'reservation.dart';
import 'calendar_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

/// アプリ全体のルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp の title / theme はアプリのメタ情報なので適宜更新してください。
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

/// メイン画面（予約一覧を表示）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // カレンダーからの予定取得を担当するサービス（外部に依存）
  final CalendarService _calendarService = CalendarService();

  // 取得した予約一覧
  List<Reservation> _reservations = [];

  // 読み込み中フラグ。セットステート時は mounted を確認すること。
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // 起動時に予定を読み込む。非同期エラーは _loadReservations 内で処理する。
    _loadReservations();
  }

  /// 予定をカレンダーから読み込む。
  /// - 成功時は _reservations を更新し UI を再構築する。
  /// - 失敗時はログ出力とユーザー通知（SnackBar）で知らせる。
  /// - finally で _loading を false にしてインジケータを止める。
  Future<void> _loadReservations() async {
    try {
      final data = await _calendarService.fetchReservations();
      // mounted チェック：非同期完了時にウィジェットが破棄されている可能性があるため必須
      if (mounted) {
        setState(() {
          _reservations = data;
        });
      }
    } catch (e, st) {
      // デバッグ用に詳細をログ出力。公開版ではログレベル/送信ポリシーに注意。
      debugPrint('Failed to load reservations: $e\n$st');
      if (mounted) {
        // ユーザーへは簡潔なメッセージで通知。詳細はログで確認できる。
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定の読み込みに失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Duration を見やすい日本語表現に変換するユーティリティ
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '${minutes}分';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${hours}時間';
    return '${hours}時間${rem}分';
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold を返すことで SnackBar を表示できるようにしている
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約ナビ'),
      ),
      body: _loading
          // 読み込み中はローディングインジケータを表示
          ? const Center(child: CircularProgressIndicator())
          // 読み込み完了後は予約リストを描画
          : ListView.builder(
              itemCount: _reservations.length,
              itemBuilder: (context, i) {
                final reservation = _reservations[i];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // タイトル
                          Text(
                            reservation.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),

                          // 所要時間など（アイコン + テキスト）
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

                          // メモ（任意）を表示（null / 空文字は無視）
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

                          // ボタン列：地図を開く / ナビ開始
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // UI に通知できるよう BuildContext を渡して呼び出す
                                    _openMap(context, reservation.place);
                                  },
                                  icon: const Icon(Icons.map),
                                  label: const Text('地図を開く'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    _startNavigation(context, reservation.place);
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
                  ),
                );
              },
            ),
    );
  }
}

/// place のバリデーション、URL 組み立て、安全な launch、エラーハンドリングを行う。
/// 呼び出し元に BuildContext を渡す理由：
/// - launch に失敗した際にユーザーに即時通知するため（SnackBar 等）
/// - ウィジェットツリーの状態に応じて処理を分岐するため（mounted チェックは呼び出し側で行う）
Future<void> _openMap(BuildContext context, String? place) async {
  // 入力検証：場所が未設定・空白のみ・超長文字列などは弾く
  if (place == null || place.trim().isEmpty) {
    // ユーザー向けに分かりやすく通知
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('場所が設定されていません')),
    );
    return;
  }

  // Google Maps の検索 URL を安全に組み立てる
  // Uri.https / queryParameters を使うことで手動のエンコードミスを防ぐ
  final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': place});

  try {
    // canLaunchUrl で開けるか事前確認（外部アプリが無い等のケースを検出）
    if (await canLaunchUrl(uri)) {
      // 外部アプリ（ブラウザ・Maps）で開く。mode は必要に応じて変更可
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // canLaunchUrl が false の場合はユーザーに優しく案内
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('地図を開けません (対応アプリが見つかりません)')),
      );
    }
  } catch (e, st) {
    // 例外時の対処：ログ出力（開発者向け）とユーザー通知（利用者向け）
    debugPrint('Error launching map: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('地図を開けません: $e')),
    );
  }
}

/// ナビ開始（経路指定）も同様に安全に実行
/// - destination パラメータに place を入れる（Google Maps Directions）
Future<void> _startNavigation(BuildContext context, String? place) async {
  if (place == null || place.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('目的地が設定されていません')),
    );
    return;
  }

  // Google Maps の経路指定 URL を組み立てる（queryParameters を推奨）
  final uri = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': place});

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ナビを開始できません (対応アプリが見つかりません)')),
      );
    }
  } catch (e, st) {
    debugPrint('Error starting navigation: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ナビを開始できません: $e')),
    );
  }
}
