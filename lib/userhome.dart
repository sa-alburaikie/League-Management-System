// lib/screens/user_home.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hadramootleagues/playerprofiledetailsscreen.dart';
import 'package:hadramootleagues/teamprofiledetailsscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aboutapp.dart';
import 'leagueslistscreen.dart';
import 'main.dart';
import 'matchesdisplayscreen.dart';

class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedIndex = 0;

  // قائمة الصفحات للـ BottomNavigationBar
  final List<Widget> _pages = [
    LeaguesListScreen(), // الدوريات
    TeamsListScreen(), // الفرق
    PlayersTeamsListScreen(), // اللاعبين
    MatchesDisplayScreen(), // المباريات
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // بناء عنصر Drawer
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                Color(0xFFF5F7F6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3D6F5D).withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Color(0xFF3D6F5D),
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D6F5D),
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF3D6F5D).withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
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

    // الانتقال إلى صفحة LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          _selectedIndex == 0
              ? 'الدوريات'
              : _selectedIndex == 1
              ? 'الفرق'
              : _selectedIndex == 2
              ? 'اللاعبين'
              : 'المباريات',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        elevation: 10,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 20),
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3D6F5D),
                    Color(0xFF5A8F7B),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'نظام إدارة دوريات',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'وادي حضرموت',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home,
                    title: 'الصفحة الرئيسية',
                    onTap: () {
                      Navigator.pop(context); // إغلاق الـ Drawer
                      setState(() {
                        _selectedIndex = 0; // العودة إلى تبويب الدوريات
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'حول التطبيق',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutApp()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'تسجيل الدخول',
                    onTap: () {
                      Navigator.pop(context);
                      _login(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF3D6F5D),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'الدوريات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'الفرق',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'اللاعبين',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'المباريات',
          ),
        ],
      ),
    );
  }
}