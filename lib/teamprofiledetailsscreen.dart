// صفحة قائمة الفرق، تعرض الفرق مع اسمها وعدد اللاعبين
// تحتوي على صفحة TeamOptions التي تعرض خيارات (بروفايل الفريق، اللاعبين، الدوريات)
// وصفحات فرعية: TeamProfileDetailsScreen, JoinedPlayers, JoinedLeagues, ResultsInLeague
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hadramootleagues/playerprofiledetailsscreen.dart';
import 'package:intl/intl.dart';

import 'matchesdisplayscreen.dart';

class TeamsListScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getTeams() async {
    final snapshot = await FirebaseFirestore.instance.collection('teams').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['teamname']?.toString() ?? 'فريق غير معروف',
        'playernumber': data['playernumber']?.toString() ?? "0",
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ في جلب الفرق',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
          );
        }
        final teams = snapshot.data ?? [];
        if (teams.isEmpty) {
          return Center(
            child: Text(
              'لا توجد فرق في النظام',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 * index),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.symmetric(vertical: 8),
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
                    leading: Icon(Icons.group, size: 30, color: Color(0xFF3D6F5D)),
                    title: Text(
                      team['name'],
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'عدد اللاعبين: ${team['playernumber']}',
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF3D6F5D)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamOptions(
                            teamId: team['id'],
                            teamName: team['name'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TeamOptions extends StatelessWidget {
  final String teamId;
  final String teamName;

  TeamOptions({required this.teamId, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'title': 'بروفايل الفريق',
        'icon': Icons.account_circle,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamProfileDetailsScreen(
                teamId: teamId,
                teamName: teamName,
              ),
            ),
          );
        },
      },
      {
        'title': 'اللاعبين',
        'icon': Icons.group,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JoinedPlayers(
                teamId: teamId,
                teamName: teamName,
              ),
            ),
          );
        },
      },
      {
        'title': 'الدوريات',
        'icon': Icons.emoji_events,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JoinedLeagues(
                teamId: teamId,
                teamName: teamName,
              ),
            ),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          'خيارات الفريق: $teamName',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 * index),
              child: GestureDetector(
                onTap: option['onTap'] as VoidCallback,
                child: Card(
                  elevation: 6,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 50,
                          color: Color(0xFF3D6F5D),
                        ),
                        SizedBox(height: 8),
                        Text(
                          option['title'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D6F5D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TeamProfileDetailsScreen extends StatelessWidget {
  final String teamId;
  final String teamName;

  TeamProfileDetailsScreen({required this.teamId, required this.teamName});

  Future<Map<String, dynamic>> _getTeamDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
      final data = doc.data() ?? {};
      return {
        'teamname': data['teamname']?.toString() ?? 'فريق غير معروف',
        'date': data['date']?.toString() ?? 'غير متوفر',
        'email': data['email']?.toString() ?? 'غير متوفر',
        'imageUrl': data['imageUrl']?.toString(),
        'location': data['location']?.toString() ?? 'غير متوفر',
        'maincolor': data['maincolor']?.toString() ?? 'غير متوفر',
        'phone': data['phone']?.toString() ?? 'غير متوفر',
        'playernumber': data['playernumber']?.toString() ?? 'غير متوفر',
      };
    } catch (e) {
      throw Exception('فشل في جلب بيانات الفريق: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
        title: Text(
          'بروفايل الفريق: $teamName',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeamProfileDetailsScreen(teamId: teamId, teamName: teamName),
              ),
            ),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getTeamDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حدث خطأ في جلب بيانات الفريق',
                    style: GoogleFonts.cairo(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamProfileDetailsScreen(teamId: teamId, teamName: teamName),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D6F5D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'إعادة المحاولة',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'لا توجد بيانات متاحة',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }

          final team = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صورة الفريق
                      if (team['imageUrl'] != null && team['imageUrl'].isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: team['imageUrl'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: Color(0xFF3D6F5D)),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.group,
                                size: 100,
                                color: Color(0xFF3D6F5D),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // اسم الفريق
                      ListTile(
                        leading: const Icon(Icons.group, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'اسم الفريق: ${team['teamname']}',
                          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),
                      // سنة التأسيس
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'سنة التأسيس: ${team['date']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // البريد الإلكتروني
                      ListTile(
                        leading: const Icon(Icons.email, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'البريد الإلكتروني: ${team['email']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // الموقع
                      ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'الموقع: ${team['location']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // اللون الرئيسي
                      ListTile(
                        leading: const Icon(Icons.color_lens, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'اللون الرئيسي: ${team['maincolor']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // رقم الهاتف
                      ListTile(
                        leading: const Icon(Icons.phone, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'رقم الهاتف: ${team['phone']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // عدد اللاعبين
                      ListTile(
                        leading: const Icon(Icons.people, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'عدد اللاعبين: ${team['playernumber']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class JoinedPlayers extends StatelessWidget {
  final String teamId;
  final String teamName;

  JoinedPlayers({required this.teamId, required this.teamName});

  Future<List<Map<String, dynamic>>> _getPlayers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('players')
        .where('club', isEqualTo: teamName)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name']?.toString() ?? 'لاعب غير معروف',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          'لاعبو الفريق: $teamName',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getPlayers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في جلب اللاعبين',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          final players = snapshot.data ?? [];
          if (players.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد لاعبون في هذا الفريق',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return FadeInUp(
                duration: Duration(milliseconds: 300 * index),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(vertical: 8),
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
                      leading: Icon(Icons.person, size: 30, color: Color(0xFF3D6F5D)),
                      title: Text(
                        player['name'],
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF3D6F5D)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerProfileDetailsScreen(
                              playerId: player['id'],
                              playerName: player['name'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class JoinedLeagues extends StatelessWidget {
  final String teamId;
  final String teamName;

  JoinedLeagues({required this.teamId, required this.teamName});

  Future<List<Map<String, dynamic>>> _getLeagues() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('leagues')
        .where('selectedTeams', arrayContains: teamName)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['leagueName']?.toString() ?? 'دوري غير معروف',
        'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          'الدوريات: $teamName',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLeagues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في جلب الدوريات',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          final leagues = snapshot.data ?? [];
          if (leagues.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد دوريات لهذا الفريق',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              final endDate = league['endDate'] as DateTime;
              final isFinished = endDate.isBefore(DateTime.now());
              final leagueStatus = isFinished ? 'مكتمل' : 'جاري';
              return FadeInUp(
                duration: Duration(milliseconds: 300 * index),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(vertical: 8),
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
                      leading: Icon(Icons.emoji_events, size: 30, color: Color(0xFF3D6F5D)),
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
                            builder: (context) => ResultsInLeague(
                              teamName: teamName,
                              leagueId: league['id'],
                              leagueName: league['name'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ResultsInLeague extends StatelessWidget {
  final String teamName;
  final String leagueId;
  final String leagueName;

  ResultsInLeague({
    required this.teamName,
    required this.leagueId,
    required this.leagueName,
  });

  Future<List<Map<String, dynamic>>> _getMatches() async {
    final snapshot1 = await FirebaseFirestore.instance
        .collection('matches')
        .where('leagueId', isEqualTo: leagueId)
        .where('team1', isEqualTo: teamName)
        .get();
    final snapshot2 = await FirebaseFirestore.instance
        .collection('matches')
        .where('leagueId', isEqualTo: leagueId)
        .where('team2', isEqualTo: teamName)
        .get();
    final matches = [...snapshot1.docs, ...snapshot2.docs];
    return matches.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'team1': data['team1']?.toString() ?? 'فريق غير معروف',
        'team2': data['team2']?.toString() ?? 'فريق غير معروف',
        'result': data['result']?.toString() ?? 'لم يحدد',
        'matchDate': (data['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'isFinished': data['isFinished'] ?? false,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          'نتائج: $teamName في $leagueName',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في جلب المباريات',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return Center(
              child: Text(
                'لا توجد مباريات لهذا الفريق في هذا الدوري',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return FadeInUp(
                duration: Duration(milliseconds: 300 * index),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(vertical: 8),
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
                      title: Text(
                        '${match['team1']} ضد ${match['team2']}',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التاريخ: ${DateFormat.yMd('ar').format(match['matchDate'])}',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                          Text(
                            'النتيجة: ${match['isFinished'] ? match['result'] : 'لم تنته بعد'}',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF3D6F5D)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchDetailsPageScreen(matchId: match['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}