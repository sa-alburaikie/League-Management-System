import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TeamRequestState extends StatefulWidget {
  @override
  _TeamRequestState createState() => _TeamRequestState();
}

class _TeamRequestState extends State<TeamRequestState> {
  String? _teamName;

  @override
  void initState() {
    super.initState();
    _loadTeamName();
  }

  Future<void> _loadTeamName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamName = prefs.getString('name')?.trim();
      print('Team Name: $_teamName'); // تصحيح
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_teamName == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 2,
        leading: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          "حالة الطلبات المرسلة للفريق",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllTeamRequestsScreen(teamName: _teamName!),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                "حالة الطلبات المرسلة",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where('senderName', isEqualTo: _teamName)
                    .orderBy('dateTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Error: ${snapshot.error}'); // تصحيح
                    return Center(child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('No documents found for teamName: $_teamName'); // تصحيح
                    return Center(
                      child: Text(
                        'لا توجد طلبات مرسلة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D6F5D),
                        ),
                      ),
                    );
                  }

                  print('Number of documents: ${snapshot.data!.docs.length}'); // تصحيح
                  var requests = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var request = requests[index].data() as Map<String, dynamic>;
                      print('Request $index: $request'); // تصحيح
                      String type = request['type'] ?? '';
                      String receiverName = request['receiverName'] ?? '';
                      String requestStatus = request['requestStatus'] ?? '';
                      Timestamp? dateTime = request['dateTime'];
                      String formattedDate = dateTime != null
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
                          : 'غير محدد';

                      String requestTitle = type == 'طلب تدريب'
                          ? 'طلب تدريب $receiverName'
                          : 'طلب استقالة من $receiverName';

                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                requestTitle,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D6F5D),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'تاريخ الإرسال: $formattedDate',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: requestStatus == 'مقبول'
                                      ? Colors.green
                                      : requestStatus == 'مرفوض'
                                      ? Colors.red
                                      : Color(0xFF3D6F5D),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
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
                      );
                    },
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

// صفحة عرض جميع الطلبات السابقة للفريق
class AllTeamRequestsScreen extends StatelessWidget {
  final String teamName;

  AllTeamRequestsScreen({required this.teamName});

  Future<void> _deleteRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 2,
        title: Text(
          'جميع الطلبات السابقة للفريق',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('senderName', isEqualTo: teamName)
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

              String requestTitle = type == 'طلب تدريب'
                  ? 'طلب تدريب $receiverName'
                  : 'طلب استقالة من $receiverName';

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requestTitle,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D6F5D)),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'تاريخ الإرسال: $formattedDate',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'الحالة: $requestStatus',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D6F5D)),
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          label: Text('حذف', style: TextStyle(color: Colors.redAccent)),
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