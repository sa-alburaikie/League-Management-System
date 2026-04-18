// صفحة قائمة اللاعبين، تعرض اسم اللاعب والفريق المنضم له
// تحتوي على صفحة PlayersOptionScreen التي تعرض خيارات (بروفايل اللاعب، إحصائيات اللاعب)
// وصفحات فرعية: PlayerProfileDetailsScreen, PlayerStatusDetailsScreen
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayersTeamsListScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getPlayers() async {
    final snapshot = await FirebaseFirestore.instance.collection('players').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name']?.toString() ?? 'لاعب غير معروف',
        'club': data['club']?.toString() ?? 'لا يوجد فريق بعد',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
              'لا يوجد لاعبون في النظام',
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
                    subtitle: Text(
                      'الفريق: ${player['club']}',
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF3D6F5D)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayersOptionScreen(
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
    );
  }
}

class PlayersOptionScreen extends StatelessWidget {
  final String playerId;
  final String playerName;

  PlayersOptionScreen({required this.playerId, required this.playerName});

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'title': 'بروفايل اللاعب',
        'icon': Icons.account_circle,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerProfileDetailsScreen(
                playerId: playerId,
                playerName: playerName,
              ),
            ),
          );
        },
      },
      {
        'title': 'إحصائيات اللاعب',
        'icon': Icons.bar_chart,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerStatusDetailsScreen(
                playerId: playerId,
                playerName: playerName,
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
          'خيارات اللاعب: $playerName',
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

class PlayerProfileDetailsScreen extends StatelessWidget {
  final String playerId;
  final String playerName;

  PlayerProfileDetailsScreen({required this.playerId, required this.playerName});

  Future<Map<String, dynamic>> _getPlayerDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('players').doc(playerId).get();
      final data = doc.data() ?? {};
      return {
        'name': data['name']?.toString() ?? 'لاعب غير معروف',
        'birthDate': data['birthDate']?.toString() ?? 'غير متوفر',
        'club': data['club']?.toString() ?? 'غير منضم لفريق',
        'imageUrl': data['imageUrl']?.toString(),
        'location': data['location']?.toString() ?? 'غير متوفر',
        'nationality': data['nationality']?.toString() ?? 'غير متوفر',
        'number': data['number']?.toString() ?? 'غير متوفر',
        'phone': data['phone']?.toString() ?? 'غير متوفر',
        'position': data['position']?.toString() ?? 'غير متوفر',
      };
    } catch (e) {
      throw Exception('فشل في جلب بيانات اللاعب: $e');
    }
  }

  // دالة لفتح تطبيق الهاتف أو البريد الإلكتروني
  Future<void> _launchUrl(String scheme, String path) async {
    final Uri url = Uri(scheme: scheme, path: path);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'لا يمكن فتح $scheme:$path';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
        title: Text(
          'بروفايل اللاعب: $playerName',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerProfileDetailsScreen(
                  playerId: playerId,
                  playerName: playerName,
                ),
              ),
            ),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getPlayerDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3D6F5D)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حدث خطأ في جلب بيانات اللاعب',
                    style: GoogleFonts.cairo(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileDetailsScreen(
                          playerId: playerId,
                          playerName: playerName,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D6F5D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

          final player = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                      // صورة اللاعب
                      if (player['imageUrl'] != null && player['imageUrl'].isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: player['imageUrl'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3D6F5D),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 100,
                                color: Color(0xFF3D6F5D),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // الاسم
                      ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'الاسم: ${player['name']}',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(),
                      // تاريخ الميلاد
                      ListTile(
                        leading: const Icon(Icons.cake, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'تاريخ الميلاد: ${player['birthDate']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // الفريق
                      ListTile(
                        leading: const Icon(Icons.group, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'الفريق: ${player['club']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // الجنسية
                      ListTile(
                        leading: const Icon(Icons.flag, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'الجنسية: ${player['nationality']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // رقم القميص
                      ListTile(
                        leading: const Icon(Icons.confirmation_number, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'رقم القميص: ${player['number']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // المركز
                      ListTile(
                        leading: const Icon(Icons.sports_soccer, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'المركز: ${player['position']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      // رقم الهاتف
                      ListTile(
                        leading: const Icon(Icons.phone, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'رقم الهاتف: ${player['phone']}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                        trailing: player['phone'] != 'غير متوفر'
                            ? IconButton(
                          icon: const Icon(Icons.call, color: Color(0xFF3D6F5D)),
                          onPressed: () => _launchUrl('tel', player['phone']),
                          tooltip: 'الاتصال',
                        )
                            : null,
                      ),
                      const Divider(),
                      // الموقع
                      ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFF3D6F5D)),
                        title: Text(
                          'الموقع: ${player['location']}',
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

class PlayerStatusDetailsScreen extends StatelessWidget {
  final String playerId;
  final String playerName;

  PlayerStatusDetailsScreen({required this.playerId, required this.playerName});

  Future<Map<String, dynamic>> _getPlayerStats() async {
    // جلب الفريق الخاص باللاعب
    final playerDoc = await FirebaseFirestore.instance.collection('players').doc(playerId).get();
    final playerData = playerDoc.data() ?? {};
    final club = playerData['club']?.toString() ?? '';

    // جلب الدوريات التي يشارك فيها الفريق
    final leaguesSnapshot = await FirebaseFirestore.instance
        .collection('leagues')
        .where('selectedTeams', arrayContains: club)
        .get();
    final leagueIds = leaguesSnapshot.docs.map((doc) => doc.id).toList();
    final leagues = leaguesSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['leagueName']?.toString() ?? 'دوري غير معروف',
      };
    }).toList();

    // جلب عدد المباريات
    int matchCount = 0;
    for (var leagueId in leagueIds) {
      final matchesSnapshot1 = await FirebaseFirestore.instance
          .collection('matches')
          .where('leagueId', isEqualTo: leagueId)
          .where('team1', isEqualTo: club)
          .get();
      final matchesSnapshot2 = await FirebaseFirestore.instance
          .collection('matches')
          .where('leagueId', isEqualTo: leagueId)
          .where('team2', isEqualTo: club)
          .get();
      matchCount += matchesSnapshot1.docs.length + matchesSnapshot2.docs.length;
    }

    // جلب الأهداف
    final goalsSnapshot = await FirebaseFirestore.instance
        .collection('goals')
        .where('playerId', isEqualTo: playerId)
        .get();
    final goals = goalsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'matchId': data['matchId']?.toString() ?? '',
        'team': data['team']?.toString() ?? 'غير معروف',
        'minute': data['minute']?.toInt() ?? 0,
        'opponent': '',
      };
    }).toList();

    // جلب اسم الفريق المنافس لكل هدف
    for (var goal in goals) {
      final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(goal['matchId']).get();
      final matchData = matchDoc.data() ?? {};
      final team1 = matchData['team1']?.toString() ?? 'غير معروف';
      final team2 = matchData['team2']?.toString() ?? 'غير معروف';
      goal['opponent'] = goal['team'] == team1 ? team2 : team1;
    }

    // جلب جوائز أفضل لاعب
    final bestPlayerAwards = <Map<String, dynamic>>[];
    for (var leagueId in leagueIds) {
      final statusDoc = await FirebaseFirestore.instance.collection('leaguestatus').doc(leagueId).get();
      final statusData = statusDoc.data() ?? {};
      if (statusData['bestPlayer'] == playerName) {
        bestPlayerAwards.add({
          'type': 'أفضل لاعب في الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
      if (statusData['bestDefender'] == playerName) {
        bestPlayerAwards.add({
          'type': 'أفضل مدافع في الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
      if (statusData['bestForward'] == playerName) {
        bestPlayerAwards.add({
          'type': 'أفضل مهاجم في الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
      if (statusData['bestGoalkeeper'] == playerName) {
        bestPlayerAwards.add({
          'type': 'أفضل حارس في الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
      if (statusData['bestMidfielder'] == playerName) {
        bestPlayerAwards.add({
          'type': 'أفضل وسط في الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
      if (statusData['topScorer'] == playerName) {
        bestPlayerAwards.add({
          'type': 'هداف الدوري',
          'league': leagues.firstWhere((l) => l['id'] == leagueId)['name'],
        });
      }
    }

    // جلب جوائز أفضل لاعب في المباريات
    final matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('bestPlayer', isEqualTo: playerId)
        .get();
    for (var match in matchesSnapshot.docs) {
      final data = match.data();
      final leagueId = data['leagueId']?.toString() ?? '';
      final leagueName = leagues.firstWhere(
            (l) => l['id'] == leagueId,
        orElse: () => {'name': 'دوري غير معروف'},
      )['name'];
      bestPlayerAwards.add({
        'type': 'أفضل لاعب في المباراة',
        'league': leagueName,
        'match': '${data['team1']} ضد ${data['team2']}',
      });
    }

    return {
      'leagues': leagues,
      'matchCount': matchCount,
      'goalCount': goals.length,
      'goals': goals,
      'bestPlayerAwards': bestPlayerAwards,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        title: Text(
          'إحصائيات: $playerName',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getPlayerStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في جلب الإحصائيات',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            );
          }
          final stats = snapshot.data ?? {};
          final leagues = stats['leagues'] as List<dynamic>? ?? [];
          final matchCount = stats['matchCount'] as int? ?? 0;
          final goalCount = stats['goalCount'] as int? ?? 0;
          final goals = stats['goals'] as List<dynamic>? ?? [];
          final bestPlayerAwards = stats['bestPlayerAwards'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
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
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الإحصائيات العامة',
                            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'عدد الدوريات: ${leagues.length}',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'عدد المباريات: $matchCount',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'عدد الأهداف: $goalCount',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                FadeInUp(
                  child: Text(
                    'الدوريات المشارك فيها:',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (leagues.isEmpty)
                  FadeInUp(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد دوريات مشارك فيها',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                    ),
                  )
                else
                  ...leagues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final league = entry.value;
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 * (index + 1)),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            league['name'],
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                SizedBox(height: 16),
                FadeInUp(
                  child: Text(
                    'الأهداف المسجلة:',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (goals.isEmpty)
                  FadeInUp(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد أهداف مسجلة',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                    ),
                  )
                else
                  ...goals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final goal = entry.value;
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 * (index + 1)),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.sports_soccer, color: Color(0xFF3D6F5D)),
                          title: Text(
                            'ضد: ${goal['opponent']}',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                          subtitle: Text(
                            'الدقيقة: ${goal['minute']}',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                SizedBox(height: 16),
                FadeInUp(
                  child: Text(
                    'جوائز أفضل لاعب:',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (bestPlayerAwards.isEmpty)
                  FadeInUp(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد جوائز أفضل لاعب',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      ),
                    ),
                  )
                else
                  ...bestPlayerAwards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final award = entry.value;
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 * (index + 1)),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.star, color: Color(0xFF3D6F5D)),
                          title: Text(
                            award['type'],
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                          subtitle: Text(
                            'الدوري: ${award['league']}${award['match'] != null ? '\nالمباراة: ${award['match']}' : ''}',
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}