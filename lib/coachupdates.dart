import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CoachUpdates extends StatefulWidget {
  const CoachUpdates({super.key});

  @override
  State<CoachUpdates> createState() => _CoachUpdatesState();
}

class _CoachUpdatesState extends State<CoachUpdates> {
  String? _coachName;

  @override
  void initState() {
    super.initState();
    _loadCoachName();
  }

  Future<void> _loadCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coachName = prefs.getString('name');
    });
  }

  Future<void> _markNewsAsRead(String newsDocId) async {
    if (_coachName == null) return;
    var existingDoc = await FirebaseFirestore.instance
        .collection('news_read_status')
        .where('newsId', isEqualTo: newsDocId)
        .where('userId', isEqualTo: _coachName)
        .get();

    if (existingDoc.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('news_read_status').add({
        'newsId': newsDocId,
        'userId': _coachName,
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
    if (_coachName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.blueGrey[50], // تغيير لون الخلفية
    body: RefreshIndicator(
    onRefresh: _refreshNews,
    color: Colors.teal, // تغيير لون مؤشر التحديث
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('news')
        .where('target', whereIn: ['الجميع', 'المدربين']) // تغيير الهدف إلى المدربين أو الجميع
        .orderBy('date', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: const TextStyle(fontSize: 18, color: Colors.red)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return const Center(
    child: Text('لا توجد أخبار للمدربين حاليًا',
    style: TextStyle(fontSize: 18, color: Colors.grey)));
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
        .where('userId', isEqualTo: _coachName)
        .snapshots(),
      builder: (context, readSnapshot) {
        bool isRead = readSnapshot.hasData &&
            readSnapshot.data!.docs.isNotEmpty &&
            readSnapshot.data!.docs.first['isRead'] == true;
        return VisibilityDetector(
          key: Key(newsDocId),
          onVisibilityChanged: (visibilityInfo) {
            if (visibilityInfo.visibleFraction > 0.5 && !isRead) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _markNewsAsRead(newsDocId);
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // زوايا أكثر استدارة
              border: Border.all(color: Colors.teal.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 20,
                      color: isRead ? Colors.grey : Colors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal, // لون مختلف للعنوان
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.5,
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