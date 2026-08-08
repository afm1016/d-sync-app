import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {

  // 💡 【追加】DartからFirebaseに直接データを書き込む関数
  Future<void> _addTestPostToFirebase() async {
    // 'posts' というフォルダ（コレクション）にデータを送信！
    // フォルダが存在しなければ、Firebaseが勝手に作ってくれます。
    await FirebaseFirestore.instance.collection('posts').add({
      'userName': 'Flutter開発者',
      'userId': 'id_dart123',
      'aiComment': 'Dartから直接Firestoreにデータを入れることに成功しました！🔥',
      'likes': 0,
      // 投稿した時間（これを使って新しい順に並べ替えます）
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // ignore: avoid_print
    print('Firestoreへの保存完了！');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ロゴ (TL)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 💡 【追加】開発用：右上のプラスボタンを押すとデータが追加される
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _addTestPostToFirebase,
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部のタブ（Sync / ログ）Figmaデザイン再現
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Sync', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('ログ', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const Divider(height: 1),

          // 💡 【変更】Firebaseからデータをリアルタイムで読み込む（StreamBuilder）
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 'posts' コレクションのデータを、時間が新しい順に並べて監視する
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. データを読み込み中の時
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // くるくる回るアイコン
                }
                
                // 2. エラーが起きた時（テストモードにしていない等）
                if (snapshot.hasError) {
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                }

                // 3. データが1件もない時
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('まだ投稿がありません。\n右上の「＋」ボタンを押して追加してみて！'));
                }

                // 4. データがある時（リストを作成）
                final docs = snapshot.data!.docs;

                // 変更箇所：buildメソッド内の ListView.builder 部分を以下のように直します
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // 💡 Firestoreの実際のキー名に合わせてマッピング！
                    final post = {
                      'userName': data['author_uid'] ?? '名無しさん', // author_uid を名前に表示
                      'userId': data['author_uid'] ?? '',
                      'distance': data['distance']?.toString() ?? '0', // distanceを表示
                      'aiComment': data['location_name'] ?? '場所情報なし', // location_nameを表示
                      'likes': 0, // 今のDBにlikesがないので0にする
                    };
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 1件分の投稿デザイン（ここは変更なし！）
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post['userId'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[800],
              child: const Center(
                child: Text(
                  'マップ・写真カルーセル',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🤖 AIコメント:\n${post['aiComment']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'いいね ${post['likes']}  コメント',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}