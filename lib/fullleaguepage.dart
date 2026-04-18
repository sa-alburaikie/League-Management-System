import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FullLeaguePage extends StatelessWidget {
  final String leagueId;

  FullLeaguePage({required this.leagueId});

  @override
  Widget build(BuildContextContext) {
    return Scaffold(
        appBar: AppBar(
          title: Text("الدوري الكامل", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
        ),
        body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('leagues').doc(leagueId).snapshots(),
    builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
    var leagueData = snapshot.data!.data() as Map<String, dynamic>;
    List<String> teams = List.from(leagueData['selectedTeams']);

    return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('matches')
        .where('leagueId', isEqualTo: leagueId)
        .snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> matchSnapshot) {
    if (!matchSnapshot.hasData) return Center(child: CircularProgressIndicator());

    Map<String, Map<String, int>> standings = {};
    for (var team in teams) {
    standings[team] = {
    'points': 0,
    'played': 0,
    'goalsFor': 0,
    'goalsAgainst': 0,
    'wins': 0,
    'draws': 0,
    'losses': 0,
    };
    }

    for (var doc in matchSnapshot.data!.docs) {
    var match = doc.data() as Map<String, dynamic>;
    if (match['result'].isNotEmpty) {
    String team1 = match['team1'];
    String team2 = match['team2'];
    int goals1 = match['goals1'] ?? 0; // افتراضي 0 إذا لم يكن موجودًا بعد
    int goals2 = match['goals2'] ?? 0;

    standings[team1]!['played'] = standings[team1]!['played']! + 1;
    standings[team2]!['played'] = standings[team2]!['played']! + 1;
    standings[team1]!['goalsFor'] = standings[team1]!['goalsFor']! + goals1;
    standings[team2]!['goalsFor'] = standings[team2]!['goalsFor']! + goals2;
    standings[team1]!['goalsAgainst'] = standings[team1]!['goalsAgainst']! + goals2;
    standings[team2]!['goalsAgainst'] = standings[team2]!['goalsAgainst']! + goals1;

    if (goals1 > goals2) {
    standings[team1]!['points'] = standings[team1]!['points']! + 3;
    standings[team1]!['wins'] = standings[team1]!['wins']! + 1;
    standings[team2]!['losses'] = standings[team2]!['losses']! + 1;
    } else if (goals1 < goals2) {
    standings[team2]!['points'] = standings[team2]!['points']! + 3;
    standings[team2]!['wins'] = standings[team2]!['wins']! + 1;
    standings[team1]!['losses'] = standings[team1]!['losses']! + 1;
    } else {
    standings[team1]!['points'] = standings[team1]!['points']! + 1;
    standings[team2]!['points'] = standings[team2]!['points']! + 1;
    standings[team1]!['draws'] = standings[team1]!['draws']! + 1;
    standings[team2]!['draws'] = standings[team2]!['draws']! + 1;
    }
    }
    }

    var sortedTeams = standings.entries.toList()
    ..sort((a, b) => b.value['points']!.compareTo(a.value['points']!));

    return Container(
    color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blueAccent,
            child: Text(
              leagueData['leagueName'],
              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedTeams.length,
              itemBuilder: (context, index) {
                var team = sortedTeams[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text("${index + 1}", style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(team.key, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "نقاط: ${team.value['points']} | لعب: ${team.value['played']} | له: ${team.value['goalsFor']} | عليه: ${team.value['goalsAgainst']}",
                    ),
                    trailing: Text(
                      "ف: ${team.value['wins']} | ت: ${team.value['draws']} | خ: ${team.value['losses']}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              },
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