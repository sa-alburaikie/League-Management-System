import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hadramootleagues/browse.dart';
import 'package:hadramootleagues/main.dart';
import 'package:hadramootleagues/playerstransfer.dart';
import 'package:hadramootleagues/showplayers.dart';
import 'package:hadramootleagues/teaminbox.dart';
import 'package:hadramootleagues/teampage.dart';
import 'package:hadramootleagues/teamrequests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'contactadmin.dart';
import 'contactplayers.dart';

class News extends StatefulWidget {
  News({super.key});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  String? _teamName;
  String? userId;

  @override
  void initState() {
    super.initState();
    createData();
  }

  void logout() async{
      // تسجيل الخروج من Firebase
      await FirebaseAuth.instance.signOut();
      GoogleSignIn().signOut();
      // الحصول على مثيل SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // حفظ قيمة hasSeenOnBoarding قبل المسح
      bool? hasSeenOnBoarding = prefs.getBool('hasSeenOnBoarding');

      // مسح جميع البيانات من SharedPreferences
      await prefs.clear();

      // إعادة تعيين قيمة hasSeenOnBoarding إلى قيمتها الأصلية
      if (hasSeenOnBoarding != null) {
        await prefs.setBool('hasSeenOnBoarding', hasSeenOnBoarding);
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
      }

  Future<void> createData() async {
    String _name;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? '';
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
        });
      }
      // الحصول على مرجع الـ document
      DocumentReference docRef = FirebaseFirestore.instance.collection('teams').doc(userId);

      // التحقق مما إذا كان الـ document موجودًا
      DocumentSnapshot docSnapshot = await docRef.get();

      // إذا لم يكن الـ document موجودًا، قم بإنشائه
      if (!docSnapshot.exists) {
        await docRef.set({
          'teamname': _name,
          'maincolor': null,
          'location': null,
          'phone': null,
          'date': null,
          'playernumber': null,
          'email': null,
          'imageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error in createData: $e');
    }
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamName = prefs.getString('name');
    });
  }

  Future<void> _markNewsAsRead(String newsDocId) async {
    if (_teamName == null) return;
    var existingDoc = await FirebaseFirestore.instance
        .collection('news_read_status')
        .where('newsId', isEqualTo: newsDocId)
        .where('userId', isEqualTo: _teamName)
        .get();

    if (existingDoc.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('news_read_status').add({
        'newsId': newsDocId,
        'userId': _teamName,
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
    if (_teamName == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "صفحة الفريق",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        leading: PopupMenuButton<int>(
          icon: Icon(Icons.more_vert, color: Colors.white), // أيقونة المزيد
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.grey[200], // لون خلفية القائمة
          itemBuilder: (context) => [
            _buildMenuItem(1, "بروفايل الفريق"),
            _buildDivider(),
            _buildMenuItem(2, "التصفح"),
            _buildDivider(),
            _buildMenuItem(3, "عرض اللاعبين"),
            _buildDivider(),
            _buildMenuItem(4, "انتقالات اللاعبين"),
            _buildDivider(),
            _buildMenuItem(5, "الطلبات"),
            _buildDivider(),
            _buildMenuItem(6, "التواصل مع اللاعبين"),
            _buildDivider(),
            _buildMenuItem(7, "التواصل مع وزارة الشباب"),
            _buildDivider(),
            _buildMenuItem(8, "البريد"),
            _buildDivider(),
            _buildMenuItem(9, "تسجيل الخروج"),
          ],
          onSelected: (value) {
            // تنفيذ الإجراء المطلوب عند اختيار عنصر
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        color: Color(0xFF3D6F5D),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('news')
              .where('target', whereIn: ['الجميع', 'الفرق'])
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
                      .where('userId', isEqualTo: _teamName)
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
                                  // MaterialButton(onPressed: () async {
                                  //       await FirebaseAuth.instance.signOut();
                                  //       GoogleSignIn().signOut();
                                  //       Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => LoginScreen(),));
                                  // },child: Text("click")),
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

  PopupMenuItem<int> _buildDivider() {
    return PopupMenuItem<int>(
      enabled: false,
      child: Divider(height: 1, color: Colors.grey[400]),
    );
  }

  PopupMenuItem<int> _buildMenuItem(int value, String text) {
    return PopupMenuItem<int>(
      onTap: (){
        if(value==1){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamProfileScreen(teamId: userId!),));
        }
        else if(value==2){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => Browse(),));
        }
        else if(value==3){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ShowPlayers(teamId:userId!),));
        }
        else if(value==4){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayersTransfer(teamId: userId!),));
        }
        else if(value==5){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamRequests(teamId: userId!),));
        }
        else if(value==6){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ContactPlayers(teamId:userId!),));

        }
        else if(value==7){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ContactAdmin(teamId:userId!),));
        }
        else if(value==8){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamInboxScreen(teamId: userId!),));
        }
        else if(value==9){
          logout();
        }
      },
      height: 10,
      padding: EdgeInsets.symmetric(vertical: 0),
      value: value,
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}