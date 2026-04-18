import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق الوقت

class MatchesDetails extends StatefulWidget {
  final String leagueId;

  MatchesDetails({required this.leagueId});

  @override
  _MatchesDetailsState createState() => _MatchesDetailsState();
}

class _MatchesDetailsState extends State<MatchesDetails> {

  @override
  Widget build(BuildContextContext) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('المباريات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get(),
        builder: (context, leagueSnapshot) {
          if (!leagueSnapshot.hasData) return Center(child: CircularProgressIndicator());
          String leagueName = leagueSnapshot.data!['leagueName'] ?? 'دوري غير معروف';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .where('leagueId', isEqualTo: widget.leagueId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              // تجميع المباريات حسب التاريخ
              Map<String, List<Map<String, dynamic>>> matchDays = {};
              for (var doc in snapshot.data!.docs) {
                var match = doc.data() as Map<String, dynamic>;
                match['id'] = doc.id;
                String date = match['matchDate'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(match['matchDate'].millisecondsSinceEpoch)
                    .toString()
                    .substring(0, 10) // YYYY-MM-DD
                    : 'غير محدد';
                if (!matchDays.containsKey(date)) matchDays[date] = [];
                matchDays[date]!.add(match);
              }

              if (matchDays.isEmpty) {
                return Center(child: Text('لا توجد مباريات بعد', style: TextStyle(fontSize: 18)));
              }

              // ترتيب التواريخ تصاعديًا
              var sortedMatchDays = matchDays.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: sortedMatchDays.map((entry) {
                            return buildMatchDay({
                              'date': entry.key,
                              'league': leagueName,
                              'matches': entry.value,
                            });
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// تصميم اليوم والبطاقات الخاصة به
  Widget buildMatchDay(Map<String, dynamic> day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: buildDateBadge(day["date"])),
        SizedBox(height: 10),
        buildLeagueBadge(day["league"]),
        SizedBox(height: 10),
        buildMatchCard(day["matches"]),
        SizedBox(height: 20),
      ],
    );
  }

  /// تصميم البادج الخاص بالتاريخ
  Widget buildDateBadge(String date) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        date,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  /// تصميم بادج اسم الدوري
  Widget buildLeagueBadge(String league) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          league,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  /// تصميم بطاقة تحتوي على قائمة المباريات
  Widget buildMatchCard(List<Map<String, dynamic>> matches) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: matches.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> match = entry.value;
          return Column(
            children: [
              buildMatchRow(match),
              if (index < matches.length - 1) Divider(height: 1, color: Colors.white),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// تصميم صف يحتوي على مباراة واحدة
  Widget buildMatchRow(Map<String, dynamic> match) {
    String matchId = match['id'];

    String displayText;
    if (match['isFinished'] == true && match['result']?.isNotEmpty == true) {
      displayText = match['result'];
    } else {
      displayText = match['matchDate'] != null
          ? DateFormat('HH:mm').format(
          DateTime.fromMillisecondsSinceEpoch(match['matchDate'].millisecondsSinceEpoch))
          : 'غير محدد';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildTeam(match['team2'], isLeft: true), // Away team (left)
          Text(
            displayText,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          buildTeam(match['team1'], isLeft: false), // Home team (right)
        ],
      ),
    );
  }

  /// تصميم الفريق (نص + صورة أو دائرة خضراء)
  Widget buildTeam(String teamName, {required bool isLeft}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('teams').doc(teamName).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(width: 24, height: 24, child: CircularProgressIndicator());

        var teamData = snapshot.data?.data() as Map<String, dynamic>?;
        String? teamImage = teamData?['teamImage'];

        Widget imageWidget = teamImage != null && teamImage.isNotEmpty
            ? ClipOval(
          child: Image.network(
            teamImage,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
        )
            : Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
        );

        return Row(
          children: isLeft
              ? [imageWidget, SizedBox(width: 6), Text(teamName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))]
              : [Text(teamName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)), SizedBox(width: 6), imageWidget],
        );
      },
    );
  }
}