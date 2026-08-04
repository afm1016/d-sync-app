import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async'; // Timerを使用するためにインポート

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isWorkoutStarted = false; // ワークアウト中かどうかを管理するフラグ
  Stopwatch _stopwatch = Stopwatch(); // タイマーの時間を計測
  Timer? _timer; // タイマーの更新を管理
  String _elapsedTime = '00:00.00'; // 表示する経過時間

  @override
  void dispose() {
    _timer?.cancel(); // ウィジェットが破棄されるときにタイマーをキャンセル
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _elapsedTime = _formatTime(_stopwatch.elapsed);
      });
    });
  }

  void _pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopwatch.reset();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _elapsedTime = '00:00.00';
      _isWorkoutStarted = false; // ワークアウト状態もリセット
    });
  }

  String _formatTime(Duration duration) {
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    String milliseconds = (duration.inMilliseconds % 1000 ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isWorkoutStarted ? 'ワークアウト中' : 'ワークアウト前',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[200],
      ),
      body: Column(
        children: [
          // 1. タイマーエリア (上部)
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Text(
                _elapsedTime,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 2. マップエリア (中央)
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
              ],
            ),
          ),
          // 3. アクションボタンエリア (下部：状態によってボタンが切り替わる)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: _isWorkoutStarted
                ?
                  // 【ワークアウト中のボタン】一時停止、カメラ、終了
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('一時停止', Colors.orange[200]!, () {
                        setState(() {
                          _pauseTimer();
                        });
                      }),
                      _buildActionButton('カメラ\n(5分後)', Colors.blue[200]!, () {
                        // TODO: 写真撮影画面へ遷移する処理
                      }),
                      _buildActionButton('終了', Colors.red[200]!, () {
                        _resetTimer();
                      }),
                    ],
                  )
                :
                  // 【ワークアウト前のボタン】モード切り替え、スタート、目標設定・AI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('モード\n切り替え', Colors.grey[300]!, () {}),
                      _buildActionButton('スタート', Colors.green[300]!, () {
                        setState(() {
                          _isWorkoutStarted = true; // ワークアウト中に切り替える！
                          _startTimer();
                        });
                      }),
                      _buildActionButton('目標設定・\nAI', Colors.grey[300]!, () {}),
                    ],
                  ),
          ),
        ],
      ),
      // 4. 下部ナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'TL'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'ワークアウト',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフ'),
        ],
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  // ボタンをスッキリ作るためのパーツ（色をカスタマイズできるように変更）
  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
