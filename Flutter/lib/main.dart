import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; 
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// ==================================================
// バックグラウンドサービスのバックグラウンド処理エントリ
// ==================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 1), (timer) {
    service.invoke('update', {'current_date': DateTime.now().toIso8601String()});
  });
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) {
        return true;
      },
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'foreground_service',
      initialNotificationTitle: 'Workout App',
      initialNotificationContent: 'ワークアウトをバックグラウンドで計測中...',
    ),
  );
}

// ==================================================
// Cloudflare Workersに画像を送信してURLを取得する共通関数
// ==================================================
Future<String?> uploadImageToCloudflare(XFile imageFile) async {
  try {
    const String workerUrl = 'https://workout-uploader.tokyo-odh-341.workers.dev'; 
    if (workerUrl.contains('〇〇')) {
      debugPrint('Cloudflare Workers URLが設定されていません。');
      return null;
    }

    var request = http.MultipartRequest('POST', Uri.parse(workerUrl));
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
  } catch (e) {
    debugPrint('画像アップロードエラー: $e');
  }
  return null;
}

// ==================================================
// 画像拡大表示用の共通関数
// ==================================================
void showFullImageDialog(BuildContext context, String imageUrl) {
  if (imageUrl.isEmpty) return;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(imageUrl),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

// ==================================================
// ログデータ共有用の簡易データストア (複数画像対応)
// ==================================================
class WorkoutLogItem {
  final String id;
  final String title;
  final String appId;
  final String authorUid;
  final List<LatLng> routePoints;
  final String distanceStr;
  final String durationStr;
  final DateTime date;
  final String comment;
  final List<String> imageUrls;

  WorkoutLogItem({
    required this.id,
    required this.title,
    required this.appId,
    required this.authorUid,
    required this.routePoints,
    required this.distanceStr,
    required this.durationStr,
    required this.date,
    this.comment = '',
    this.imageUrls = const [],
  });
}

class WorkoutLogStore {
  static final List<WorkoutLogItem> logs = [];
}

// ==================================================
// カラーパレット定義
// ==================================================
class AppThemeColors {
  static const Color primary = Color(0xFF2563EB); 
  static const Color secondary = Color(0xFF10B981); 
  static const Color accent = Color(0xFFF59E0B); 
  static const Color background = Color(0xFFF8FAFC); 
  static const Color surface = Color(0xFFFFFFFF); 
  static const Color text = Color(0xFF111827); 
  static const Color border = Color(0xFFE5E7EB); 
  static const Color success = Color(0xFF22C55E); 
  static const Color error = Color(0xFFEF4444); 
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeBackgroundService();
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
        colorScheme: const ColorScheme.light(
          primary: AppThemeColors.primary,
          secondary: AppThemeColors.secondary,
          surface: AppThemeColors.surface,
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
  bool _isLoading = false;

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) _navigateToHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログイン失敗: メールアドレスかパスワードが違います'),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  child: const Icon(Icons.directions_run_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppThemeColors.text)),
                const SizedBox(height: 8),
                const Text('アカウントにログインして始めましょう', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 36),
                _buildTextField(controller: _emailController, label: 'メールアドレス', icon: Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, label: 'パスワード', icon: Icons.lock_outline, isPassword: true),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ログイン', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeColors.secondary,
                      side: const BorderSide(color: AppThemeColors.secondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('新規アカウント作成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _navigateToHome,
                  child: const Text('ログインせずに試す', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
  bool _isLoading = false;

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('全ての項目を入力してください')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final String generatedAppId = uid.substring(0, 8).toUpperCase();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'appId': generatedAppId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'region': '',
        'bio': '',
        'photoUrl': '',
        'headerUrl': '',
        'gachaPoints': 60,
        'friends': [], 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) _navigateToHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: AppThemeColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppThemeColors.text)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('アカウントを作成', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppThemeColors.text)),
                const SizedBox(height: 8),
                const Text('必要な情報を入力してください', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 32),
                _buildTextField(controller: _nameController, label: 'ユーザー名', icon: Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(controller: _emailController, label: 'メールアドレス', icon: Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, label: 'パスワード (6文字以上)', icon: Icons.lock_outline, isPassword: true),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('登録を完了する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('すでにアカウントをお持ちですか？', style: TextStyle(fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ログイン', style: TextStyle(color: AppThemeColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
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
  int _currentIndex = 0; 

  final List<Widget> _screens = const [
    TimelineScreen(),
    WorkoutScreen(),
    ProfileScreen(),
    GachaScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_roll), 
            label: 'ガチャ',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 共通コメントBottomSheet表示関数（非正規化対応・確実なプロフィール遷移版）
// ==================================================
void showCommentsBottomSheet(BuildContext context, String postId, String postOwner) {
  final TextEditingController commentController = TextEditingController();
  final parentContext = context; // 親コンテキスト保持

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppThemeColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (modalContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'まだコメントはありません。\n最初のコメントを投稿してみよう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    final commentDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: commentDocs.length,
                      itemBuilder: (context, index) {
                        final commentData = commentDocs[index].data() as Map<String, dynamic>;
                        final String uid = commentData['uid'] ?? '';
                        final String fallbackName = commentData['userName'] ?? '名無しさん';
                        final String text = commentData['text'] ?? '';
                        final String? directPhotoUrl = commentData['photoUrl'];

                        // 💡 コメントにphotoUrlがない古いデータの場合はストリームでユーザー情報を補完
                        return StreamBuilder<DocumentSnapshot?>(
                          stream: (directPhotoUrl == null || directPhotoUrl.isEmpty) 
                              ? _getUserStreamByUidOrName(uid, fallbackName) 
                              : const Stream.empty(),
                          builder: (context, userSnapshot) {
                            String displayName = fallbackName;
                            String resolvedUid = uid;
                            String? photoUrl = directPhotoUrl;

                            if (userSnapshot.hasData && userSnapshot.data != null) {
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              if (userData != null) {
                                displayName = userData['name'] ?? fallbackName;
                                resolvedUid = userData['uid'] ?? uid;
                                if (photoUrl == null || photoUrl.isEmpty) {
                                  photoUrl = userData['photoUrl'];
                                }
                              }
                            }

                            return ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  if (resolvedUid.isNotEmpty) {
                                    Navigator.pop(modalContext); // ボトムシートを閉じる
                                    Navigator.push(
                                      parentContext, // 親コンテキストで画面遷移
                                      MaterialPageRoute(
                                        builder: (context) => UserProfileScreen(
                                          targetUid: resolvedUid,
                                          fallbackName: displayName,
                                          fallbackAppId: '',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppThemeColors.border,
                                    shape: BoxShape.circle,
                                    image: photoUrl != null && photoUrl.isNotEmpty
                                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: photoUrl == null || photoUrl.isEmpty
                                      ? const Icon(Icons.person, size: 20, color: AppThemeColors.text)
                                      : null,
                                ),
                              ),
                              title: GestureDetector(
                                onTap: () {
                                  if (resolvedUid.isNotEmpty) {
                                    Navigator.pop(modalContext);
                                    Navigator.push(
                                      parentContext,
                                      MaterialPageRoute(
                                        builder: (context) => UserProfileScreen(
                                          targetUid: resolvedUid,
                                          fallbackName: displayName,
                                          fallbackAppId: '',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: Text(text),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
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
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;

                      final user = FirebaseAuth.instance.currentUser;
                      String userName = 'ゲスト';
                      String authorUid = user != null ? user.uid : '';
                      String photoUrl = '';

                      if (user != null) {
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                        if (userDoc.exists) {
                          userName = userDoc.data()?['name'] ?? 'ランナー';
                          photoUrl = userDoc.data()?['photoUrl'] ?? '';
                        }
                      }

                      // 💡 投稿時にuid, userNameに加えてphotoUrlも直接保存（非正規化）
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                        'uid': authorUid,
                        'userName': userName,
                        'photoUrl': photoUrl,
                        'text': commentController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      commentController.clear();
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
// 1. TL (タイムライン) 画面 - フレンド専用
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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        List<String> allowedUids = [currentUser.uid];
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> friendsList = userData['friends'] ?? [];
          for (var f in friendsList) {
            allowedUids.add(f.toString());
          }
        }

        return SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'フレンドTL',
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
                    _buildTimelineList(isLogTab: false, allowedUids: allowedUids),
                    _buildTimelineList(isLogTab: true, allowedUids: allowedUids),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineList({required bool isLogTab, required List<String> allowedUids}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: isLogTab ? 'log' : 'sync') 
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return const Center(child: Text('データを読み込めませんでした。'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isLogTab ? 'フレンドのログ投稿がまだありません。' : 'フレンドのSync投稿がまだありません。\nフレンドを追加してみよう！',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final authorUid = data['author_uid'] ?? '';
          return allowedUids.contains(authorUid);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              isLogTab ? 'フレンドのログ投稿がまだありません。' : 'フレンドのSync投稿がまだありません。\nフレンドを追加してみよう！',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            if (isLogTab) {
              List<LatLng> restoredPoints = [];
              if (data['routePoints'] != null) {
                for (var p in data['routePoints']) {
                  if (p['lat'] != null && p['lng'] != null) {
                    restoredPoints.add(
                      LatLng(
                        (p['lat'] as num).toDouble(),
                        (p['lng'] as num).toDouble(),
                      ),
                    );
                  }
                }
              }
              if (restoredPoints.isEmpty) {
                restoredPoints.add(const LatLng(35.681236, 139.767125));
              }

              List<String> restoredImageUrls = [];
              if (data['imageUrls'] != null) {
                restoredImageUrls = List<String>.from(data['imageUrls']);
              } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
                restoredImageUrls.add(data['imageUrl']);
              }

              final logItem = WorkoutLogItem(
                id: docs[index].id,
                title: data['author_name'] ?? data['author_uid'] ?? 'ユーザー',
                appId: data['author_appId'] ?? 'ID',
                authorUid: data['author_uid'] ?? '',
                routePoints: restoredPoints,
                distanceStr: '${data['distance'] ?? 0} km',
                durationStr: data['duration'] ?? '00:00',
                date: DateTime.now(),
                comment: data['comment'] ?? '',
                imageUrls: restoredImageUrls,
              );

              return CarouselPostCard(logItem: logItem);
            } else {
              return SyncPostCard(postId: docs[index].id, data: data);
            }
          },
        );
      },
    );
  }
}

// ==================================================
// Sync用カードウィジェット
// ==================================================
class SyncPostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const SyncPostCard({super.key, required this.postId, required this.data});

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final postData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> likedUids = List.from(postData['liked_uids'] ?? []);
        int currentLikes = postData['likes'] ?? 0;

        if (likedUids.contains(user.uid)) {
          likedUids.remove(user.uid);
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
          transaction.update(docRef, {
            'likes': currentLikes,
            'liked_uids': likedUids,
          });
        } else {
          likedUids.add(user.uid);
          transaction.update(docRef, {
            'likes': currentLikes + 1,
            'liked_uids': likedUids,
          });
        }
      });
    } catch (e) {
      debugPrint('いいねトグルエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String authorName = data['author_name'] ?? data['author_uid'] ?? 'ユーザー';
    final String authorAppId = data['author_appId'] ?? 'ID';
    final String authorUid = data['author_uid'] ?? '';
    final String comment = data['comment'] ?? '';
    final String imageUrl = data['imageUrl'] ?? '';
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(context, authorName, authorAppId, authorUid),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            color: AppThemeColors.border,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => showFullImageDialog(context, imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                if (comment.isNotEmpty) ...[
                  if (imageUrl.isNotEmpty) const SizedBox(height: 20),
                  Text(comment),
                ],
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int likesCount = 0;
                        bool isLikedByMe = false;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final docData = snapshot.data!.data() as Map<String, dynamic>;
                          likesCount = docData['likes'] ?? 0;
                          List<dynamic> likedUids = docData['liked_uids'] ?? [];
                          isLikedByMe = likedUids.contains(currentUserId);
                        }

                        return GestureDetector(
                          onTap: () => _toggleLike(context),
                          child: Row(
                            children: [
                              Icon(
                                isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: AppThemeColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$likesCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppThemeColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, commentSnapshot) {
                        int commentCount = 0;
                        if (commentSnapshot.hasData) {
                          commentCount = commentSnapshot.data!.docs.length;
                        }

                        return GestureDetector(
                          onTap: () => showCommentsBottomSheet(
                            context,
                            postId,
                            authorName,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: AppThemeColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$commentCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppThemeColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

// ==================================================
// ログ用カード (動的カルーセルスライド対応)
// ==================================================
class CarouselPostCard extends StatefulWidget {
  final WorkoutLogItem logItem;

  const CarouselPostCard({super.key, required this.logItem});

  @override
  State<CarouselPostCard> createState() => _CarouselPostCardState();
}

class _CarouselPostCardState extends State<CarouselPostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('posts').doc(widget.logItem.id);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final postData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> likedUids = List.from(postData['liked_uids'] ?? []);
        int currentLikes = postData['likes'] ?? 0;

        if (likedUids.contains(user.uid)) {
          likedUids.remove(user.uid);
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
          transaction.update(docRef, {
            'likes': currentLikes,
            'liked_uids': likedUids,
          });
        } else {
          likedUids.add(user.uid);
          transaction.update(docRef, {
            'likes': currentLikes + 1,
            'liked_uids': likedUids,
          });
        }
      });
    } catch (e) {
      debugPrint('いいねトグルエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    List<Widget> slides = [];
    slides.add(_buildMapSlide(widget.logItem));
    slides.add(_buildSlide(
      Icons.fitness_center,
      '筋トレ種目 / メニュー',
      '・ベンチプレス 60kg × 10回\n・スクワット 80kg × 8回',
    ));

    for (var imgUrl in widget.logItem.imageUrls) {
      slides.add(_buildPhotoSlide(imgUrl));
    }

    int totalSlides = slides.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(
            context,
            widget.logItem.title,
            widget.logItem.appId,
            widget.logItem.authorUid,
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
                        children: slides,
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
                            '${_currentPage + 1}/$totalSlides',
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
                    totalSlides,
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
                if (widget.logItem.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.logItem.comment),
                ],
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.logItem.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int likesCount = 0;
                        bool isLikedByMe = false;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          likesCount = data['likes'] ?? 0;
                          List<dynamic> likedUids = data['liked_uids'] ?? [];
                          isLikedByMe = likedUids.contains(currentUserId);
                        }

                        return GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: AppThemeColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$likesCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppThemeColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.logItem.id)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, commentSnapshot) {
                        int commentCount = 0;
                        if (commentSnapshot.hasData) {
                          commentCount = commentSnapshot.data!.docs.length;
                        }

                        return GestureDetector(
                          onTap: () => showCommentsBottomSheet(
                            context,
                            widget.logItem.id,
                            widget.logItem.title,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: AppThemeColors.primary,
                              ),
                              const SizedBox(width: 4), 
                              Text(
                                '$commentCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppThemeColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildMapSlide(WorkoutLogItem item) {
    final bool hasPoints = item.routePoints.isNotEmpty;
    
    LatLng initialCenter = const LatLng(35.681236, 139.767125);
    if (hasPoints) {
      double sumLat = 0;
      double sumLng = 0;
      for (var p in item.routePoints) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      initialCenter = LatLng(sumLat / item.routePoints.length, sumLng / item.routePoints.length);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
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
                      urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
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
                  ],
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

  Widget _buildPhotoSlide(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => showFullImageDialog(context, imageUrl),
        child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }
}

// ==================================================
// ユーザー情報を安全に取得するためのヘルパー関数
// ==================================================
Stream<DocumentSnapshot?> _getUserStream(String uidOrEmail) {
  if (uidOrEmail.isEmpty) return Stream.value(null);
  if (uidOrEmail.contains('@')) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: uidOrEmail)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  } else {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uidOrEmail)
        .snapshots()
        .map((doc) => doc.exists ? doc : null);
  }
}

Stream<DocumentSnapshot?> _getUserStreamByUidOrName(String uid, String fallbackName) {
  if (uid.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc : null);
  } else if (fallbackName.isNotEmpty && fallbackName != 'ゲスト' && fallbackName != '名無しさん') {
    return FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: fallbackName)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }
  return Stream.value(null);
}

// ==================================================
// ユーザーヘッダー
// ==================================================
Widget _buildUserHeader(BuildContext context, String fallbackName, String fallbackId, String authorUid) {
  return StreamBuilder<DocumentSnapshot?>(
    stream: _getUserStream(authorUid),
    builder: (context, snapshot) {
      String displayName = fallbackName;
      String displayId = fallbackId;
      String? photoUrl;

      if (snapshot.hasData && snapshot.data != null) {
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData != null) {
          displayName = userData['name'] ?? fallbackName;
          displayId = userData['appId'] ?? fallbackId;
          photoUrl = userData['photoUrl'];
        }
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                targetUid: authorUid,
                fallbackName: displayName,
                fallbackAppId: displayId,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppThemeColors.border,
                shape: BoxShape.circle,
                image: photoUrl != null && photoUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  displayId,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

// ==================================================
// 相互フレンド追加の共通ロジック
// ==================================================
Future<void> addMutualFriendByAppId(BuildContext context, String targetAppId) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    return;
  }

  final trimmedId = targetAppId.trim().toUpperCase();
  if (trimmedId.isEmpty) return;

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('appId', isEqualTo: trimmedId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ 該当するIDのユーザーが見つかりませんでした'), backgroundColor: AppThemeColors.error),
        );
      }
      return;
    }

    final targetDoc = querySnapshot.docs.first;
    final targetUid = targetDoc.id;
    final targetName = targetDoc.data()['name'] ?? 'ユーザー';

    if (targetUid == currentUser.uid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('自分自身をフレンドに追加することはできません'), backgroundColor: AppThemeColors.error),
        );
      }
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

    batch.update(myRef, {'friends': FieldValue.arrayUnion([targetUid])});
    batch.update(targetRef, {'friends': FieldValue.arrayUnion([currentUser.uid])});
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $targetName さんと相互フレンドになりました！'),
          backgroundColor: AppThemeColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    debugPrint('フレンド追加エラー: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: AppThemeColors.error),
      );
    }
  }
}

// ==================================================
// 相手のプロフィール画面
// ==================================================
class UserProfileScreen extends StatelessWidget {
  final String targetUid;
  final String fallbackName;
  final String fallbackAppId;

  const UserProfileScreen({
    super.key,
    required this.targetUid,
    this.fallbackName = 'ユーザー',
    this.fallbackAppId = 'ID',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppThemeColors.text),
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _getUserStream(targetUid),
        builder: (context, snapshot) {
          String name = fallbackName;
          String appId = fallbackAppId;
          String region = '';
          String bio = '';
          String? photoUrl;
          String? headerUrl;

          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              name = data['name'] ?? fallbackName;
              appId = data['appId'] ?? fallbackAppId;
              region = data['region'] ?? '';
              bio = data['bio'] ?? '';
              photoUrl = data['photoUrl'];
              headerUrl = data['headerUrl'];
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (headerUrl != null && headerUrl.isNotEmpty) {
                        showFullImageDialog(context, headerUrl);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppThemeColors.border,
                        image: headerUrl != null && headerUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(headerUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: headerUrl == null || headerUrl.isEmpty ? const Text('ヘッダー', style: TextStyle(fontSize: 15)) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (photoUrl != null && photoUrl.isNotEmpty) {
                            showFullImageDialog(context, photoUrl);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppThemeColors.border,
                            shape: BoxShape.circle,
                            image: photoUrl != null && photoUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: photoUrl == null || photoUrl.isEmpty ? const Text('アイコン', style: TextStyle(fontSize: 14)) : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildReadOnlyField(name),
                            const SizedBox(height: 8),
                            _buildReadOnlyField(appId),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 65,
                                  child: _buildReadOnlyField(region.isEmpty ? '居住地域未設定' : region),
                                ),
                                const Spacer(flex: 35),
                              ],
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
                    child: Text(
                      bio.isEmpty ? '自己紹介欄はまだありません。' : bio,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
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
          );
        },
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
// 2. ワークアウト 画面
// ==================================================
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

enum WorkoutMode { running, muscle }

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  bool _isWorkoutStarted = false;
  WorkoutMode _currentMode = WorkoutMode.running;
  bool _isMapReady = false; 

  Timer? _stopwatchTimer;
  DateTime? _startTime;
  int _accumulatedMilliseconds = 0;
  int _elapsedMilliseconds = 0;
  bool _isTimerRunning = false;

  Timer? _cameraTimer;
  int _cameraRemainingSeconds = 0;
  bool _isCameraEnabled = false;

  final List<String> _sessionImageUrls = []; 

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng _currentLocation = const LatLng(35.681236, 139.767125); 
  final List<LatLng> _routePoints = []; 
  double _totalDistanceMeters = 0.0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
        _initCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    _cameraTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isTimerRunning && _startTime != null) {
        setState(() {
          _elapsedMilliseconds = _accumulatedMilliseconds + DateTime.now().difference(_startTime!).inMilliseconds;
        });
      }
    }
  }

  Future<void> _initCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = newPos;
        });
        try {
          _mapController.move(newPos, 16.0);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('初期位置取得エラー: $e');
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

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
      _startTime = DateTime.now(); 
      
      _stopwatchTimer?.cancel();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        setState(() {
          _elapsedMilliseconds = _accumulatedMilliseconds + DateTime.now().difference(_startTime!).inMilliseconds;
        });
      });
    }
  }

  void _pauseStopwatch() {
    if (_isTimerRunning) {
      _isTimerRunning = false;
      _stopwatchTimer?.cancel();
      if (_startTime != null) {
        _accumulatedMilliseconds += DateTime.now().difference(_startTime!).inMilliseconds;
      }
      setState(() {});
    }
  }

  void _resetStopwatch() {
    _isTimerRunning = false;
    _stopwatchTimer?.cancel();
    _startTime = null;
    _accumulatedMilliseconds = 0;
    setState(() {
      _elapsedMilliseconds = 0;
    });
  }

  String get _formattedTime {
    int minutes = (_elapsedMilliseconds ~/ 60000);
    int seconds = ((_elapsedMilliseconds % 60000) ~/ 1000);
    int hundredths = ((_elapsedMilliseconds % 1000) ~/ 10);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}";
  }

  void _triggerCameraNotification() {
    HapticFeedback.vibrate();

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

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📷 写真をアップロード中です...')),
      );
    }

    String? imageUrl = await uploadImageToCloudflare(image);

    if (imageUrl != null) {
      String photoComment = '';
      if (mounted) {
        final TextEditingController photoCommentController = TextEditingController();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('写真のコメント入力'),
              content: TextField(
                controller: photoCommentController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '例: 途中経過！いいペース！ (空でもOK)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    photoComment = photoCommentController.text.trim();
                    Navigator.pop(context);
                  },
                  child: const Text('決定'),
                ),
              ],
            );
          },
        );
      }

      setState(() {
        _isCameraEnabled = false; 
        _sessionImageUrls.add(imageUrl);
      });

      final user = FirebaseAuth.instance.currentUser;
      String authorName = 'ゲストランナー';
      String authorAppId = 'ID';
      String authorUid = user != null ? user.uid : 'guest';

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          authorName = userDoc.data()?['name'] ?? 'ランナー';
          authorAppId = userDoc.data()?['appId'] ?? 'ID';
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'gachaPoints': FieldValue.increment(1),
        });
      }

      try {
        await FirebaseFirestore.instance.collection('posts').add({
          'author_uid': authorUid,
          'author_name': authorName,
          'author_appId': authorAppId,
          'comment': photoComment,
          'imageUrl': imageUrl,
          'likes': 0,
          'liked_uids': [],
          'type': 'sync',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Sync投稿エラー: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 写真をSyncに投稿し、ガチャポイント1pt獲得しました！'),
            backgroundColor: AppThemeColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ アップロード失敗: Cloudflare WorkersのURLをご確認ください。'),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');

    _stopLocationTracking();
    _stopwatchTimer?.cancel();

    TextEditingController commentController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 16),
                    const Text('ワークアウト終了', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('お疲れ様でした！感想を入力してください。', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '例: 自己ベスト更新しました！気持ちよかった！',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppThemeColors.background,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('撮影した写真 (${_sessionImageUrls.length}枚)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    if (_sessionImageUrls.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sessionImageUrls.length,
                          itemBuilder: (context, index) {
                            final imgUrl = _sessionImageUrls[index];
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => showFullImageDialog(context, imgUrl),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8, top: 4, left: 4),
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppThemeColors.border),
                                      image: DecorationImage(
                                        image: NetworkImage(imgUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        _sessionImageUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      const Text('写真はありません（0枚）', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('投稿する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    String commentText = commentController.text.trim();
    String distanceKm = (_totalDistanceMeters / 1000.0).toStringAsFixed(2);
    final user = FirebaseAuth.instance.currentUser;
    String authorName = 'ゲストランナー';
    String authorAppId = 'ID';
    String authorUid = user != null ? user.uid : 'guest';

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        authorName = userDoc.data()?['name'] ?? 'ランナー';
        authorAppId = userDoc.data()?['appId'] ?? 'ID';
      }
    }

    if (_routePoints.isNotEmpty || _sessionImageUrls.isNotEmpty || commentText.isNotEmpty) {
      List<Map<String, double>> pointsList = _routePoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList();

      WorkoutLogStore.logs.insert(
        0,
        WorkoutLogItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: authorName,
          appId: authorAppId,
          authorUid: authorUid,
          routePoints: List.from(_routePoints),
          distanceStr: '$distanceKm km',
          durationStr: _formattedTime.split('.').first,
          date: DateTime.now(),
          comment: commentText,
          imageUrls: List.from(_sessionImageUrls),
        ),
      );

      try {
        await FirebaseFirestore.instance.collection('posts').add({
          'author_uid': authorUid,
          'author_name': authorName,
          'author_appId': authorAppId,
          'distance': double.parse(distanceKm),
          'duration': _formattedTime.split('.').first,
          'comment': commentText,
          'imageUrls': _sessionImageUrls,
          'routePoints': pointsList,
          'location_name': 'ワークアウト走行ルート',
          'likes': 0,
          'liked_uids': [],
          'type': 'log',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestoreへのログ保存エラー: $e');
      }
    }

    _resetStopwatch();
    _cameraTimer?.cancel();

    setState(() {
      _isWorkoutStarted = false;
      _isCameraEnabled = false;
      _sessionImageUrls.clear();
      _routePoints.clear();
      _totalDistanceMeters = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ワークアウトが終了し、TLに保存されました！'),
          backgroundColor: AppThemeColors.success,
        ),
      );
    }
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
                  (!_isMapReady
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
                                  'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      _buildActionButton('スタート', AppThemeColors.secondary, () async {
                        setState(() {
                          _isWorkoutStarted = true;
                        });
                        
                        final service = FlutterBackgroundService();
                        bool isRunning = await service.isRunning();
                        if (!isRunning) {
                          service.startService();
                        }

                        _startStopwatch();
                        _startLocationTracking();
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
      cameraText = 'カメラ\n(${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')})';
    } else {
      cameraText = 'カメラ\n(ロック)';
    }

    return GestureDetector(
      onTap: _isCameraEnabled ? _takePhoto : null,
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
// ガチャ関連のデータモデル・クラス定義
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

class RealFilmCanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    final holePaint = Paint()..color = Colors.white.withOpacity(0.85);
    for (int i = 0; i < 5; i++) {
      double dx = size.width * (0.13 + i * 0.045);
      double dy = size.height * (0.40 + i * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, 7, 10), const Radius.circular(1.5)),
        holePaint,
      );
    }

    final canRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.16, size.width * 0.48, size.height * 0.68),
      const Radius.circular(16),
    );

    canvas.drawRRect(canRect, Paint()..color = const Color(0xFF0F172A));

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================================================
// ガチャ画面本体
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
    if (pool.isEmpty) return kGachaPool.first;
    return (pool..shuffle()).first;
  }

  Future<void> _executeGacha(int count) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です'), backgroundColor: Colors.red),
      );
      return;
    }

    final cost = count == 1 ? costOne : costTen;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final int currentPoints = doc.data()?['gachaPoints'] ?? 0;

    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイントが不足しています！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'gachaPoints': FieldValue.increment(-cost),
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pop(context);

      List<GachaItemData> results = [];
      for (int i = 0; i < count; i++) {
        results.add(_drawOne());
      }
      _showResultDialog(results);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
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
                  if (mounted) setState(() {});
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                const Text(
                  'ガチャ',
                  style: TextStyle(
                    fontSize: 16,
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
                    StreamBuilder<DocumentSnapshot>(
                      stream: currentUserId != null
                          ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        int userPoints = 0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          userPoints = data['gachaPoints'] ?? 0;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'ポイント: $userPoints',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = true;
  String? _uid;
  String? _userPhotoUrl;
  String? _userHeaderUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _idController.text = data['appId'] ?? '';
            _regionController.text = data['region'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _userPhotoUrl = data['photoUrl'];
            _userHeaderUrl = data['headerUrl'];
          });
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_uid == null) return;
    FocusScope.of(context).unfocus();

    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ プロフィール情報を保存しました！'),
            backgroundColor: AppThemeColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: AppThemeColors.error),
        );
      }
    }
  }

  Future<void> _pickAndCropImage(bool isHeader) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isHeader ? 'ヘッダー画像の位置調整' : 'アイコン画像の位置調整',
          toolbarColor: AppThemeColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: isHeader ? CropAspectRatioPreset.ratio16x9 : CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: isHeader
              ? [CropAspectRatioPreset.ratio16x9, CropAspectRatioPreset.ratio4x3]
              : [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: isHeader ? 'ヘッダー画像の位置調整' : 'アイコン画像の位置調整',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    XFile croppedXFile = XFile(croppedFile.path);
    await _uploadAndSaveImage(croppedXFile, isHeader);
  }

  Future<void> _uploadAndSaveImage(XFile imageFile, bool isHeader) async {
    setState(() => _isLoading = true);

    String? url = await uploadImageToCloudflare(imageFile);
    if (url != null && _uid != null) {
      String fieldKey = isHeader ? 'headerUrl' : 'photoUrl';
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        fieldKey: url,
      });

      if (mounted) {
        setState(() {
          if (isHeader) {
            _userHeaderUrl = url;
          } else {
            _userPhotoUrl = url;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isHeader ? '✅ ヘッダー画像を更新しました！' : '✅ アイコン画像を更新しました！')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ アップロード失敗: Cloudflare WorkersのURLをご確認ください。'),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                const Text('フレンド追加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppThemeColors.text)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppThemeColors.border, child: Icon(Icons.qr_code_scanner, color: AppThemeColors.primary)),
                  title: const Text('QRコードリーダーで追加', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('カメラで相手のQRコードを読み取ります'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QrScannerScreen(myId: _idController.text)));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppThemeColors.border, child: Icon(Icons.keyboard, color: AppThemeColors.secondary)),
                  title: const Text('IDを直打ちして追加', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('8文字の英数字IDを入力してください。'),
              const SizedBox(height: 16),
              TextField(
                controller: friendIdController,
                maxLength: 8,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'フレンドID (8文字)', border: OutlineInputBorder(), counterText: ''),
                onChanged: (text) {
                  if (text.trim().length == 8) {
                    final String addedId = text.trim();
                    Navigator.pop(context);
                    addMutualFriendByAppId(context, addedId);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ],
        );
      },
    );
  }

  Widget _buildField(TextEditingController controller, String hintText, {bool readOnly = false}) {
    return Container(
      height: 28,
      color: AppThemeColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(fontSize: 13, color: readOnly ? Colors.grey[600] : AppThemeColors.text),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('プロフィール', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _pickAndCropImage(true),
                    child: Container(
                      width: double.infinity,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppThemeColors.border,
                        image: _userHeaderUrl != null && _userHeaderUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_userHeaderUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _userHeaderUrl == null || _userHeaderUrl!.isEmpty
                          ? const Text('ヘッダー編集 (タップして位置調整)', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _pickAndCropImage(false),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppThemeColors.border,
                            shape: BoxShape.circle,
                            image: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_userPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: _userPhotoUrl == null || _userPhotoUrl!.isEmpty ? const Text('アイコン', style: TextStyle(fontSize: 14)) : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildField(_nameController, '名前'),
                            const SizedBox(height: 8),
                            _buildField(_idController, 'ID', readOnly: true),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 65,
                                  child: _buildField(_regionController, '居住地域'),
                                ),
                                const Spacer(flex: 35),
                              ],
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
                      decoration: const InputDecoration(hintText: '自己紹介欄', hintStyle: TextStyle(color: Colors.grey, fontSize: 13), border: InputBorder.none, isDense: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(width: 60, height: 60, decoration: const BoxDecoration(color: AppThemeColors.border, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('レベル', style: TextStyle(fontSize: 13))),
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
                            style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                            child: const Text('プロフィールを保存', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                            label: const Text('フレンド追加', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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
}

// ==================================================
// 3-A. QRコードスキャナー画面
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
              const Text('マイQRコード', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('あなたのID: ${widget.myId.isEmpty ? "未設定" : widget.myId}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.primary, foregroundColor: Colors.white),
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
        title: const Text('QRコードを読み取る', style: TextStyle(color: AppThemeColors.text, fontSize: 16)),
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
                  addMutualFriendByAppId(context, scannedData);
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
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showMyQrCodeModal,
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text('マイQRコードを表示', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
// 4. 目標設定画面
// ==================================================
class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  bool _isManualMode = false;
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('goals').add({
        'uid': user != null ? user.uid : 'guest',
        'email': user != null ? user.email : 'guest',
        'content': text,
        'mode': _isManualMode ? 'manual' : 'ai_consult',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isManualMode ? '✅ 目標を設定してデータベースに保存しました！' : '🤖 AIにメッセージを送信し、保存しました！',
            ),
            backgroundColor: AppThemeColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                      icon: const Icon(Icons.arrow_back, color: AppThemeColors.text),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text('目標設定・AI相談', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: AppThemeColors.border, shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy_outlined, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(color: AppThemeColors.border, borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: const Text(
                                'AIからのコメント\n\n(例: 今日はどのようなトレーニングをしたい気分ですか？)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppThemeColors.text),
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
                        icon: Icon(_isManualMode ? Icons.smart_toy : Icons.edit, size: 18),
                        label: Text(_isManualMode ? 'AIに相談するモードへ' : '自分で設定する'),
                        style: TextButton.styleFrom(
                          backgroundColor: AppThemeColors.border,
                          foregroundColor: AppThemeColors.text,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(color: AppThemeColors.border, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _inputController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isManualMode ? 'テキストボックス\n\n(例: 今日は5km走る！)' : 'テキストボックス\n\n(例: 今日は疲れているから軽めの運動にしたい)',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_isManualMode ? 'この目標で決定する' : 'AIに送信', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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