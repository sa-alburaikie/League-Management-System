// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hadramootleagues/aboutapp.dart';
// import 'package:hadramootleagues/leaguedetails.dart';
// import 'package:hadramootleagues/leaguepage.dart';
// import 'package:hadramootleagues/main.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class LeaguesListScreen extends StatefulWidget {
//   @override
//   State<LeaguesListScreen> createState() => _LeaguesListScreenState();
// }
//
// class _LeaguesListScreenState extends State<LeaguesListScreen> {
//
//   void initState(){
//     super.initState();
//     // logout();
//   }
//   // void logout() async{
//   //     // تسجيل الخروج من Firebase
//   //     await FirebaseAuth.instance.signOut();
//   //     GoogleSignIn().signOut();
//   //     }
//   // دالة لجلب بيانات الدوريات من Firestore
//   Future<List<Map<String, dynamic>>> _getLeaguesFromFirestore() async {
//     final snapshot = await FirebaseFirestore.instance.collection('leagues').get();
//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       return {
//         'id': doc.id, // إضافة id هنا
//         'name': data['leagueName'],
//         'endDate': (data['endDate'] as Timestamp).toDate(),
//         'image': data['image'], // تأكد أن الحقل image موجود في قاعدة البيانات إذا كان هناك صورة
//       };
//     }).toList();
//   }
//
//   Widget _buildDrawerItem({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(15),
//     child: Container(
//     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//     decoration: BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(15),
//     gradient: LinearGradient(
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//     colors: [
//     Colors.white,
//     Color(0xFFF5F7F6), // تدرج خفيف للخلفية
//     ],
//     ),
//       boxShadow: [
//         BoxShadow(
//           color: Color(0xFF3D6F5D).withOpacity(0.1),
//           blurRadius: 8,
//           offset: Offset(0, 2),
//         ),
//       ],
//     ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: Color(0xFF3D6F5D),
//             size: 28,
//           ),
//           SizedBox(width: 16),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF3D6F5D),
//             ),
//           ),
//           Spacer(),
//           Icon(
//             Icons.arrow_forward_ios,
//             size: 16,
//             color: Color(0xFF3D6F5D).withOpacity(0.7),
//           ),
//         ],
//       ),
//     ),
//     ),
//     );
//   }
//
//   Future<void> _login(BuildContext context) async {
//     // الحصول على مثيل SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//
//     // حفظ قيمة hasSeenOnBoarding قبل المسح
//     bool? hasSeenOnBoarding = prefs.getBool('hasSeenOnBoarding');
//
//     // مسح جميع البيانات من SharedPreferences
//     await prefs.clear();
//
//     // إعادة تعيين قيمة hasSeenOnBoarding إلى قيمتها الأصلية
//     if (hasSeenOnBoarding != null) {
//       await prefs.setBool('hasSeenOnBoarding', hasSeenOnBoarding);
//     }
//
//     // الانتقال إلى صفحة LoginScreen
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: Drawer(
//         width: 280, // عرض الـ Drawer
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
//         ),
//         elevation: 10, // ظل خفيف لإضفاء عمق
//         child: Column(
//           children: [
//             // الجزء العلوي (Header)
//             Container(
//               margin: EdgeInsets.only(bottom: 20),
//               height: 200,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Color(0xFF3D6F5D), // اللون الأساسي
//                     Color(0xFF5A8F7B), // تدرج أفتح قليلاً
//                   ],
//                 ),
//                 borderRadius: BorderRadius.only(
//                   topRight: Radius.circular(20),
//                   bottomLeft: Radius.circular(40),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 10,
//                     offset: Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.sports_soccer, // أيقونة رياضية كمثال
//                       size: 60,
//                       color: Colors.white,
//                     ),
//                     SizedBox(height: 10),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 40),
//                       child: Text(
//                         'نظام إدارة دوريات',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 40),
//                       child: Text(
//                         'وادي حضرموت',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // الخيارات
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   _buildDrawerItem(
//                     context: context,
//                     icon: Icons.info_outline,
//                     title: 'حول التطبيق',
//                     onTap: () {
//                       Navigator.pop(context);
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => AboutApp(),)); // عرض نافذة "حول التطبيق"
//                     },
//                   ),
//                   _buildDrawerItem(
//                     context: context,
//                     icon: Icons.logout,
//                     title: 'تسجيل الدخول',
//                     onTap: () {
//                       Navigator.pop(context); // إغلاق الـ Drawer
//                       _login(context); // تنفيذ تسجيل الخروج
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       appBar: AppBar(
//         iconTheme: IconThemeData(color: Colors.white),
//         backgroundColor: Color(0xFF3D6F5D),
//         title: Text('قائمة الدوريات', style: TextStyle(
//             color: Colors.white, fontWeight: FontWeight.bold
//         )),
//         centerTitle: true,
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _getLeaguesFromFirestore(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('حدث خطأ في جلب البيانات'));
//           }
//           final leagues = snapshot.data ?? [];
//           return ListView.builder(
//             itemCount: leagues.length,
//             itemBuilder: (context, index) {
//               final league = leagues[index];
//               final endDate = league['endDate'];
//               final isFinished = endDate.isBefore(DateTime.now());
//               final leagueStatus = isFinished ? 'مكتمل' : 'جاري';
//
//               return Card(
//                 margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 elevation: 5,
//                 child: ListTile(
//                   leading: league['image'] != null
//                       ? Image.network(league['image'])
//                       : Icon(Icons.sports_soccer, size: 30, color: Color(0xFF3D6F5D)),
//                   title: Text(league['name']),
//                   subtitle: Text('الحالة: $leagueStatus'),
//                   trailing: Icon(Icons.arrow_forward_ios),
//                   onTap: () {
//                     // تمرير leagueId إلى صفحة LeaguePage
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => Leaguedetails(leagueId: league['id']),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }


// lib/screens/leagues_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'leaguedetails.dart';

class LeaguesListScreen extends StatelessWidget {
  // دالة لجلب بيانات الدوريات من Firestore
  Future<List<Map<String, dynamic>>> _getLeaguesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('leagues').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['leagueName']?.toString() ?? 'دوري غير معروف',
        'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'image': data['image']?.toString(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getLeaguesFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ في جلب البيانات',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
          );
        }
        final leagues = snapshot.data ?? [];
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final league = leagues[index];
            final endDate = league['endDate'] as DateTime;
            final isFinished = endDate.isBefore(DateTime.now());
            final leagueStatus = isFinished ? 'مكتمل' : 'جاري';

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  leading: league['image'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      league['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.sports_soccer,
                        size: 30,
                        color: Color(0xFF3D6F5D),
                      ),
                    ),
                  )
                      : Icon(Icons.sports_soccer, size: 30, color: Color(0xFF3D6F5D)),
                  title: Text(
                    league['name'],
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'الحالة: $leagueStatus',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF3D6F5D)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Leaguedetails(leagueId: league['id']),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}