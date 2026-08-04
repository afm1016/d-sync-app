import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeLine Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const TimelineScreen(),
    );
  }
}

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 画面上部タイトル「写真＋コメントTL」
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '写真＋コメントTL',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),

            // ロゴヘッダー
            Container(
              width: double.infinity,
              height: 50,
              color: grayBoxColor,
              alignment: Alignment.center,
              child: const Text(
                'ロゴ',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            // TabBar（Sync / ログ の切り替え）
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

            // タブコンテンツエリア（Sync画面 / ログ画面）
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Sync タブ（従来の通常投稿）
                  _buildTimelineList(grayBoxColor, isLogTab: false),

                  // 2. ログ タブ（カルーセル投稿対応）
                  _buildTimelineList(grayBoxColor, isLogTab: true),
                ],
              ),
            ),

            // ボトムナビゲーション（TL / ワークアウト / プロフ）
            Container(
              width: double.infinity,
              height: 70,
              color: grayBoxColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItem('TL', isSelected: true),
                  _buildBottomNavItem('ワークアウト'),
                  _buildBottomNavItem('プロフ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // タイムラインのリスト表示
  Widget _buildTimelineList(Color grayBoxColor, {required bool isLogTab}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        if (isLogTab) {
          return CarouselPostCard(
            grayBoxColor: grayBoxColor,
            index: index,
          );
        } else {
          return _buildStandardPostCard(grayBoxColor, index);
        }
      },
    );
  }

  // Syncタブ用の標準投稿カード
  Widget _buildStandardPostCard(Color grayBoxColor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(grayBoxColor, 'ユーザー名'),
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
                  child: const Text('投稿した写真', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 20),
                const Text('投稿主からのコメント'),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // フッターの丸ボタン
  Widget _buildBottomNavItem(String label, {bool isSelected = false}) {
    return Container(
      width: label == 'ワークアウト' ? 90 : 60,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// 共通ユーザーヘッダー
Widget _buildUserHeader(Color grayBoxColor, String userName) {
  return Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: grayBoxColor,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            'id',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ],
  );
}

// いいね・コメントボタン
Widget _buildActionButtons() {
  return Row(
    children: const [
      Text('いいね', style: TextStyle(fontSize: 13, color: Colors.black87)),
      SizedBox(width: 16),
      Text('コメント', style: TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );
}

// --------------------------------------------------
// ログタブ用：カルーセル投稿カード（StatefulWidgetでページ状態を保持）
// --------------------------------------------------
class CarouselPostCard extends StatefulWidget {
  final Color grayBoxColor;
  final int index;

  const CarouselPostCard({
    super.key,
    required this.grayBoxColor,
    required this.index,
  });

  @override
  State<CarouselPostCard> createState() => _CarouselPostCardState();
}

class _CarouselPostCardState extends State<CarouselPostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
          // 1. ユーザーヘッダー
          _buildUserHeader(widget.grayBoxColor, 'ワークアウトログ ${widget.index + 1}'),

          const SizedBox(height: 10),

          // 2. カルーセルエリア（コンテナ）
          Container(
            width: double.infinity,
            color: widget.grayBoxColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カルーセル本体 (PageView)
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          // 1枚目：ランニング移動経路
                          _buildCardSlide(
                            icon: Icons.map_outlined,
                            title: '1. ランニング移動経路',
                            detail: '走行距離: 5.2 km\nタイム: 28分30秒\n平均ペース: 5\'28"/km',
                          ),
                          // 2枚目：筋トレ種目
                          _buildCardSlide(
                            icon: Icons.fitness_center,
                            title: '2. 筋トレ種目',
                            detail: '・ベンチプレス 60kg × 10回 3Set\n・スクワット 80kg × 8回 3Set\n・デッドリフト 90kg × 5回 2Set',
                          ),
                          // 3枚目：投稿写真
                          _buildCardSlide(
                            icon: Icons.photo_camera,
                            title: '3. 投稿した写真',
                            detail: '📷 トレーニング後の写真',
                          ),
                        ],
                      ),

                      // 右上のページカウント表示 (例: 1/3)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
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

                // ページインジケーター（インジケーターの丸ドット）
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 8 : 6,
                      height: _currentPage == index ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.black : Colors.black26,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // 投稿主のコメント
                const Text(
                  '投稿主からのコメント:\n今日もしっかりトレーニング完了！ランニングのあとに筋トレも頑張りました。',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),

                const SizedBox(height: 12),

                // アクションボタン（いいね・コメント）
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // カルーセルの1枚ごとのカードレイアウト
  Widget _buildCardSlide({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}