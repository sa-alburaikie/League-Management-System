//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:hadramootleagues/leaguepage.dart';
//
// import 'createleague.dart';
//
// class AdminHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Color(0xFF3D6F5D),
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {},
//         ),
//         title: Text(
//           'الصفحة الرئيسية للمسؤول',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100),
//         child: Center(
//           child: GridView.count(
//             crossAxisCount: 3,
//             crossAxisSpacing: 20,
//             mainAxisSpacing: 20,
//             childAspectRatio: 0.7,
//
//             children: [
//               menuItem('إنشاء دوري', Icons.add,context),
//               menuItem('إدارة دوري', Icons.group,context),
//               menuItem('الأخبار', Icons.article,context),
//               menuItem('البريد', Icons.mail,context),
//               menuItem('     إدارة'+'\n'+'المستخدمين', Icons.supervised_user_circle,context),
//               menuItem('التحكم', Icons.tune,context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget menuItem(String title, IconData icon,BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         InkWell(
//           onTap: (){
//             if(title=="إنشاء دوري"){
//               Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateLeagueScreen(),));
//             }
//             else if(title=="إدارة دوري"){
//               Navigator.of(context).push(MaterialPageRoute(builder: (context) => LeaguePage(),));
//             }
//           },
//           child: Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: Color(0xFF3D6B56),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.white, size: 36),
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           title,
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }
// }




import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hadramootleagues/addnewsscreen.dart';
import 'package:hadramootleagues/adminmailscreen.dart';
import 'package:hadramootleagues/leaguepage.dart';
import 'package:hadramootleagues/main.dart';
import 'package:hadramootleagues/manageleaguesscreen.dart';
import 'package:hadramootleagues/matchespage.dart';
import 'package:hadramootleagues/usermanagementscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'createleague.dart';

class AdminHomePage extends StatefulWidget {
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {

  void _logout() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد تسجيل الخروج'),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              // حذف بيانات SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              GoogleSignIn().signOut();
    Navigator.of(context).pop(true);
    },
            child: Text('موافق'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // حذف البيانات من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('accountType');

      // إعادة التوجيه إلى صفحة تسجيل الدخول
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar( backgroundColor: Color(0xFF3D6F5D),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text( 'الصفحة الرئيسية للمسؤول',
          style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2, ),
        ),
        centerTitle: true, ),
      body:
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
        child: Center(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.65,
            children: [
              menuItem('إنشاء دوري', Icons.add, context),
              menuItem('إدارة دوري', Icons.group, context),
              menuItem('الأخبار', Icons.article, context),
              menuItem('البريد', Icons.mail, context),
              menuItem(' إدارة\nالمستخدمين', Icons.supervised_user_circle, context),
              menuItem('المباريات', Icons.sports_soccer, context),
              menuItem('تسجيل الخروج', Icons.logout, context), ], ), ), ), ); }
 Widget
  menuItem(String title, IconData icon, BuildContext context) {
    return AnimatedMenuItem(
      title: title, icon: icon, onTap: () {
      if (title == "إنشاء دوري") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => CreateLeagueScreen()),
        ); }
      else if (title == "إدارة دوري") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => ManageLeaguesScreen()),
        ); }
      else if (title == "الأخبار") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => AddNewsScreen()),
        ); }
      else if (title == "البريد") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => AdminMailScreen()),
        ); }
      else if (title == " إدارة\nالمستخدمين") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => UserManagementScreen()),
        ); }
      else if (title == "المباريات") {
        Navigator.of(context).push( MaterialPageRoute(builder: (context) => MatchesPage()),
        ); }
      else if (title == "تسجيل الخروج") {
        _logout();
         }
      }, ); }}

class AnimatedMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const AnimatedMenuItem({
    required this.title,
    required this.icon,
    required this.onTap, });

  @override _AnimatedMenuItemState createState() => _AnimatedMenuItemState(); }

class _AnimatedMenuItemState extends State<AnimatedMenuItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override void initState() {
    super.initState();
    _controller = AnimationController( duration: const Duration(milliseconds: 300), vsync: this, );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate( CurvedAnimation(parent: _controller,
        curve: Curves.easeInOut), ); } @override void dispose() { _controller.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(), onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap, child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration( color: Color(0xFF3D6F5D),
                shape: BoxShape.circle,
                gradient: LinearGradient( colors: [ Color(0xFF3D6F5D), Color(0xFF5A8F7B), ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight, ),
                boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.2),
                  blurRadius: 8, offset: Offset(0, 4), ), ], ),
              child: (widget.icon==Icons.logout)?
                  Transform(alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14),child: Icon(widget.icon,color: Colors.white,size: 40,),)
              :Icon( widget.icon, color: Colors.white, size: 40, ), ),
            SizedBox(height: 12), Text( widget.title, textAlign: TextAlign.center,
              style: TextStyle( fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3D6F5D),
                shadows: [ Shadow( color: Colors.black.withOpacity(0.1), offset: Offset(0, 2),
                  blurRadius: 4, ),
                ], ), ), ],
        ), ), ), );
  }
}