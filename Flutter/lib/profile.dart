import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F6F6), // アプリ全体の背景色
        fontFamily: 'sans-serif',
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 編集用のコントローラー
  final TextEditingController _nameController = TextEditingController(text: '名前');
  final TextEditingController _idController = TextEditingController(text: 'ID');
  final TextEditingController _regionController = TextEditingController(text: '居住地域');
  final TextEditingController _bioController =
      TextEditingController(text: '自己紹介欄');

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _regionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color grayBoxColor = Color(0xFFD9D9D9); // ワイヤーフレーム風のグレー

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ページタイトル
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'プロフィール',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),

            // メインスクロールエリア
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー編集エリア
                    Container(
                      width: double.infinity,
                      height: 90,
                      color: grayBoxColor,
                      alignment: Alignment.center,
                      child: const Text(
                        'ヘッダー編集',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // アイコン ＆ 基本情報（名前・ID・居住地域）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // アイコン（円）
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: grayBoxColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'アイコン',
                            style: TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 名前、ID、居住地域
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 名前
                              Container(
                                width: double.infinity,
                                height: 28,
                                color: grayBoxColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ID
                              Container(
                                width: double.infinity,
                                height: 28,
                                color: grayBoxColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: _idController,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 居住地域（画像通り幅を短めに配置）
                              FractionallySizedBox(
                                widthFactor: 0.65,
                                child: Container(
                                  height: 28,
                                  color: grayBoxColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _regionController,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 自己紹介欄
                    Container(
                      width: double.infinity,
                      height: 120,
                      color: grayBoxColor,
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.topLeft,
                      child: TextField(
                        controller: _bioController,
                        maxLines: null,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // レベル & 次のレベルまで
                    Row(
                      children: [
                        // レベル（円）
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: grayBoxColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'レベル',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          '次のレベルまで：○日',
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 獲得したバッチ
                    Container(
                      width: double.infinity,
                      color: grayBoxColor,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '獲得したバッチ',
                            style: TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          // 3x3の星アイコン
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 9,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemBuilder: (context, index) {
                              return const Icon(
                                Icons.star,
                                size: 52,
                                color: Color(0xFF222222), // 写真通りの黒色星マーク
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ボトムナビゲーションバー（TL / ワークアウト / プロフ）
            Container(
              width: double.infinity,
              height: 70,
              color: grayBoxColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItem('TL'),
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

  // ボトムナビゲーション用の白円ボタン
  Widget _buildBottomNavItem(String label) {
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
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }
}