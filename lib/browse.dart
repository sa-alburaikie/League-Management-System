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

class Browse extends StatefulWidget {
  @override
  _BrowseState createState() => _BrowseState();
}

class _BrowseState extends State<Browse> {
  // قائمة الصفحات للـ TabBarView
  final List<Widget> _pages = [
    LeaguesListScreen(), // الدوريات
    TeamsListScreen(), // الفرق
    PlayersTeamsListScreen(), // اللاعبين
    MatchesDisplayScreen(), // المباريات
  ];

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
    return DefaultTabController(
      length: _pages.length,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(75.0), // Increased height to fix 4px overflow
          child: AppBar(
            backgroundColor: Color(0xFF3D6F5D),
            flexibleSpace: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TabBar(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[300],
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.cairo(),
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.emoji_events, size: 24),
                      text: 'الدوريات',
                    ),
                    Tab(
                      icon: Icon(Icons.group, size: 24),
                      text: 'الفرق',
                    ),
                    Tab(
                      icon: Icon(Icons.person, size: 24),
                      text: 'اللاعبين',
                    ),
                    Tab(
                      icon: Icon(Icons.sports_soccer, size: 24),
                      text: 'المباريات',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: _pages,
        ),
      ),
    );
  }
}