import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // لاستخدام خطوط عصرية

class LeagueStatsScreen extends StatefulWidget {
  final String leagueId;

  LeagueStatsScreen({required this.leagueId});

  @override
  _LeagueStatsScreenState createState() => _LeagueStatsScreenState();
}

class _LeagueStatsScreenState extends State<LeagueStatsScreen> {
  bool _isEditing = false;
  late TextEditingController _bestPlayerController;
  late TextEditingController _topScorerController;
  late TextEditingController _bestGoalkeeperController;
  late TextEditingController _bestDefenderController;
  late TextEditingController _bestMidfielderController;
  late TextEditingController _bestForwardController;

  @override
  void initState() {
    super.initState();
    _bestPlayerController = TextEditingController();
    _topScorerController = TextEditingController();
    _bestGoalkeeperController = TextEditingController();
    _bestDefenderController = TextEditingController();
    _bestMidfielderController = TextEditingController();
    _bestForwardController = TextEditingController();
    _initializeStats();
  }

  @override
  void dispose() {
    _bestPlayerController.dispose();
    _topScorerController.dispose();
    _bestGoalkeeperController.dispose();
    _bestDefenderController.dispose();
    _bestMidfielderController.dispose();
    _bestForwardController.dispose();
    super.dispose();
  }

  Future<void> _initializeStats() async {
    var statsDoc = await FirebaseFirestore.instance.collection('leaguestatus').doc(widget.leagueId).get();
    if (!statsDoc.exists) {
      await FirebaseFirestore.instance.collection('leaguestatus').doc(widget.leagueId).set({
        'leagueId': widget.leagueId,
        'bestPlayer': '',
        'topScorer': '',
        'bestGoalkeeper': '',
        'bestDefender': '',
        'bestMidfielder': '',
        'bestForward': '',
      });
    }
    var data = statsDoc.data() as Map<String, dynamic>? ?? {};
    setState(() {
      _bestPlayerController.text = data['bestPlayer'] ?? '';
      _topScorerController.text = data['topScorer'] ?? '';
      _bestGoalkeeperController.text = data['bestGoalkeeper'] ?? '';
      _bestDefenderController.text = data['bestDefender'] ?? '';
      _bestMidfielderController.text = data['bestMidfielder'] ?? '';
      _bestForwardController.text = data['bestForward'] ?? '';
    });
  }

  Future<void> _saveStats() async {
    await FirebaseFirestore.instance.collection('leaguestatus').doc(widget.leagueId).update({
      'bestPlayer': _bestPlayerController.text,
      'topScorer': _topScorerController.text,
      'bestGoalkeeper': _bestGoalkeeperController.text,
      'bestDefender': _bestDefenderController.text,
      'bestMidfielder': _bestMidfielderController.text,
      'bestForward': _bestForwardController.text,
    });
  }

  @override
  Widget build(BuildContextContext) {
    return Scaffold(
        body: Container(
        decoration: BoxDecoration(
        gradient: LinearGradient(
        colors: [Color(0xFF3D6F5D), Colors.grey[200]!],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    ),
    ),
    child: SafeArea(
    child: Stack(
    children: [
    // خلفية متحركة خفيفة (اختيارية)
    AnimatedContainer(
    duration: Duration(seconds: 5),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),
    ),
    Column(
    children: [
      _buildAppBar(),
      Expanded(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            String leagueName = snapshot.data!['leagueName'] ?? 'دوري غير معروف';

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeagueTitle(leagueName),
                  SizedBox(height: 20),
                  buildStatCard('أفضل لاعب', Icons.star, _bestPlayerController, Colors.yellow[700]!),
                  buildStatCard('أكثر لاعب تسجيلًا', Icons.sports_soccer, _topScorerController, Colors.redAccent),
                  buildStatCard('أفضل حارس', Icons.sports_handball, _bestGoalkeeperController, Colors.blueAccent),
                  buildStatCard('أفضل مدافع', Icons.security, _bestDefenderController, Colors.greenAccent),
                  buildStatCard('أفضل لاعب وسط', Icons.directions_run, _bestMidfielderController, Colors.purpleAccent),
                  buildStatCard('أفضل مهاجم', Icons.local_fire_department, _bestForwardController, Colors.orangeAccent),
                ],
              ),
            );
          },
        ),
      ),
    ],
    ),
    ],
    ),
    ),
        ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF3D6F5D),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'إحصائيات الدوري',
            style: GoogleFonts.cairo(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_isEditing ? Colors.green : Colors.blue, Colors.white]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
              onPressed: () async {
                if (_isEditing) await _saveStats();
                setState(() => _isEditing = !_isEditing);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueTitle(String leagueName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF3D6F5D), Colors.teal]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Text(
        leagueName,
        style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildStatCard(String title, IconData icon, TextEditingController controller, Color accentColor) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withOpacity(0.2),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: controller,
                    style: GoogleFonts.cairo(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم اللاعب',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accentColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                      : Text(
                    controller.text.isEmpty ? 'لم يتم تحديده بعد' : controller.text,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: controller.text.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}