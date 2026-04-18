import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KnockoutLeaguePage extends StatelessWidget {
  final String leagueId;

  KnockoutLeaguePage({required this.leagueId});

  @override
  Widget build(BuildContextContext) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("الرئيسية", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
          backgroundColor: Color(0xFF3D6F5D),
          elevation: 0,
        ),
        body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('leagues').doc(leagueId).snapshots(),
    builder: (context, AsyncSnapshot<DocumentSnapshot> leagueSnapshot) {
    if (!leagueSnapshot.hasData) {
    return Center(child: CircularProgressIndicator());
    }
    var leagueData = leagueSnapshot.data!.data() as Map<String, dynamic>;

    return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('matches')
        .where('leagueId', isEqualTo: leagueId)
        .snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> matchSnapshot) {
    if (!matchSnapshot.hasData) {
    return Center(child: CircularProgressIndicator());
    }

    List<Map<String, dynamic>> matches = matchSnapshot.data!.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    return Container(
    color: Colors.grey[100],
    child: Column(
    children: [
      // قسم المباريات
    Expanded(
    child: matches.isEmpty
    ? Center(
    child: Text(
    "لا توجد مباريات بعد",
    style: TextStyle(fontSize: 18, color: Colors.grey),
    ),
    )
        : ListView.builder(
    itemCount: matches.length,
    itemBuilder: (context, index) {
    var match = matches[index];
    return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
    leading: Icon(Icons.sports_soccer, color: Color(0xFF3D6F5D)),
    title: Text(
    "${match['team1']} vs ${match['team2']}",
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Text(
    match['result'].isNotEmpty
    ? "النتيجة: ${match['goals1']} - ${match['goals2']}"
    : "قادمة",
      style: TextStyle(color: Colors.grey[600]),
    ),
    ),
    );
    },
    ),
    ),
      // قسم الشجرة
      if (matches.isNotEmpty)
        Container(
          height: 300,
          padding: EdgeInsets.all(16),
          child: CustomPaint(
            painter: KnockoutBracketPainter(matches: matches),
            child: Center(
              child: Text(
                "مخطط الدوري",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D6F5D),
                ),
              ),
            ),
          ),
        ),
    ],
    ),
    );
    },
    );
    },
        ),
    );
  }
}

// رسم الشجرة باستخدام CustomPaint
class KnockoutBracketPainter extends CustomPainter {
  final List<Map<String, dynamic>> matches;

  KnockoutBracketPainter({required this.matches});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF3D6F5D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double spacing = size.height / (matches.length + 1);
    for (int i = 0; i < matches.length; i++) {
      double y = (i + 1) * spacing;
      // خط أفقي لكل مباراة
      canvas.drawLine(Offset(0, y), Offset(size.width / 3, y), paint);
      // خطوط ربط إذا كانت هناك مباراة تالية
      if (i % 2 == 0 && i + 1 < matches.length) {
        double nextY = (i + 2) * spacing;
        canvas.drawLine(Offset(size.width / 3, y), Offset(size.width / 3, nextY), paint);
        canvas.drawLine(Offset(size.width / 3, (y + nextY) / 2), Offset(size.width * 2 / 3, (y + nextY) / 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}