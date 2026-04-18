import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Playerupdates extends StatefulWidget {
  Playerupdates({super.key});

  @override
  State<Playerupdates> createState() => _PlayerupdatesState();
}

class _PlayerupdatesState extends State<Playerupdates> {
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerName = prefs.getString('name');
    });
  }

  Future<void> _markNewsAsRead(String newsDocId) async {
    if (_playerName == null) return;
    var existingDoc = await FirebaseFirestore.instance
        .collection('news_read_status')
        .where('newsId', isEqualTo: newsDocId)
        .where('userId', isEqualTo: _playerName)
        .get();

    if (existingDoc.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('news_read_status').add({
        'newsId': newsDocId,
        'userId': _playerName,
        'isRead': true,
        'readTimestamp': FieldValue.serverTimestamp(),
      });
    } else if (!existingDoc.docs.first['isRead']) {
      await FirebaseFirestore.instance
          .collection('news_read_status')
          .doc(existingDoc.docs.first.id)
          .update({'isRead': true, 'readTimestamp': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _refreshNews() async {
    setState(() {}); // إعادة تحميل البيانات
  }

  @override
  Widget build(BuildContext context) {
    if (_playerName == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: RefreshIndicator(
        onRefresh: _refreshNews,
        color: Color(0xFF3D6F5D),
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('news')
        .where('target', whereIn: ['الجميع', 'اللاعبين'])
        .orderBy('date', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(fontSize: 18, color: Colors.red)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(child: Text('لا توجد أخبار حاليًا', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    var newsList = snapshot.data!.docs;

    return ListView.builder(
    itemCount: newsList.length,
    itemBuilder: (context, index) {
    var news = newsList[index].data() as Map<String, dynamic>;
    String newsDocId = newsList[index].id;
    String title = news['title'] ?? 'بدون عنوان';
    String message = news['content'] ?? '';

    print('News $index: $title (ID: $newsDocId)'); // تصحيح أخطاء
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('news_read_status')
          .where('newsId', isEqualTo: newsDocId)
          .where('userId', isEqualTo: _playerName)
          .snapshots(),
      builder: (context, readSnapshot) {
        bool isRead = readSnapshot.hasData &&
            readSnapshot.data!.docs.isNotEmpty &&
            readSnapshot.data!.docs.first['isRead'] == true;

        return VisibilityDetector(
          key: Key(newsDocId),
          onVisibilityChanged: (visibilityInfo) {
            if (visibilityInfo.visibleFraction > 0.5 && !isRead) {
              Future.delayed(Duration(seconds: 2), () {
                if (mounted) _markNewsAsRead(newsDocId);
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isRead ? Colors.grey : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    },
    );
    },
    ),
        ),
    );
  }
}