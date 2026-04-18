import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminMailScreen extends StatefulWidget {
  @override
  _AdminMailScreenState createState() => _AdminMailScreenState();
}

class _AdminMailScreenState extends State<AdminMailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = Color(0xFF3D6F5D);
  String? _selectedReceiver;
  String _receiverType = 'players'; // Default to 'players'

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>?> _getUsersList(String collection) async {
    try {
      var usersSnapshot = await FirebaseFirestore.instance.collection(collection).get();
      return usersSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': collection == 'teams' ? doc['teamname'] ?? 'بدون اسم' : doc['name'] ?? 'بدون اسم',
        };
      }).toList();
    } catch (e) {
      print("خطأ أثناء جلب القائمة: $e");
      return null;
    }
  }

  Future<void> _openUserSearchDialog() async {
    var users = await _getUsersList(_receiverType);
    String? selected;

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredUsers = users ?? [];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('اختر المستلم', style: TextStyle(color: primaryColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "ابحث عن اسم المستلم",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                    ),
                    onChanged: (val) {
                      setState(() {
                        filteredUsers = users
                            ?.where((user) => user['name']!.toLowerCase().contains(val.toLowerCase()))
                            .toList() ?? [];
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (ctx, index) {
                        return ListTile(
                          title: Text(filteredUsers[index]['name'] ?? 'No name'),
                          onTap: () {
                            selected = filteredUsers[index]['name'];
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: TextStyle(color: primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedReceiver = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
    backgroundColor: primaryColor,
          title: Text('البريد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "البريد الوارد"),
              Tab(text: "إرسال بريد"),
            ],
          ),
        ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InboxTab(),
          SendMailTab(
            selectedReceiver: _selectedReceiver,
            receiverType: _receiverType,
            onReceiverTypeChanged: (value) {
              setState(() {
                _receiverType = value;
              });
            },
            openUserSearchDialog: _openUserSearchDialog,
          ),
        ],
      ),
    );
  }
}

class InboxTab extends StatelessWidget {
  Future<void> _markAsRead(String messageId) async {
    await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
      'isRead': true,
    });
  }

  Future<void> _replyToMessage(BuildContext context, String messageId) async {
    TextEditingController replyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على الرسالة', style: TextStyle(color: Color(0xFF3D6F5D))),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            labelText: 'اكتب ردك هنا',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Color(0xFF3D6F5D))),
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
                  const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: Text('إرسال', style: TextStyle(color: Color(0xFF3D6F5D))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey[100],
        child: Stack(
        children: [
        StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
        .where('receiverId', isEqualTo: 'adminId')
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
                      onPressed: () => _replyToMessage(context, messageId),
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
        heroTag: 'readMessages',
        backgroundColor: Color(0xFF3D6F5D),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminReadMessagesScreen()));
        },
        child: Icon(Icons.archive, color: Colors.white),
      ),
    ),
          Positioned(
            bottom: 16,
            left: 80,
            child: FloatingActionButton(
              heroTag: 'repliedMessages',
              backgroundColor: Color(0xFF3D6F5D),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminRepliedMessagesScreen()));
              },
              child: Icon(Icons.reply_all, color: Colors.white),
            ),
          ),
        ],
        ),
    );
  }
}

class AdminReadMessagesScreen extends StatelessWidget {
  Future<void> _replyToMessage(BuildContext context, String messageId, String? existingReply) async {
    if (existingReply != null) return;

    TextEditingController replyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على الرسالة', style: TextStyle(color: Color(0xFF3D6F5D))),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            labelText: 'اكتب ردك هنا',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Color(0xFF3D6F5D))),
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
                  const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                );
              }
            },
            child: Text('إرسال', style: TextStyle(color: Color(0xFF3D6F5D))),
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
        .where('receiverId', isEqualTo: 'adminId')
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

class AdminRepliedMessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color(0xFF3D6F5D),
          title: Text('الردود على رسائلك', style: TextStyle(color: Colors.white)),
        ),
        body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
        .where('senderName', isEqualTo: 'adminId')
            .where('reply', isNotEqualTo: null).where('reply', isNotEqualTo: '')
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
                  child: Text('لا توجد ردود على رسائلك',
                      style: TextStyle(fontSize: 18, color: Colors.grey)));
            }

            var messages = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(16),
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
                          'إلى: $receiverName',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Text(
                          'التاريخ: $formattedDate',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'الرسالة: $content',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black87, height: 1.4),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'الرد: $reply',
                          style: TextStyle(
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

class SendMailTab extends StatefulWidget {
  final String? selectedReceiver;
  final String receiverType;
  final Function(String) onReceiverTypeChanged;
  final Function openUserSearchDialog;

  SendMailTab({
    required this.selectedReceiver,
    required this.receiverType,
    required this.onReceiverTypeChanged,
    required this.openUserSearchDialog,
  });

  @override
  _SendMailTabState createState() => _SendMailTabState();
}

class _SendMailTabState extends State<SendMailTab> {
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  Future<void> _sendMessage() async {
    if (widget.selectedReceiver == null || _subjectController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("يرجى تعبئة جميع الحقول")));
    return;
    }

    setState(() {
    _isLoading = true;
    });

    await FirebaseFirestore.instance.collection('messages').add({
    'senderName': 'adminId',
    'receiverId': widget.selectedReceiver,
    'title': _subjectController.text.trim(),
    'content': _contentController.text.trim(),
    'dateTime': FieldValue.serverTimestamp(), // استخدام dateTime للإرسال
    'isRead': false,
    'reply': null,
    });

    setState(() {
    _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال البريد")));
    _subjectController.clear();
    _contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: widget.receiverType,
            decoration: InputDecoration(
              labelText: 'اختر نوع المستلم',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            items: [
              DropdownMenuItem(value: 'players', child: Text('لاعبين')),
              DropdownMenuItem(value: 'teams', child: Text('فرق')),
              DropdownMenuItem(value: 'coaches', child: Text('مدربين')),
            ],
            onChanged: (String? value) {
              widget.onReceiverTypeChanged(value!);
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3D6F5D),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => widget.openUserSearchDialog(),
            child: Text(
              widget.selectedReceiver == null ? "اختر المستلم" : "مستلم: ${widget.selectedReceiver}",
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: "عنوان الرسالة",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "محتوى الرسالة",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 24),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3D6F5D),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _sendMessage,
            child: Text("إرسال البريد", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
