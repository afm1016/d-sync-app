import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ==================================================
// メインナビゲーション (IndexedStackで状態を完全保持)
// ==================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // 初期選択は「ワークアウト」

  final List<Widget> _screens = const [
    TimelineScreen(),
    WorkoutScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'TL',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'ワークアウト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフ',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 1. TL (タイムライン) 画面
// ==================================================
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color grayBoxColor = Color(0xFFD9D9D9);

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '写真＋コメントTL',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            color: grayBoxColor,
            alignment: Alignment.center,
            child: const Text('ロゴ', style: TextStyle(fontSize: 16)),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.black,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: 'Sync'),
                Tab(text: 'ログ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineList(grayBoxColor, isLogTab: false),
                _buildTimelineList(grayBoxColor, isLogTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(Color grayBoxColor, {required bool isLogTab}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        if (isLogTab) {
          return CarouselPostCard(grayBoxColor: grayBoxColor, index: index);
        } else {
          return _buildStandardPostCard(context, grayBoxColor, index);
        }
      },
    );
  }

  Widget _buildStandardPostCard(
      BuildContext context, Color grayBoxColor, int index) {
    final String userName = 'ユーザー名 ${index + 1}';
    final String userId = 'ID_${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(context, grayBoxColor, userName, userId),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            color: grayBoxColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  alignment: Alignment.center,
                  child: Text('投稿した写真 ${index + 1}',
                      style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 20),
                const Text('投稿主からのコメント'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.favorite_border,
                            size: 18, color: Colors.black87),
                        SizedBox(width: 4),
                        Text('12',
                            style: TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showCommentsBottomSheet(context, userName),
                      child: Row(
                        children: const [
                          Icon(Icons.chat_bubble_outline,
                              size: 18, color: Colors.black87),
                          SizedBox(width: 4),
                          Text('3',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, String postOwner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('$postOwner さんの投稿へのコメント',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: const [
                      ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Color(0xFFD9D9D9),
                            child: Icon(Icons.person, size: 20)),
                        title: Text('ランナーA',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('お疲れ様です！'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Color(0xFFD9D9D9),
                            child: Icon(Icons.person, size: 20)),
                        title: Text('ランナーB',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('ナイスラン！'),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'コメントを入力...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CarouselPostCard extends StatefulWidget {
  final Color grayBoxColor;
  final int index;

  const CarouselPostCard(
      {super.key, required this.grayBoxColor, required this.index});

  @override
  State<CarouselPostCard> createState() => _CarouselPostCardState();
}

class _CarouselPostCardState extends State<CarouselPostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(context, widget.grayBoxColor,
              'ワークアウトログ ${widget.index + 1}', 'ID_${widget.index + 1}'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            color: widget.grayBoxColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        children: [
                          _buildSlide(Icons.map, '1. ランニング移動経路',
                              '走行距離: 5.2 km\nタイム: 28分30秒'),
                          _buildSlide(Icons.fitness_center, '2. 筋トレ種目',
                              '・ベンチプレス 60kg × 10回\n・スクワット 80kg × 8回'),
                          _buildSlide(Icons.photo_camera, '3. 投稿した写真',
                              '📷 トレーニング後の写真'),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('${_currentPage + 1}/3',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 8 : 6,
                            height: _currentPage == i ? 8 : 6,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == i
                                    ? Colors.black
                                    : Colors.black26),
                          )),
                ),
                const SizedBox(height: 12),
                const Text('投稿主からのコメント:\n今日も順調に運動完了！'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.favorite_border,
                            size: 18, color: Colors.black87),
                        SizedBox(width: 4),
                        Text('8',
                            style: TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            size: 18, color: Colors.black87),
                        SizedBox(width: 4),
                        Text('1',
                            style: TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(IconData icon, String title, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

Widget _buildUserHeader(
    BuildContext context, Color grayBoxColor, String userName, String userId) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserProfileScreen(userName: userName, userId: userId),
        ),
      );
    },
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: grayBoxColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('id',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    ),
  );
}

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userId;

  const UserProfileScreen(
      {super.key, required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color grayBoxColor = Color(0xFFD9D9D9);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 80,
                color: grayBoxColor,
                alignment: Alignment.center,
                child: const Text('ヘッダー', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: grayBoxColor, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('アイコン', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildReadOnlyField(userName, grayBoxColor),
                        const SizedBox(height: 8),
                        _buildReadOnlyField(userId, grayBoxColor),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 0.65,
                          child: _buildReadOnlyField('居住地域', grayBoxColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 100,
                color: grayBoxColor,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  '自己紹介欄',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                        color: grayBoxColor, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('レベル', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 16),
                  const Text('次のレベルまで：○日', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                color: grayBoxColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('獲得したバッチ', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 9,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) => const Icon(Icons.star,
                          size: 48, color: Color(0xFF222222)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, Color color) {
    return Container(
      height: 28,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

// ==================================================
// 2. ワークアウト 画面 (タイマー＆モード切替完全対応版)
// ==================================================
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isWorkoutStarted = false;
  bool _isRunningMode = true; // true = ランニング, false = 筋トレ

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // タイマーを開始・再開する
  void _startTimer() {
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    setState(() {
      _isWorkoutStarted = true;
    });
  }

  // 一時停止
  void _pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  // 終了・リセット
  void _resetTimer() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isWorkoutStarted = false;
      });
    }
  }

  // 時間のフォーマット処理 (例: 00:00.00)
  String _getFormattedTime() {
    final int milliseconds = _stopwatch.elapsedMilliseconds;
    final int minutes = milliseconds ~/ (1000 * 60);
    final int seconds = (milliseconds % (1000 * 60)) ~/ 1000;
    final int centiseconds = (milliseconds % 1000) ~/ 10;

    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    final String centisecondsStr = centiseconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr.$centisecondsStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String modeText = _isRunningMode ? 'ランニング' : '筋トレ';
    final String statusText = _isWorkoutStarted ? 'ワークアウト中' : 'ワークアウト前';

    return SafeArea(
      child: Column(
        children: [
          // 1. ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$statusText ($modeText)',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // 2. タイマー数値表示
          Container(
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              _getFormattedTime(),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // 3. 中央表示エリア (ランニングと筋トレで切り替え)
          Expanded(
            child: _isRunningMode ? _buildMapView() : _buildMuscleView(),
          ),

          // 4. 下部アクションボタン
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _isWorkoutStarted
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        _stopwatch.isRunning ? '一時停止' : '再開',
                        Colors.orange[200]!,
                        () {
                          if (_stopwatch.isRunning) {
                            _pauseTimer();
                          } else {
                            _startTimer();
                          }
                        },
                      ),
                      _buildActionButton(
                          'カメラ\n(5分後)', Colors.blue[200]!, () {}),
                      _buildActionButton('終了', Colors.red[200]!, () {
                        _resetTimer();
                      }),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('モード\n切り替え', Colors.grey[300]!, () {
                        setState(() {
                          _isRunningMode = !_isRunningMode;
                        });
                      }),
                      _buildActionButton('スタート', Colors.green[300]!, () {
                        _startTimer();
                      }),
                      _buildActionButton(
                          '目標設定・\nAI', Colors.grey[300]!, () {}),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // マップ表示ビュー
  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.map, size: 100, color: Colors.grey[400]),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Icon(Icons.my_location, color: Colors.blue, size: 36),
                SizedBox(height: 8),
                Text(
                  'GPS現在地マップエリア',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 筋トレ表示ビュー
  Widget _buildMuscleView() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('本日の筋トレメニュー',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildMuscleItem('プッシュアップ', '3セット × 10回'),
          _buildMuscleItem('スクワット', '3セット × 15回'),
          _buildMuscleItem('クランチ（腹筋）', '3セット × 20回'),
          _buildMuscleItem('プランク', '3セット × 60秒'),
        ],
      ),
    );
  }

  Widget _buildMuscleItem(String title, String subtitle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.blueGrey),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 76,
      height: 76,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 3,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ==================================================
// 3. プロフィール 画面
// ==================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: '名前');
  final TextEditingController _idController = TextEditingController(text: 'ID');
  final TextEditingController _regionController =
      TextEditingController(text: '居住地域');
  final TextEditingController _bioController =
      TextEditingController(text: '自己紹介欄');

  @override
  Widget build(BuildContext context) {
    const Color grayBoxColor = Color(0xFFD9D9D9);

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('プロフィール', style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 80,
                    color: grayBoxColor,
                    alignment: Alignment.center,
                    child: const Text('ヘッダー編集', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            color: grayBoxColor, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child:
                            const Text('アイコン', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildField(_nameController, grayBoxColor),
                            const SizedBox(height: 8),
                            _buildField(_idController, grayBoxColor),
                            const SizedBox(height: 8),
                            FractionallySizedBox(
                              widthFactor: 0.65,
                              child:
                                  _buildField(_regionController, grayBoxColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: grayBoxColor,
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _bioController,
                      maxLines: null,
                      decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                            color: grayBoxColor, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child:
                            const Text('レベル', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 16),
                      const Text('次のレベルまで：○日', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    color: grayBoxColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('獲得したバッチ', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 9,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) => const Icon(Icons.star,
                              size: 48, color: Color(0xFF222222)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, Color color) {
    return Container(
      height: 28,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero),
      ),
    );
  }
}