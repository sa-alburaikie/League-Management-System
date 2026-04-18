import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeamInboxScreen extends StatefulWidget {
  final String teamId;

  const TeamInboxScreen({required this.teamId});

  @override
  _TeamInboxScreenState createState() => _TeamInboxScreenState();
}

class _TeamInboxScreenState extends State<TeamInboxScreen> {
  String? _teamName;

  @override
  void initState() {
    super.initState();
    _loadTeamName();
  }

  Future<void> _loadTeamName() async {
    final teamDoc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .get();
    setState(() {
      _teamName = teamDoc.data()?['teamname'] as String?;
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
        title: const Text('الرد على الرسالة'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(labelText: 'اكتب ردك هنا'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
                  'reply': replyController.text,
                  'isRead': true,
                  'replySender': _teamName ?? 'فريق مجهول',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_teamName == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF3D6F5D),
        title: const Text('البريد الوارد', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('receiverId', isEqualTo: _teamName)
                .where('isRead', isEqualTo: false)
                .orderBy('dateTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد رسائل واردة غير مقروءة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              var messages = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 10, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'من: $senderName',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            'التاريخ: $formattedDate',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.reply, color: Color(0xFF3D6F5D)),
                                label: const Text('الرد', style: TextStyle(color: Color(0xFF3D6F5D))),
                                onPressed: () => _replyToMessage(messageId),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.check, color: Color(0xFF3D6F5D)),
                                label: const Text('تعيين كمقروء', style: TextStyle(color: Color(0xFF3D6F5D))),
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
              heroTag: 'readMessages',
              backgroundColor: const Color(0xFF3D6F5D),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamReadMessagesScreen(teamId: widget.teamId),
                  ),
                );
              },
              child: const Icon(Icons.archive, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 80,
            child: FloatingActionButton(
              heroTag: 'repliedMessages',
              backgroundColor: const Color(0xFF3D6F5D),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamRepliedMessagesScreen(teamId: widget.teamId),
                  ),
                );
              },
              child: const Icon(Icons.reply_all, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamReadMessagesScreen extends StatelessWidget {
  final String teamId;

  const TeamReadMessagesScreen({required this.teamId});

  Future<String?> _getTeamName() async {
    final teamDoc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .get();
    return teamDoc.data()?['teamname'] as String?;
  }

  Future<void> _replyToMessage(BuildContext context, String messageId, String? existingReply) async {
    if (existingReply != null) return;

    String? teamName = await _getTeamName();
    TextEditingController replyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الرد على الرسالة'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(labelText: 'اكتب ردك هنا'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
                  'reply': replyController.text,
                  'isRead': true,
                  'replySender': teamName ?? 'فريق مجهول',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getTeamName(),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamSnapshot.hasError || teamSnapshot.data == null) {
          return const Center(
            child: Text(
              'حدث خطأ أثناء تحميل اسم الفريق',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        String teamName = teamSnapshot.data!;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color(0xFF3D6F5D),
            title: const Text('الرسائل المقروءة', style: TextStyle(color: Colors.white)),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('receiverId', isEqualTo: teamName)
                .where('isRead', isEqualTo: true)
                .orderBy('dateTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد رسائل مقروءة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              var messages = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'من: $senderName',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            'التاريخ: $formattedDate',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          if (reply != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'الرد: $reply',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3D6F5D),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (reply == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.reply, color: Color(0xFF3D6F5D)),
                                  label: const Text('الرد', style: TextStyle(color: Color(0xFF3D6F5D))),
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
      },
    );
  }
}

class TeamRepliedMessagesScreen extends StatelessWidget {
  final String teamId;

  const TeamRepliedMessagesScreen({required this.teamId});

  Future<String?> _getTeamName() async {
    final teamDoc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .get();
    return teamDoc.data()?['teamname'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getTeamName(),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamSnapshot.hasError || teamSnapshot.data == null) {
          return const Center(
            child: Text(
              'حدث خطأ أثناء تحميل اسم الفريق',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        String teamName = teamSnapshot.data!;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color(0xFF3D6F5D),
            title: const Text('الردود على رسائل الفريق', style: TextStyle(color: Colors.white)),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('senderName', isEqualTo: teamName)
                .where('reply', isNotEqualTo: null)
                .orderBy('dateTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد ردود على رسائل الفريق',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
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
                  String? replySender = message['replySender'] ?? 'مجهول';
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
                              color: Colors.black87,
                            ),
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
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'الرد (من $replySender): $reply',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF3D6F5D),
                              fontStyle: FontStyle.italic,
                            ),
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
      },
    );
  }
}