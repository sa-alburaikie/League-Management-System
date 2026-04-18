import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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

  Future<void> _markAsRead(String messageId) async {
    await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
      'isRead': true,
    });
  }

  Future<void> _replyToMessage(String messageId) async {
    TextEditingController replyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على الرسالة'),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(labelText: 'اكتب ردك هنا'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
                  'reply': replyController.text,
                  'isRead': true,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_playerName == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
        children: [
        StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
        .where('receiverId', isEqualTo: _playerName)
        .where('isRead', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: TextStyle(color: Colors.red)));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(
    child: Text('لا توجد رسائل واردة غير مقروءة',
    style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    var messages = snapshot.data!.docs;

    return ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: messages.length,
    itemBuilder: (context, index) {
    var message = messages[index].data() as Map<String, dynamic>;
    String messageId = messages[index].id;
    String title = message['title'] ?? 'بدون عنوان';
    String content = message['content'] ?? '';
    String senderName = message['senderName'] ?? 'مجهول';
    Timestamp? dateTime = message['dateTime'];
    String formattedDate = dateTime != null
        ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
        : 'غير محدد';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'من: $senderName',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'التاريخ: $formattedDate',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                  fontSize: 16, color: Colors.black87, height: 1.4),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.reply, color: Color(0xFF3D6F5D)),
                  label: Text('الرد',
                      style: TextStyle(color: Color(0xFF3D6F5D))),
                  onPressed: () => _replyToMessage(messageId),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.check, color: Color(0xFF3D6F5D)),
                  label: Text('تعيين كمقروء',
                      style: TextStyle(color: Color(0xFF3D6F5D))),
                  onPressed: () => _markAsRead(messageId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    },
    );
    },
    ),
    Positioned(
    bottom: 16,
    left: 16,
    child: FloatingActionButton(
    heroTag: 'readMessages', // تحديد heroTag فريد
    backgroundColor: Color(0xFF3D6F5D),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => ReadMessagesScreen(playerName: _playerName!)));
    },
    child: Icon(Icons.archive, color: Colors.white),
    ),
    ),
    Positioned(
      bottom: 16,
      left: 80, // بجانب الزر الأول
      child: FloatingActionButton(
        heroTag: 'repliedMessages', // تحديد heroTag فريد
        backgroundColor: Color(0xFF3D6F5D),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PlayerRepliedMessagesScreen(playerName: _playerName!)));
        },
        child: Icon(Icons.reply_all, color: Colors.white),
      ),
    ),
        ],
        ),
    );
  }
}

// صفحة الرسائل المقروءة
class ReadMessagesScreen extends StatelessWidget {
  final String playerName;

  ReadMessagesScreen({required this.playerName});

  Future<void> _replyToMessage(BuildContext context, String messageId, String? existingReply) async {
    if (existingReply != null) return;

    TextEditingController replyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على الرسالة'),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(labelText: 'اكتب ردك هنا'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
                  'reply': replyController.text,
                  'isRead': true,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color(0xFF3D6F5D),
          title: Text('الرسائل المقروءة', style: TextStyle(color: Colors.white)),
        ),
        body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
        .where('receiverId', isEqualTo: playerName)
        .where('isRead', isEqualTo: true)
        .orderBy('dateTime', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: TextStyle(color: Colors.red)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(
    child: Text('لا توجد رسائل مقروءة',
    style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    var messages = snapshot.data!.docs;

    return ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: messages.length,
    itemBuilder: (context, index) {
    var message = messages[index].data() as Map<String, dynamic>;
    String messageId = messages[index].id;
    String title = message['title'] ?? 'بدون عنوان';
    String content = message['content'] ?? '';
    String senderName = message['senderName'] ?? 'مجهول';
    String? reply = message['reply'];
    Timestamp? dateTime = message['dateTime'];
    String formattedDate = dateTime != null
    ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
    : 'غير محدد';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              'من: $senderName',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'التاريخ: $formattedDate',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                  fontSize: 16, color: Colors.black87, height: 1.4),
            ),
            if (reply != null) ...[
              SizedBox(height: 12),
              Text(
                'الرد: $reply',
                style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3D6F5D),
                    fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: 16),
            if (reply == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.reply, color: Color(0xFF3D6F5D)),
                    label: Text('الرد',
                        style: TextStyle(color: Color(0xFF3D6F5D))),
                    onPressed: () => _replyToMessage(context, messageId, reply),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    },
    );
    },
        ),
    );
  }
}

// صفحة جديدة لعرض الردود على رسائل اللاعب
class PlayerRepliedMessagesScreen extends StatelessWidget {
  final String playerName;

  const PlayerRepliedMessagesScreen({required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF3D6F5D),
          title: const Text('الردود على رسائلك', style: TextStyle(color: Colors.white)),
        ),
        body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
        .where('senderName', isEqualTo: playerName)
        .where('reply', isNotEqualTo: null)
        .orderBy('dateTime', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: const TextStyle(color: Colors.red)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return const Center(
    child: Text('لا توجد ردود على رسائلك',
    style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
    var messages = snapshot.data!.docs;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        var message = messages[index].data() as Map<String, dynamic>;
        String title = message['title'] ?? 'بدون عنوان';
        String content = message['content'] ?? '';
        String receiverName = message['receiverId'] ?? 'مجهول';
        String reply = message['reply'] ?? '';
        Timestamp? dateTime = message['dateTime'];
        String formattedDate = dateTime != null
            ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
            : 'غير محدد';
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'إلى: $receiverName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'التاريخ: $formattedDate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  'الرسالة: $content',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'الرد: $reply',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF3D6F5D),
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
    },
        ),
    );
  }
}