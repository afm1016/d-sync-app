import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ==================================================
// ガチャデータモデル & ステート管理
// ==================================================
enum Rarity { UR, SSR, SR, R }

extension RarityExtension on Rarity {
  String get label {
    switch (this) {
      case Rarity.UR:
        return 'UR';
      case Rarity.SSR:
        return 'SSR';
      case Rarity.SR:
        return 'SR';
      case Rarity.R:
        return 'R';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.UR:
        return const Color(0xFFFFD700);
      case Rarity.SSR:
        return const Color(0xFFA855F7);
      case Rarity.SR:
        return const Color(0xFF3B82F6);
      case Rarity.R:
        return const Color(0xFF10B981);
    }
  }
}

class GachaItemData {
  final String id;
  final String name;
  final Rarity rarity;
  final IconData icon;

  GachaItemData({
    required this.id,
    required this.name,
    required this.rarity,
    required this.icon,
  });
}

class UserState {
  static int userPoints = 60;
}

final List<GachaItemData> kGachaPool = [
  GachaItemData(id: '1', name: '伝説のフレーム', rarity: Rarity.UR, icon: Icons.military_tech),
  GachaItemData(id: '2', name: '黄金のスニーカー', rarity: Rarity.UR, icon: Icons.stars),
  GachaItemData(id: '3', name: '称号: 疾風迅雷', rarity: Rarity.SSR, icon: Icons.flash_on),
  GachaItemData(id: '4', name: 'ナイトラン背景', rarity: Rarity.SSR, icon: Icons.nightlight_round),
  GachaItemData(id: '5', name: '不屈のダイエッター', rarity: Rarity.SR, icon: Icons.fitness_center),
  GachaItemData(id: '6', name: 'ドリンクスタンプ', rarity: Rarity.SR, icon: Icons.local_drink),
  GachaItemData(id: '7', name: 'ナイスラン！バッジ', rarity: Rarity.R, icon: Icons.thumb_up_alt),
  GachaItemData(id: '8', name: '水分補給アイコン', rarity: Rarity.R, icon: Icons.water_drop),
];

// ==================================================
// 黒×青のフィルム缶を描画するCustomPainter
// ==================================================
class RealFilmCanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. 左側の引き出されたフィルム帯
    final filmPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.28)
      ..cubicTo(
        size.width * 0.15, size.height * 0.20,
        size.width * 0.05, size.height * 0.45,
        size.width * 0.12, size.height * 0.72,
      )
      ..lineTo(size.width * 0.38, size.height * 0.82)
      ..cubicTo(
        size.width * 0.22, size.height * 0.60,
        size.width * 0.28, size.height * 0.38,
        size.width * 0.45, size.height * 0.38,
      )
      ..close();

    final darkFilmPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    canvas.drawPath(filmPath, darkFilmPaint);

    // パーフォレーション（フィルムの穴）
    final holePaint = Paint()..color = Colors.white.withOpacity(0.85);
    for (int i = 0; i < 5; i++) {
      double dx = size.width * (0.13 + i * 0.045);
      double dy = size.height * (0.40 + i * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, 7, 10), const Radius.circular(1.5)),
        holePaint,
      );
    }

    // 2. パトローネ本体（ブラック）
    final canRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.16, size.width * 0.48, size.height * 0.68),
      const Radius.circular(16),
    );

    canvas.drawRRect(canRect, Paint()..color = const Color(0xFF0F172A));

    // 青色のアクセントラベル（右側）
    final blueLabelPath = Path()
      ..moveTo(size.width * 0.60, size.height * 0.16)
      ..lineTo(size.width * 0.86, size.height * 0.16)
      ..lineTo(size.width * 0.86, size.height * 0.84)
      ..lineTo(size.width * 0.60, size.height * 0.84)
      ..close();

    canvas.drawPath(
      blueLabelPath,
      Paint()..color = const Color(0xFF2563EB),
    );

    // 3. 上部スプールキャップ
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.48, size.height * 0.06, size.width * 0.28, size.height * 0.12),
      const Radius.circular(10),
    );
    canvas.drawRRect(capRect, Paint()..color = const Color(0xFF1E293B));

    final innerCapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.54, size.height * 0.03, size.width * 0.16, size.height * 0.06),
      const Radius.circular(4),
    );
    canvas.drawRRect(innerCapRect, Paint()..color = const Color(0xFF334155));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================================================
// ガチャ画面本体 (GachaScreen)
// ==================================================
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final int costOne = 3;
  final int costTen = 30;

  GachaItemData _drawOne() {
    final random = Random().nextInt(100);
    Rarity rarity;
    if (random < 5) {
      rarity = Rarity.UR;
    } else if (random < 20) {
      rarity = Rarity.SSR;
    } else if (random < 50) {
      rarity = Rarity.SR;
    } else {
      rarity = Rarity.R;
    }

    final pool = kGachaPool.where((item) => item.rarity == rarity).toList();
    return (pool..shuffle()).first;
  }

  void _executeGacha(int count) {
    final cost = count == 1 ? costOne : costTen;
    if (UserState.userPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイントが不足しています！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      UserState.userPoints -= cost;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    Timer(const Duration(seconds: 1), () {
      Navigator.pop(context);
      List<GachaItemData> results = [];
      for (int i = 0; i < count; i++) {
        results.add(_drawOne());
      }
      _showResultDialog(results);
    });
  }

  void _showResultDialog(List<GachaItemData> results) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text('✨ 獲得アイテム ✨', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: results.map((item) {
                  return Container(
                    width: results.length == 1 ? 130 : 85,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.rarity.color, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.rarity.label, style: TextStyle(color: item.rarity.color, fontWeight: FontWeight.bold, fontSize: 10)),
                        const SizedBox(height: 4),
                        Icon(item.icon, size: 28, color: item.rarity.color),
                        const SizedBox(height: 4),
                        Text(item.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 2),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProbabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提供割合'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('UR'), trailing: Text('5%')),
            ListTile(title: Text('SSR'), trailing: Text('15%')),
            ListTile(title: Text('SR'), trailing: Text('30%')),
            ListTile(title: Text('R'), trailing: Text('50%')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 上部エリア
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'ロゴ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: _showProbabilityDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: const Text('提供割合', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          'ポイント: ${UserState.userPoints}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // 2. 中央エリア（黒×青 フィルム缶 ＆ デザイン文字復活版）
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: RealFilmCanPainter(),
                      ),

                      // 黒領域：D-Sync + 8 EXP
                      Positioned(
                        left: 95,
                        top: 60,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'D-Sync',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    '8',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'EXP',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 青領域：白文字で復活したフィルム詳細テキスト
                      Positioned(
                        right: 40,
                        top: 52,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '5207  250D',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '135 Movie Film',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'for Color Prints',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. 下部操作エリア
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _executeGacha(1),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '1回引く',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 2),
                          Text('$costOneポイント使用', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'レアアイテム1つ確定',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _executeGacha(10),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '10回引く',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$costTenポイント使用',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}