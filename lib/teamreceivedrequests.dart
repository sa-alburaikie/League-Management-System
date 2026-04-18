import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TeamReceivedRequests extends StatefulWidget {
  @override
  State<TeamReceivedRequests> createState() => _TeamReceivedRequestsState();
}

class _TeamReceivedRequestsState extends State<TeamReceivedRequests> {
  String? _teamName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamName();
  }

  Future<void> _loadTeamName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamName = prefs.getString('name')?.trim();
      _isLoading = false;
      print('Team Name: $_teamName'); // تصحيح للتحقق من اسم الفريق
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

  Future<bool> _canJoinTeam(String senderName, String type) async {
    // التحقق من إمكانية انضمام اللاعب أو المدرب بناءً على نوع الطلب
    if (type == 'طلب انضمام' || type == 'طلب تدريب') {
      var collection = type == 'طلب انضمام' ? 'players' : 'coaches';
      var query = await FirebaseFirestore.instance
          .collection(collection)
          .where('name', isEqualTo: senderName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        var club = query.docs.first['club'];
        return club == null || club.isEmpty;
      }
    }
    return true;
  }

  Future<void> _cancelPendingRequests(String currentRequestId, String senderName, String type) async {
    // إلغاء الطلبات المعلقة الأخرى لنفس اللاعب/المدرب لأنواع معينة
    if (type == 'طلب انضمام' || type == 'طلب تدريب') {
      var pendingRequests = await FirebaseFirestore.instance
          .collection('requests')
          .where('senderName', isEqualTo: senderName)
          .where('requestStatus', isEqualTo: 'في انتظار الرد')
          .where('Type', isEqualTo: type)
          .get();

      for (var doc in pendingRequests.docs) {
        if (doc.id != currentRequestId) {
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(doc.id)
              .update({'requestStatus': 'تم إلغاء الطلب'});
          print('Cancelled pending request: ${doc.id}'); // تصحيح
        }
      }
    }
  }

  Future<void> _handleRequest(String requestId, String senderName, String type, bool accept, {String? playerId, String? duration}) async {
    if (accept) {
      // التحقق من إمكانية الانضمام للطلبات التي تتطلب ذلك
      if (type == 'طلب انضمام' || type == 'طلب تدريب') {
        bool canJoin = await _canJoinTeam(senderName, type);
        if (!canJoin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن قبول الطلب لأن ${type == 'طلب انضمام' ? 'اللاعب' : 'المدرب'} موجود في فريق آخر بالفعل.'),
            ),
          );
          return;
        }
      }
    }

    // عرض حوار التأكيد
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
      try {
        if (accept) {
          // معالجة جميع أنواع الطلبات مع تحديث requestStatus إلى "تم القبول"
          if (type == 'طلب انضمام') {
            var playerQuery = await FirebaseFirestore.instance
                .collection('players')
                .where('name', isEqualTo: senderName)
                .limit(1)
                .get();
            if (playerQuery.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('players')
                  .doc(playerQuery.docs.first.id)
                  .update({'club': _teamName});
              print('Updated player club to $_teamName for player: $senderName'); // تصحيح
              await _cancelPendingRequests(requestId, senderName, type);
            }
          } else if (type == 'طلب خروج') {
            var playerQuery = await FirebaseFirestore.instance
                .collection('players')
                .where('name', isEqualTo: senderName)
                .limit(1)
                .get();
            if (playerQuery.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('players')
                  .doc(playerQuery.docs.first.id)
                  .update({'club': null});
              print('Cleared player club for player: $senderName'); // تصحيح
            }
          } else if (type == 'طلب تدريب') {
            var coachQuery = await FirebaseFirestore.instance
                .collection('coaches')
                .where('name', isEqualTo: senderName)
                .limit(1)
                .get();
            if (coachQuery.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('coaches')
                  .doc(coachQuery.docs.first.id)
                  .update({'club': _teamName});
              print('Updated coach club to $_teamName for coach: $senderName'); // تصحيح
              await _cancelPendingRequests(requestId, senderName, type);
            }
          } else if (type == 'طلب استقالة') {
            var coachQuery = await FirebaseFirestore.instance
                .collection('coaches')
                .where('name', isEqualTo: senderName)
                .limit(1)
                .get();
            if (coachQuery.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('coaches')
                  .doc(coachQuery.docs.first.id)
                  .update({'club': null});
              print('Cleared coach club for coach: $senderName'); // تصحيح
            }
          } else if (type == 'طلب عرض') {
            if (playerId != null) {
              await FirebaseFirestore.instance
                  .collection('players')
                  .doc(playerId)
                  .update({'club': _teamName});
              print('Updated player club to $_teamName for playerId: $playerId'); // تصحيح
            }
          } else if (type == 'طلب شراء') {
            if (playerId != null) {
              await FirebaseFirestore.instance
                  .collection('players')
                  .doc(playerId)
                  .update({'club': senderName});
              print('Updated player club to $senderName for playerId: $playerId'); // تصحيح
            }
          } else if (type == 'طلب إعارة') {
            if (playerId != null && duration != null) {
              var playerQuery = await FirebaseFirestore.instance
                  .collection('players')
                  .doc(playerId)
                  .get();
              if (playerQuery.exists) {
                var originalClub = playerQuery.data()!['club'];
                await FirebaseFirestore.instance
                    .collection('players')
                    .doc(playerId)
                    .update({'club': _teamName});
                await FirebaseFirestore.instance
                    .collection('requests')
                    .doc(requestId)
                    .update({
                  'originalClub': originalClub,
                  'loanStartTime': FieldValue.serverTimestamp(),
                  'loanDuration': duration,
                });
                print('Updated player club to $_teamName for playerId: $playerId, originalClub: $originalClub, duration: $duration'); // تصحيح
              }
            }
          }
          // تحديث حالة الطلب إلى "تم القبول" لجميع الأنواع
          await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
            'requestStatus': 'تم القبول',
          });
          print('Updated requestStatus to تم القبول for requestId: $requestId'); // تصحيح
        } else {
          // تحديث حالة الطلب إلى "تم الرفض" عند الرفض
          await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
            'requestStatus': 'تم الرفض',
          });
          print('Updated requestStatus to تم الرفض for requestId: $requestId'); // تصحيح
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'تم قبول الطلب' : 'تم رفض الطلب')),
        );
      } catch (e) {
        print('Error handling request: $e'); // تصحيح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء معالجة الطلب: $e')),
        );
      }
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
          'الطلبات المستقبلة للفريق',
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
                      .where('receiverName', isEqualTo: _teamName)
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
                      FirebaseFirestore.instance
                          .collection('requests')
                          .get()
                          .then((querySnapshot) {
                        print('All documents in requests collection:');
                        if (querySnapshot.docs.isEmpty) {
                          print('No documents found in collection');
                        } else {
                          for (var doc in querySnapshot.docs) {
                            print('Document ID: ${doc.id}, Data: ${doc.data()}');
                          }
                        }
                      });
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

                    print('Number of documents: ${snapshot.data!.docs.length}'); // تصحيح
                    for (var doc in snapshot.data!.docs) {
                      print('Document ID: ${doc.id}, Data: ${doc.data()}'); // تصحيح
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
                        // ملاحظة: إذا كان اسم الحقل في Firestore هو 'type' بدلاً من 'Type'، استبدل 'Type' بـ 'type'
                        String type = request['Type'] ?? '';
                        String requestStatus = request['requestStatus'] ?? '';
                        String? playerId = request['playerId'];
                        String? duration = request['duration'];
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
                              playerId: playerId,
                              duration: duration,
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
    String? playerId,
    String? duration,
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
            if (playerId != null)
              Text(
                'معرف اللاعب: $playerId',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            if (duration != null)
              Text(
                'مدة الإعارة: $duration',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: requestStatus == 'في انتظار الرد'
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton("رفض", Colors.teal[50]!, Colors.black, () {
              _handleRequest(requestId, senderName, type, false, playerId: playerId, duration: duration);
            }),
            SizedBox(width: 8),
            _buildActionButton("قبول", Colors.teal[700]!, Colors.white, () {
              _handleRequest(requestId, senderName, type, true, playerId: playerId, duration: duration);
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