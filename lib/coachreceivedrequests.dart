import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CoachReceivedRequests extends StatefulWidget {
  @override
  State<CoachReceivedRequests> createState() => _CoachReceivedRequestsState();
}

class _CoachReceivedRequestsState extends State<CoachReceivedRequests> {
  String? _coachName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoachName();
  }

  Future<void> _loadCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coachName = prefs.getString('name');
      _isLoading = false;
    });
  }

  Future<String?> _getTeamImage(String teamName) async {
    var teamQuery = await FirebaseFirestore.instance
        .collection('teams')
        .where('teamname', isEqualTo: teamName)
        .limit(1)
        .get();
    if (teamQuery.docs.isNotEmpty && teamQuery.docs.first['teamimage'] != null) {
      return teamQuery.docs.first['teamimage'];
    }
    return null;
  }

  Future<bool> _canJoinTeam() async {
    var coachQuery = await FirebaseFirestore.instance
        .collection('coaches')
        .where('name', isEqualTo: _coachName)
        .limit(1)
        .get();
    if (coachQuery.docs.isNotEmpty) {
      var club = coachQuery.docs.first['club'];
      return club == null || club.isEmpty;
    }
    return true;
  }

  Future<void> _cancelPendingRequests(String currentRequestId) async {
    var pendingRequests = await FirebaseFirestore.instance
        .collection('requests')
        .where('senderName', isEqualTo: _coachName)
        .where('requestStatus', isEqualTo: 'في انتظار الرد')
        .get();

    for (var doc in pendingRequests.docs) {
      if (doc.id != currentRequestId) {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(doc.id)
            .update({'requestStatus': 'تم إلغاء الطلب'});
      }
    }
  }

  Future<void> _handleRequest(String requestId, String senderName, bool accept) async {
    if (accept) {
      bool canJoin = await _canJoinTeam();
      if (!canJoin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن الانضمام للفريق لأنك تدرب فريقًا آخر بالفعل. قم بالاستقالة أولاً.'),
          ),
        );
        return;
      }
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'تأكيد القبول' : 'تأكيد الرفض'),
        content: Text(accept ? 'هل تؤكد قبول الطلب؟' : 'هل تؤكد رفض الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (accept) {
        var coachQuery = await FirebaseFirestore.instance
            .collection('coaches')
            .where('name', isEqualTo: _coachName)
            .limit(1)
            .get();
        if (coachQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('coaches')
              .doc(coachQuery.docs.first.id)
              .update({'club': senderName});
        }
        await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
          'requestStatus': 'تم القبول',
        });
        await _cancelPendingRequests(requestId);
      } else {
        await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
          'requestStatus': 'تم الرفض',
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'تم قبول الطلب' : 'تم رفض الطلب')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF3D6F5D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            'الطلبات المستقبلة للمدرب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF3D6F5D),
          elevation: 0,
        ),
        body: Container(
            width: double.infinity,
            child: Column(
                children: [
                SizedBox(height: 16),
            Expanded(
            child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
        .where('receiverName', isEqualTo: _coachName)
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
    'لا يوجد طلبات مستقبلة بعد!',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    ),
    );
    }

    var requests = snapshot.data!.docs;

    return ListView.separated(
    padding: EdgeInsets.symmetric(vertical: 10),
    itemCount: requests.length,
    separatorBuilder: (context, index) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(thickness: 1),
    ),
    itemBuilder: (context, index) {
    var request = requests[index].data() as Map<String, dynamic>;
    String requestId = requests[index].id;
    String senderName = request['senderName'] ?? '';
    String type = request['Type'] ?? '';
    String requestStatus = request['requestStatus'] ?? '';
    Timestamp? dateTime = request['dateTime'];
    String formattedDate = dateTime != null
    ? DateFormat('yyyy-MM-dd – kk:mm').format(dateTime.toDate())
        : 'غير محدد';
    return FutureBuilder<String?>(
      future: _getTeamImage(senderName),
      builder: (context, imageSnapshot) {
        return _buildRequestItem(
          requestId: requestId,
          senderName: senderName,
          type: type,
          dateTime: formattedDate,
          requestStatus: requestStatus,
          imageUrl: imageSnapshot.data,
        );
      },
    );
    },
    );
    },
        ),
            ),
            ),
                ],
            ),
        ),
    );
  }

  Widget _buildRequestItem({
    required String requestId,
    required String senderName,
    required String type,
    required String dateTime,
    required String requestStatus,
    String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null ? Icon(Icons.group, size: 28, color: Colors.grey[600]) : null,
          ),
        ),
        title: Text(
          senderName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النوع: $type',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'تاريخ الإرسال: $dateTime',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: requestStatus == 'في انتظار الرد'
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton("رفض", Colors.teal[50]!, Colors.black, () {
              _handleRequest(requestId, senderName, false);
            }),
            SizedBox(width: 8),
            _buildActionButton("قبول", Colors.teal[700]!, Colors.white, () {
              _handleRequest(requestId, senderName, true);
            }),
          ],
        )
            : Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: requestStatus == 'تم القبول' ? Color(0xFF3D6F5D) : Colors.red[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            requestStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}