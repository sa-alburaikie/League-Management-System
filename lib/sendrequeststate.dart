import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SendRequestState extends StatefulWidget {
  @override
  _SendRequestState createState() => _SendRequestState();
}

class _SendRequestState extends State<SendRequestState> {
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

  @override
  Widget build(BuildContext context) {
    if (_playerName == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3D6F5D),
          elevation: 0,
          leading: Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF3D6F5D)),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          centerTitle: true,
          title: Text(
            "حالة الطلب المرسل",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllRequestsScreen(playerName: _playerName!),
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    SizedBox(height: 30),
    Center(
    child: Text(
    "حالة الطلب المرسل",
    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
    ),
    ),
    SizedBox(height: 40),
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('requests')
        .where('senderName', isEqualTo: _playerName)
        .orderBy('dateTime', descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(
    child: Text(
    'لا يوجد أي طلب مُرسل',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    ),
    );
    }

    var request = snapshot.data!.docs.first.data() as Map<String, dynamic>;
    String type = request['type'] ?? '';
    String receiverName = request['receiverName'] ?? '';
    String requestStatus = request['requestStatus'] ?? '';
    Timestamp? dateTime = request['dateTime'];
    String formattedDate = dateTime != null
        ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
        : 'غير محدد';

    String requestTitle = type == 'طلب انضمام'
        ? 'طلب انضمام إلى $receiverName'
        : 'طلب خروج من $receiverName';

    return Center(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                requestTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                'تاريخ الإرسال: $formattedDate',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF3D6F5D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  requestStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    },
    ),
    ),
    ],
    ),
        ),
    );
  }
}

// صفحة عرض جميع الطلبات السابقة
class AllRequestsScreen extends StatelessWidget {
  final String playerName;

  AllRequestsScreen({required this.playerName});

  Future<void> _deleteRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color(0xFF3D6F5D),
          elevation: 0,
          title: Text(
            'جميع الطلبات السابقة',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
        .where('senderName', isEqualTo: playerName)
        .orderBy('dateTime', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Text(
          'لا توجد طلبات سابقة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D6F5D)),
        ),
      );
    }

    var requests = snapshot.data!.docs;

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var request = requests[index].data() as Map<String, dynamic>;
        String requestId = requests[index].id;
        String type = request['type'] ?? '';
        String receiverName = request['receiverName'] ?? '';
        String requestStatus = request['requestStatus'] ?? '';
        Timestamp? dateTime = request['dateTime'];
        String formattedDate = dateTime != null
            ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
            : 'غير محدد';

        String requestTitle = type == 'طلب انضمام'
            ? 'طلب انضمام إلى $receiverName'
            : 'طلب خروج من $receiverName';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 8),
                Text(
                  'تاريخ الإرسال: $formattedDate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'الحالة: $requestStatus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D6F5D)),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('حذف', style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      await _deleteRequest(requestId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حذف الطلب بنجاح')),
                      );
                    },
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
  }
}