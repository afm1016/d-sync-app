import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ==================================================
// ログデータ共有用の簡易データストア
// ==================================================
class WorkoutLogItem {
  final String id;
  final String title;
  final List<LatLng> routePoints;
  final String distanceStr;
  final String durationStr;
  final DateTime date;

  WorkoutLogItem({
    required this.id,
    required this.title,
    required this.routePoints,
    required this.distanceStr,
    required this.durationStr,
    required this.date,
  });
}

class WorkoutLogStore {
  static final List<WorkoutLogItem> logs = [
    // デモ用初期データ
    WorkoutLogItem(
      id: '1',
      title: 'ワークアウトログ 1',
      routePoints: [
        const LatLng(35.681236, 139.767125),
        const LatLng(35.682236, 139.768125),
        const LatLng(35.683236, 139.769125),
      ],
      distanceStr: '2.5 km',
      durationStr: '15分20秒',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}

// ==================================================
// カラーパレット定義
// ==================================================
class AppThemeColors {
  static const Color primary = Color(0xFF2563EB); // メインブルー
  static const Color secondary = Color(0xFF10B981); // エメラルドグリーン
  static const Color accent = Color(0xFFF59E0B); // 琥珀色
  static const Color background = Color(0xFFF8FAFC); // ライトブルーグレー背景
  static const Color surface = Color(0xFFFFFFFF); // カード/フォーム背景
  static const Color text = Color(0xFF111827); // メインテキスト（濃紺グレー）
  static const Color border = Color(0xFFE5E7EB); // 境界線グレー
  static const Color success = Color(0xFF22C55E); // 成功グリーン
  static const Color error = Color(0xFFEF4444); // エラーレッド
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout & Community App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppThemeColors.background,
        primaryColor: AppThemeColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppThemeColors.primary,
          secondary: AppThemeColors.secondary,
          surface: AppThemeColors.surface,
          background: AppThemeColors.background,
          error: AppThemeColors.error,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppThemeColors.text,
          displayColor: AppThemeColors.text,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ==================================================
// A. ログイン画面
// ==================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_run_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'アカウントにログインして始めましょう',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 36),
                _buildTextField(
                  controller: _emailController,
                  label: 'メールアドレス',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'パスワード',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'パスワードをお忘れですか？',
                      style: TextStyle(
                        color: AppThemeColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ログイン',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeColors.secondary,
                      side: const BorderSide(
                        color: AppThemeColors.secondary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '新規アカウント作成',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _navigateToHome,
                  child: const Text(
                    'ログインせずに試す',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// B. 新規登録画面
// ==================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppThemeColors.text),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'アカウントを作成',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '必要な情報を入力してください',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _nameController,
                  label: 'ユーザー名',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'メールアドレス',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'パスワード',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '登録を完了する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'すでにアカウントをお持ちですか？',
                      style: TextStyle(fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'ログイン',
                        style: TextStyle(
                          color: AppThemeColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool isPassword = false,
}) {
  return TextField(
    controller: controller,
    obscureText: isPassword,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: AppThemeColors.primary),
      filled: true,
      fillColor: AppThemeColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppThemeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppThemeColors.primary, width: 2),
      ),
    ),
  );
}

// ==================================================
// メインナビゲーション
// ==================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    TimelineScreen(),
    WorkoutScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppThemeColors.surface,
        selectedItemColor: AppThemeColors.primary,
        unselectedItemColor: Colors.grey[400],
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフ'),
        ],
      ),
    );
  }
}

// 共通コメントBottomSheet表示関数
void showCommentsBottomSheet(BuildContext context, String postOwner) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppThemeColors.surface,
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
                    color: AppThemeColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$postOwner さんの投稿へのコメント',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.border,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: AppThemeColors.text,
                        ),
                      ),
                      title: Text(
                        'ランナーA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('お疲れ様です！'),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.border,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: AppThemeColors.text,
                        ),
                      ),
                      title: Text(
                        'ランナーB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppThemeColors.primary),
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
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '写真＋コメントTL',
              style: TextStyle(
                fontSize: 16,
                color: AppThemeColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            color: AppThemeColors.border,
            alignment: Alignment.center,
            child: const Text('ロゴ', style: TextStyle(fontSize: 16)),
          ),
          Container(
            color: AppThemeColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppThemeColors.primary,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: AppThemeColors.primary,
              indicatorWeight: 3,
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
                _buildTimelineList(isLogTab: false),
                _buildTimelineList(isLogTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList({required bool isLogTab}) {
    if (isLogTab) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: WorkoutLogStore.logs.length,
        itemBuilder: (context, index) {
          return CarouselPostCard(logItem: WorkoutLogStore.logs[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildStandardPostCard(context, index);
        },
      );
    }
  }

  Widget _buildStandardPostCard(BuildContext context, int index) {
    final String userName = 'ユーザー名 ${index + 1}';
    final String userId = 'ID_${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(context, userName, userId),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            color: AppThemeColors.border,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  alignment: Alignment.center,
                  child: Text(
                    '投稿した写真 ${index + 1}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('投稿主からのコメント'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.favorite,
                          size: 18,
                          color: AppThemeColors.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '12',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppThemeColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => showCommentsBottomSheet(context, userName),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: AppThemeColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '3',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeColors.text,
                            ),
                          ),
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
}

class CarouselPostCard extends StatefulWidget {
  final WorkoutLogItem logItem;

  const CarouselPostCard({super.key, required this.logItem});

  @override
  State<CarouselPostCard> createState() => _CarouselPostCardState();
}

class _CarouselPostCardState extends State<CarouselPostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isMapReady = false; // ★ マップ準備完了フラグ

  @override
  void initState() {
    super.initState();
    // わずかに遅延させてPageViewのレイアウトが落ち着いた後にマップを表示
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(
            context,
            widget.logItem.title,
            'ID_${widget.logItem.id}',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            color: AppThemeColors.border,
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
                          _buildMapSlide(widget.logItem),
                          _buildSlide(
                            Icons.fitness_center,
                            '2. 筋トレ種目',
                            '・ベンチプレス 60kg × 10回\n・スクワット 80kg × 8回',
                          ),
                          _buildSlide(
                            Icons.photo_camera,
                            '3. 投稿した写真',
                            '📷 トレーニング後の写真',
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1}/3',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
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
                            ? AppThemeColors.primary
                            : Colors.black26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('投稿主からのコメント:\n今日も順調に運動完了！経路を記録しました！'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.favorite,
                          size: 18,
                          color: AppThemeColors.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '8',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppThemeColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => showCommentsBottomSheet(
                        context,
                        widget.logItem.title,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: AppThemeColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '1',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeColors.text,
                            ),
                          ),
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

  // ログ用ミニマップ表示
  Widget _buildMapSlide(WorkoutLogItem item) {
    final bool hasPoints = item.routePoints.isNotEmpty;
    final LatLng initialCenter = hasPoints
        ? item.routePoints.first
        : const LatLng(35.681236, 139.767125);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      // ★ サイズ未確定によるエラーを防ぐため、準備完了前はローディングを表示
      child: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 14.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tatsuishi.workoutapp',
                    ),
                    if (hasPoints)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: item.routePoints,
                            strokeWidth: 4.0,
                            color: AppThemeColors.primary,
                          ),
                        ],
                      ),
                    if (hasPoints)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: item.routePoints.first,
                            width: 24,
                            height: 24,
                            child: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          Marker(
                            point: item.routePoints.last,
                            width: 24,
                            height: 24,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '走行距離: ${item.distanceStr}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'タイム: ${item.durationStr}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppThemeColors.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Widget _buildUserHeader(BuildContext context, String userName, String userId) {
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
          decoration: const BoxDecoration(
            color: AppThemeColors.border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              'id',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    ),
  );
}

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppThemeColors.text),
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
                color: AppThemeColors.border,
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
                      color: AppThemeColors.border,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('アイコン', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildReadOnlyField(userName),
                        const SizedBox(height: 8),
                        _buildReadOnlyField(userId),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 0.65,
                          child: _buildReadOnlyField('居住地域'),
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
                color: AppThemeColors.border,
                padding: const EdgeInsets.all(10),
                child: const Text('自己紹介欄', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppThemeColors.border,
                      shape: BoxShape.circle,
                    ),
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
                color: AppThemeColors.border,
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
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        size: 48,
                        color: AppThemeColors.accent,
                      ),
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

  Widget _buildReadOnlyField(String text) {
    return Container(
      height: 28,
      color: AppThemeColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ==================================================
// 2. ワークアウト 画面 (GPS & 移動経路トラッキング機能を追加)
// ==================================================
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

enum WorkoutMode { running, muscle }

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isWorkoutStarted = false;
  WorkoutMode _currentMode = WorkoutMode.running;
  bool _isMapReady = false; // ★ マップ準備完了フラグ

  Timer? _stopwatchTimer;
  int _elapsedMilliseconds = 0;
  bool _isTimerRunning = false;

  Timer? _cameraTimer;
  int _cameraRemainingSeconds = 0;
  bool _isCameraEnabled = false;

  // GPS / Map 関連変数
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng _currentLocation = const LatLng(35.681236, 139.767125); // 東京駅初期値
  final List<LatLng> _routePoints = []; // 走行経路の座標リスト
  double _totalDistanceMeters = 0.0; // 総移動距離（メートル）

  @override
  void initState() {
    super.initState();
    // ★ 画面の初期描画後にマップを有効化し、初期化エラーを防ぐ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _cameraTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // 位置情報権限の取得とリアルタイムトラッキング開始
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('位置情報サービスが無効になっています')));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('位置情報の権限が拒否されました')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('位置情報の権限が永久に拒否されています')));
      }
      return;
    }

    // 初回の現在地を取得
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newPos;
        _routePoints.add(newPos);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          try {
            _mapController.move(newPos, 16.5);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('位置情報取得エラー: $e');
    }

    // リアルタイムの位置情報変更を監視
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newPos = LatLng(position.latitude, position.longitude);
            setState(() {
              if (_routePoints.isNotEmpty) {
                double dist = Geolocator.distanceBetween(
                  _routePoints.last.latitude,
                  _routePoints.last.longitude,
                  newPos.latitude,
                  newPos.longitude,
                );
                _totalDistanceMeters += dist;
              }
              _currentLocation = newPos;
              _routePoints.add(newPos);
            });
            try {
              _mapController.move(newPos, 16.0);
            } catch (_) {}
          },
        );
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _startStopwatch() {
    if (!_isTimerRunning) {
      _isTimerRunning = true;
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (
        timer,
      ) {
        setState(() {
          _elapsedMilliseconds += 10;
        });
      });
    }
  }

  void _pauseStopwatch() {
    if (_isTimerRunning) {
      _isTimerRunning = false;
      _stopwatchTimer?.cancel();
      setState(() {});
    }
  }

  void _resetStopwatch() {
    _isTimerRunning = false;
    _stopwatchTimer?.cancel();
    setState(() {
      _elapsedMilliseconds = 0;
    });
  }

  String get _formattedTime {
    int minutes = (_elapsedMilliseconds ~/ 60000);
    int seconds = ((_elapsedMilliseconds % 60000) ~/ 1000);
    int hundredths = ((_elapsedMilliseconds % 1000) ~/ 10);

    String mStr = minutes.toString().padLeft(2, '0');
    String sStr = seconds.toString().padLeft(2, '0');
    String hStr = hundredths.toString().padLeft(2, '0');

    return "$mStr:$sStr.$hStr";
  }

  void _triggerCameraNotification() {
    _cameraTimer?.cancel();
    setState(() {
      _isCameraEnabled = true;
      _cameraRemainingSeconds = 300;
    });

    _cameraTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cameraRemainingSeconds > 0) {
        setState(() {
          _cameraRemainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCameraEnabled = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 カメラ撮影の通知が届きました！5分以内に撮影してください。'),
        backgroundColor: AppThemeColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _finishWorkout() {
    String distanceKm = (_totalDistanceMeters / 1000.0).toStringAsFixed(2);

    if (_routePoints.isNotEmpty) {
      WorkoutLogStore.logs.insert(
        0,
        WorkoutLogItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'ワークアウトログ ${WorkoutLogStore.logs.length + 1}',
          routePoints: List.from(_routePoints),
          distanceStr: '$distanceKm km',
          durationStr: _formattedTime.split('.').first,
          date: DateTime.now(),
        ),
      );
    }

    _stopLocationTracking();
    _resetStopwatch();
    _cameraTimer?.cancel();

    setState(() {
      _isWorkoutStarted = false;
      _isCameraEnabled = false;
      _routePoints.clear();
      _totalDistanceMeters = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 ワークアウトが終了し、TLログに保存されました！'),
        backgroundColor: AppThemeColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _isWorkoutStarted ? 'ワークアウト中' : 'ワークアウト前',
              style: const TextStyle(
                fontSize: 14,
                color: AppThemeColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 70,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_currentMode == WorkoutMode.running)
                  _isWorkoutStarted
                      ? (!_isMapReady
                            // ★ サイズ未確定によるエラーを防ぐため、準備完了前はローディングを表示
                            ? const Center(child: CircularProgressIndicator())
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _currentLocation,
                                  initialZoom: 16.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.tatsuishi.workoutapp',
                                  ),
                                  if (_routePoints.length >= 2)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _routePoints,
                                          strokeWidth: 5.0,
                                          color: AppThemeColors.primary,
                                        ),
                                      ],
                                    ),
                                  if (_routePoints.isNotEmpty)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _currentLocation,
                                          width: 30,
                                          height: 30,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppThemeColors.primary
                                                  .withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: AppThemeColors.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ))
                      : Container(
                          color: AppThemeColors.border,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'スタートを押すとマップが表示されます',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                else
                  Container(
                    color: AppThemeColors.background,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: AppThemeColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '今日の目標筋トレリスト',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: const [
                              _MuscleExerciseTile(
                                title: 'ベンチプレス',
                                subtitle: '3セット × 10回 (目標: 60kg)',
                              ),
                              _MuscleExerciseTile(
                                title: 'スクワット',
                                subtitle: '3セット × 12回 (目標: 80kg)',
                              ),
                              _MuscleExerciseTile(
                                title: 'デッドリフト',
                                subtitle: '3セット × 8回 (目標: 90kg)',
                              ),
                              _MuscleExerciseTile(
                                title: 'ダンベルショルダープレス',
                                subtitle: '3セット × 10回 (目標: 16kg)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 通知テストボタン (ワークアウト中のみ)
                if (_isWorkoutStarted)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ElevatedButton.icon(
                      onPressed: _triggerCameraNotification,
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text(
                        '通知テスト',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _isWorkoutStarted
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        _isTimerRunning ? '一時停止' : '再開',
                        AppThemeColors.accent,
                        () {
                          if (_isTimerRunning) {
                            _pauseStopwatch();
                          } else {
                            _startStopwatch();
                          }
                        },
                      ),
                      _buildCameraButton(),
                      _buildActionButton(
                        '終了',
                        AppThemeColors.error,
                        _finishWorkout,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        _currentMode == WorkoutMode.running
                            ? '筋トレ\nモード'
                            : 'ラン\nモード',
                        AppThemeColors.border,
                        () {
                          setState(() {
                            _currentMode = _currentMode == WorkoutMode.running
                                ? WorkoutMode.muscle
                                : WorkoutMode.running;
                          });
                        },
                      ),
                      _buildActionButton('スタート', AppThemeColors.secondary, () {
                        setState(() {
                          _isWorkoutStarted = true;
                          _isMapReady = false; // 一旦マップを非表示にしてローディング等を挟む
                        });
                        _startStopwatch();
                        _startLocationTracking();

                        // 0.1秒後にサイズが確定したとみなしてマップを表示し、コントローラーを動かす
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            setState(() {
                              _isMapReady = true;
                            });
                            try {
                              _mapController.move(_currentLocation, 16.0);
                            } catch (_) {}
                          }
                        });
                      }),
                      _buildActionButton(
                        '目標設定・\nAI',
                        AppThemeColors.border,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GoalSettingScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    String cameraText;
    if (_isCameraEnabled) {
      int m = _cameraRemainingSeconds ~/ 60;
      int s = _cameraRemainingSeconds % 60;
      cameraText =
          'カメラ\n(${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')})';
    } else {
      cameraText = 'カメラ\n(ロック)';
    }

    return GestureDetector(
      onTap: _isCameraEnabled
          ? () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('📷 パシャ！写真を撮影しました')));
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: _isCameraEnabled ? AppThemeColors.primary : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: _isCameraEnabled
              ? [
                  BoxShadow(
                    color: AppThemeColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            cameraText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isCameraEnabled ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    final bool isDark = color != AppThemeColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppThemeColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _MuscleExerciseTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MuscleExerciseTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppThemeColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppThemeColors.border),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppThemeColors.border,
          child: Icon(Icons.check, color: AppThemeColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

// ==================================================
// 3. プロフィール 画面 (フレンド追加機能拡張)
// ==================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController(
    text: 'MYID1234',
  );
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ プロフィール情報を保存しました！'),
        backgroundColor: AppThemeColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddFriendDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'フレンド追加',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppThemeColors.border,
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: AppThemeColors.primary,
                    ),
                  ),
                  title: const Text(
                    'QRコードリーダーで追加',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('カメラで相手のQRコードを読み取ります'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QrScannerScreen(myId: _idController.text),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppThemeColors.border,
                    child: Icon(
                      Icons.keyboard,
                      color: AppThemeColors.secondary,
                    ),
                  ),
                  title: const Text(
                    'IDを直打ちして追加',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('8文字の英数字IDを入力します'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showIdInputDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIdInputDialog() {
    final TextEditingController friendIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フレンドID入力'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('8文字の英数字IDを入力してください。入力が完了すると自動的にフレンド追加されます。'),
              const SizedBox(height: 16),
              TextField(
                controller: friendIdController,
                maxLength: 8,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'フレンドID (8文字)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (text) {
                  if (text.trim().length == 8) {
                    final String addedId = text.trim();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 ID: $addedId のユーザーをフレンドに追加しました！'),
                        backgroundColor: AppThemeColors.success,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'プロフィール',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                    color: AppThemeColors.border,
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
                          color: AppThemeColors.border,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'アイコン',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildField(_nameController, '名前'),
                            const SizedBox(height: 8),
                            _buildField(_idController, 'ID'),
                            const SizedBox(height: 8),
                            FractionallySizedBox(
                              widthFactor: 0.65,
                              child: _buildField(_regionController, '居住地域'),
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
                    color: AppThemeColors.border,
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _bioController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: '自己紹介欄',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppThemeColors.border,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'レベル',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('次のレベルまで：○日', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    color: AppThemeColors.border,
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
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            size: 48,
                            color: AppThemeColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'プロフィールを保存',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _showAddFriendDialog,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text(
                              'フレンド追加',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hintText) {
    return Container(
      height: 28,
      color: AppThemeColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ==================================================
// 3-A. QRコードスキャナー画面 & マイQR表示機能
// ==================================================
class QrScannerScreen extends StatefulWidget {
  final String myId;
  const QrScannerScreen({super.key, required this.myId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _showMyQrCodeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'マイQRコード',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'あなたのID: ${widget.myId.isEmpty ? "未設定" : widget.myId}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Center(
                child: QrImageView(
                  data: widget.myId.isEmpty ? 'USER_ID_DEFAULT' : widget.myId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QRコードを読み取る',
          style: TextStyle(color: AppThemeColors.text, fontSize: 16),
        ),
        backgroundColor: AppThemeColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppThemeColors.text),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  final String scannedData = barcode.rawValue!;

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 「$scannedData」 をフレンドに追加しました！'),
                      backgroundColor: AppThemeColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppThemeColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showMyQrCodeModal,
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text(
                  'マイQRコードを表示',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 4. 目標設定画面 (AI相談 / 手動設定)
// ==================================================
class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  bool _isManualMode = false;
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 60,
              color: AppThemeColors.border,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppThemeColors.text,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'ロゴ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isManualMode) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppThemeColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppThemeColors.border,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: const Text(
                                'AIからのコメント\n\n(例: 今日はどのようなトレーニングをしたい気分ですか？)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppThemeColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isManualMode = !_isManualMode;
                            _inputController.clear();
                          });
                        },
                        icon: Icon(
                          _isManualMode ? Icons.smart_toy : Icons.edit,
                          size: 18,
                        ),
                        label: Text(_isManualMode ? 'AIに相談するモードへ' : '自分で設定する'),
                        style: TextButton.styleFrom(
                          backgroundColor: AppThemeColors.border,
                          foregroundColor: AppThemeColors.text,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemeColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _inputController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isManualMode
                              ? 'テキストボックス\n\n(例: 今日は5km走る！)'
                              : 'テキストボックス\n\n(例: 今日は疲れているから軽めの運動にしたい)',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isManualMode
                                    ? '目標を設定しました！'
                                    : 'AIにメッセージを送信しました！',
                              ),
                              backgroundColor: AppThemeColors.primary,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isManualMode ? 'この目標で決定する' : 'AIに送信',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
