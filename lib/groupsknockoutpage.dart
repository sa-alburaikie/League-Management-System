import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupsKnockoutPage extends StatelessWidget {
  final String leagueId;

  GroupsKnockoutPage({required this.leagueId});

  @override
  Widget build(BuildContextContext) {
    return Scaffold(
        appBar: AppBar(
          title: Text("دور المجموعات + الإقصائية", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('leagues').doc(leagueId).snapshots(),
    builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
    var leagueData = snapshot.data!.data() as Map<String, dynamic>;
    List<String> teams = List.from(leagueData['selectedTeams']);
    int groupSize = 4;
    List<List<String>> groups = [];
    for (int i = 0; i < teams.length; i += groupSize) {
    groups.add(teams.sublist(i, i + groupSize > teams.length ? teams.length : i + groupSize));
    }

    return SingleChildScrollView(
    child: Container(
    color: Colors.grey[100],
    child: Column(
    children: [
    Container(
    padding: EdgeInsets.all(16),
    color: Colors.green,
    child: Text(
    leagueData['leagueName'],
    style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
    ),
    ),
    ...groups.asMap().entries.map((entry) {
    int idx = entry.key;
    List<String> groupTeams = entry.value;
    return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('matches')
        .where('leagueId', isEqualTo: leagueId)
        .snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> matchSnapshot) {
    if (!matchSnapshot.hasData) return CircularProgressIndicator();

    Map<String, Map<String, int>> standings = {};
    for (var team in groupTeams) {
    standings[team] = {
    'points': 0,
    'played': 0,
    'goalsFor': 0,
    'goalsAgainst': 0,
    };
    }

    for (var doc in matchSnapshot.data!.docs) {
    var match = doc.data() as Map<String, dynamic>;
    if (match['result'].isNotEmpty && groupTeams.contains(match['team1']) && groupTeams.contains(match['team2'])) {
    String team1 = match['team1'];
    String team2 = match['team2'];
    int goals1 = match['goals1'] ?? 0;
    int goals2 = match['goals2'] ?? 0;

    standings[team1]!['played'] = standings[team1]!['played']! + 1;
    standings[team2]!['played'] = standings[team2]!['played']! + 1;
    standings[team1]!['goalsFor'] = standings[team1]!['goalsFor']! + goals1;
    standings[team2]!['goalsFor'] = standings[team2]!['goalsFor']! + goals2;
    standings[team1]!['goalsAgainst'] = standings[team1]!['goalsAgainst']! + goals2;
    standings[team2]!['goalsAgainst'] = standings[team2]!['goalsAgainst']! + goals1;

    if (goals1 > goals2) standings[team1]!['points'] = standings[team1]!['points']! + 3;
    else if (goals1 < goals2) standings[team2]!['points'] = standings[team2]!['points']! + 3;
    else {
      standings[team1]!['points'] = standings[team1]!['points']! + 1;
      standings[team2]!['points'] = standings[team2]!['points']! + 1;
    }
    }
    }

    var sortedTeams = standings.entries.toList()
      ..sort((a, b) => b.value['points']!.compareTo(a.value['points']!));

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "المجموعة ${String.fromCharCode(65 + idx)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 8),
            DataTable(
              columnSpacing: 16,
              columns: [
                DataColumn(label: Text('الفريق', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('النقاط')),
                DataColumn(label: Text('لعب')),
                DataColumn(label: Text('له')),
                DataColumn(label: Text('عليه')),
              ],
              rows: sortedTeams.map((team) {
                return DataRow(cells: [
                  DataCell(Text(team.key)),
                  DataCell(Text(team.value['points'].toString())),
                  DataCell(Text(team.value['played'].toString())),
                  DataCell(Text(team.value['goalsFor'].toString())),
                  DataCell(Text(team.value['goalsAgainst'].toString())),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
    },
    );
    }).toList(),
      Padding(
        padding: EdgeInsets.all(16),
        child: KnockoutTree(leagueId: leagueId, groups: groups),
      ),
    ],
    ),
    ),
    );
    },
        ),
    );
  }
}

// Widget لرسم شجرة الأدوار الإقصائية
class KnockoutTree extends StatelessWidget {
  final String leagueId;
  final List<List<String>> groups;

  KnockoutTree({required this.leagueId, required this.groups});

  @override
  Widget build(BuildContextContext) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('matches').where('leagueId', isEqualTo: leagueId).snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    // تحديد المتأهلين (الأول والثاني من كل مجموعة)
    List<String> qualifiers = [];
    for (var group in groups) {
    Map<String, int> points = {};
    for (var team in group) points[team] = 0;
    for (var doc in snapshot.data!.docs) {
      var match = doc.data() as Map<String, dynamic>;
      if (match['result'].isNotEmpty && group.contains(match['team1']) && group.contains(match['team2'])) {
        int goals1 = match['goals1'] ?? 0;
        int goals2 = match['goals2'] ?? 0;
        if (goals1 > goals2) points[match['team1']] = points[match['team1']]! + 3;
        else if (goals1 < goals2) points[match['team2']] = points[match['team2']]! + 3;
        else {
          points[match['team1']] = points[match['team1']]! + 1;
          points[match['team2']] = points[match['team2']]! + 1;
        }
      }
    }
    var sorted = points.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    qualifiers.add(sorted[0].key); // الأول
    qualifiers.add(sorted[1].key); // الثاني
    }

    return Column(
      children: [
        Text("مخطط الأدوار الإقصائية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: CustomPaint(
            painter: BracketPainter(teams: qualifiers),
            child: Container(),
          ),
        ),
      ],
    );
    },
    );
  }
}

// رسم الشجرة باستخدام CustomPaint
class BracketPainter extends CustomPainter {
  final List<String> teams;

  BracketPainter({required this.teams});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double spacing = size.height / (teams.length / 2);
    for (int i = 0; i < teams.length; i += 2) {
      double y = i * spacing / 2 + spacing / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width / 4, y), paint);
      canvas.drawLine(Offset(0, y + spacing / 2), Offset(size.width / 4, y + spacing / 2), paint);
      canvas.drawLine(Offset(size.width / 4, y), Offset(size.width / 4, y + spacing / 2), paint);
    }
    // يمكنك توسيع هذا لدور نصف النهائي والنهائي حسب الحاجة
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}