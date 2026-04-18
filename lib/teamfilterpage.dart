import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeamFilterPage extends StatefulWidget {
  const TeamFilterPage({Key? key}) : super(key: key);

  @override
  _TeamFilterPageState createState() => _TeamFilterPageState();
}

class _TeamFilterPageState extends State<TeamFilterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> matches = [];
  List<Map<String, dynamic>> leagues = [];
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? nextMatch;
  List<Map<String, dynamic>?> formation = List.filled(11, null);
  List<String> selectedPlayers = [];
  String errorMessage = '';
  String selectedFormation = '4-4-2';
  String? teamName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTeamNameAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTeamNameAndData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMessage = 'يجب تسجيل الدخول لعرض البيانات';
      });
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final coachDoc = await firestore.collection('coaches').doc(user.uid).get();

    if (!coachDoc.exists) {
      setState(() {
        errorMessage = 'لم يتم العثور على بيانات المدرب';
      });
      return;
    }

    final coachData = coachDoc.data();
    final fetchedTeamName = coachData?['club'] as String?;

    if (fetchedTeamName == null) {
      setState(() {
        errorMessage = 'لم يتم العثور على فريق مرتبط بالمدرب';
      });
      return;
    }

    setState(() {
      teamName = fetchedTeamName.trim();
      print('Team Name (trimmed): "$teamName"');
    });

    final matchesSnapshot = await firestore.collection('matches').get();
    final matchesData = matchesSnapshot.docs.map((doc) {
      final data = doc.data();
      final matchDate = (data['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      return {
        'id': doc.id,
        ...data,
        'matchDate': matchDate,
        'team1': (data['team1'] as String?)?.trim(),
        'team2': (data['team2'] as String?)?.trim(),
      };
    }).toList();

    for (var match in matchesData) {
      print('Match ID: ${match['id']}, Team1: "${match['team1']}", Team2: "${match['team2']}", Date: ${match['matchDate']}');
    }

    setState(() {
      matches = matchesData
          .where((match) => match['team1'] == teamName || match['team2'] == teamName)
          .toList();
    });

    final leaguesSnapshot = await firestore.collection('leagues').get();
    setState(() {
      leagues = leaguesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });

    final playersSnapshot = await firestore.collection('players').get();
    setState(() {
      players = playersSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((player) => (player['club'] as String?)?.trim() == teamName)
          .toList();
    });

    final today = DateTime.now().toUtc();
    final tomorrow = today.add(const Duration(days: 1));
    final upcomingMatch = matchesData
        .where((match) {
      final matchDate = (match['matchDate'] as DateTime).toUtc();
      final isUpcoming = matchDate.isAfter(today) ||
          (matchDate.year == tomorrow.year &&
              matchDate.month == tomorrow.month &&
              matchDate.day == tomorrow.day);
      final isTeamMatch = match['team1'] == teamName || match['team2'] == teamName;
      print('Match ID: ${match['id']}, IsUpcoming: $isUpcoming, IsTeam: $isTeamMatch, Date: $matchDate');
      return isUpcoming && isTeamMatch;
    })
        .toList()
      ..sort((a, b) => (a['matchDate'] as DateTime).compareTo(b['matchDate'] as DateTime));

    setState(() {
      nextMatch = upcomingMatch.isNotEmpty ? upcomingMatch.first : null;
      if (nextMatch == null) {
        print('No upcoming match found for team: "$teamName"');
      } else {
        print('Next match: ${nextMatch!['id']}, Date: ${nextMatch!['matchDate']}, Team1: "${nextMatch!['team1']}", Team2: "${nextMatch!['team2']}"');
      }
    });
  }

  List<Map<String, dynamic>> getUniqueLeagues() {
    final leagueIds = matches.map((match) => match['leagueId']).toSet().toList();
    return leagues.where((league) => leagueIds.contains(league['id'])).toList();
  }

  void handleDrop(Map<String, dynamic> player, int index) {
    setState(() {
      if (formation[index] != null) {
        selectedPlayers.remove(formation[index]!['id']);
      }
      formation[index] = player;
      selectedPlayers.add(player['id']);
      errorMessage = '';
    });
  }

  Future<void> saveFormation() async {
    if (formation.any((slot) => slot == null)) {
      setState(() {
        errorMessage = 'يجب اختيار 11 لاعبًا لتشكيلة كاملة';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('formations').add({
        'teamName': teamName,
        'formation': formation.map((player) => player!['name']).toList(),
        'formationType': selectedFormation,
        'createdAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التشكيلة بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        formation = List.filled(11, null);
        selectedPlayers.clear();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء حفظ التشكيلة';
      });
    }
  }

  List<Offset> getPlayerPositions(String formationType) {
    switch (formationType) {
      case '4-4-2':
        return [
          const Offset(0.50, 0.05),
          const Offset(0.15, 0.25),
          const Offset(0.35, 0.25),
          const Offset(0.65, 0.25),
          const Offset(0.85, 0.25),
          const Offset(0.15, 0.50),
          const Offset(0.35, 0.50),
          const Offset(0.65, 0.50),
          const Offset(0.85, 0.50),
          const Offset(0.35, 0.80),
          const Offset(0.65, 0.80),
        ];
      case '4-3-3':
        return [
          const Offset(0.50, 0.05),
          const Offset(0.15, 0.25),
          const Offset(0.35, 0.25),
          const Offset(0.65, 0.25),
          const Offset(0.85, 0.25),
          const Offset(0.25, 0.50),
          const Offset(0.50, 0.50),
          const Offset(0.75, 0.50),
          const Offset(0.25, 0.80),
          const Offset(0.50, 0.80),
          const Offset(0.75, 0.80),
        ];
      case '3-5-2':
        return [
          const Offset(0.50, 0.05),
          const Offset(0.25, 0.25),
          const Offset(0.50, 0.25),
          const Offset(0.75, 0.25),
          const Offset(0.15, 0.50),
          const Offset(0.30, 0.50),
          const Offset(0.50, 0.50),
          const Offset(0.70, 0.50),
          const Offset(0.85, 0.50),
          const Offset(0.35, 0.80),
          const Offset(0.65, 0.80),
        ];
      default:
        return List.filled(11, const Offset(0.5, 0.5));
    }
  }

  Widget buildPitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitchWidth = constraints.maxWidth;
        final pitchHeight = 450.0;
        return Container(
          height: pitchHeight,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.green[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white70, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CustomPaint(
              painter: PitchPainter(),
              child: Stack(
                children: List.generate(11, (index) {
                  final position = getPlayerPositions(selectedFormation)[index];
                  return Positioned(
                    left: position.dx * pitchWidth - 30,
                    top: position.dy * pitchHeight - 30,
                    child: DragTarget<Map<String, dynamic>>(
                      onAccept: (player) => handleDrop(player, index),
                      builder: (context, candidateData, rejectedData) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: formation[index] != null
                                ? LinearGradient(
                              colors: [Colors.blue[800]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : LinearGradient(
                              colors: [Colors.white, Colors.grey[200]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white70, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: formation[index] != null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formation[index]!['name'].split(' ').first,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            )
                                : Text(
                              'Slot ${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ).animate().scale(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isNotEmpty && teamName == null) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
        ),
      );
    }

    if (teamName == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[300],
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'نتائج الفريق'),
            Tab(text: 'المباراة القادمة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: getUniqueLeagues().map((league) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league['leagueName'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                    const SizedBox(height: 12),
                    ...matches.where((match) => match['leagueId'] == league['id']).map((match) {
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            '${match['team1']} ${match['goals1']} - ${match['goals2']} ${match['team2']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'الجولة: ${match['roundId']} | ${match['result']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        end: 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المباراة القادمة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                const SizedBox(height: 12),
                nextMatch != null
                    ? Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      '${nextMatch!['team1']} ضد ${nextMatch!['team2']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'التاريخ: ${DateFormat.yMMMd().format(nextMatch!['matchDate'] as DateTime)} ${DateFormat.Hm().format(nextMatch!['matchDate'] as DateTime)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ).animate().slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                )
                    : const Text(
                  'لا توجد مباريات قادمة.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ).animate().fadeIn(),
                const SizedBox(height: 20),
                const Text(
                  'تشكيلة الفريق',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedFormation,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '4-4-2', child: Text('4-4-2')),
                    DropdownMenuItem(value: '4-3-3', child: Text('4-3-3')),
                    DropdownMenuItem(value: '3-5-2', child: Text('3-5-2')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFormation = value!;
                      formation = List.filled(11, null);
                      selectedPlayers.clear();
                    });
                  },
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  dropdownColor: Colors.white,
                  elevation: 5,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                  underline: Container(
                    height: 2,
                    color: Colors.green[700],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                const SizedBox(height: 20),
                buildPitch().animate().fadeIn(duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: players.asMap().entries.where((entry) => !selectedPlayers.contains(entry.value['id'])).map((entry) {
                    final player = entry.value;
                    return Draggable<Map<String, dynamic>>(
                      data: player,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3D6F5D), Color(0xFF4A8C70)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white70, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player['name'].split(' ').first,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '#${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3D6F5D), Color(0xFF4A8C70)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white70, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(2, 2),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                player['name'].split(' ').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '#${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().scale(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ).then().shimmer(
                      duration: const Duration(milliseconds: 800),
                      color: Colors.white.withOpacity(0.3),
                    );
                  }).toList(),
                ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveFormation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: const Text(
                    'حفظ التشكيلة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[900]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), linePaint);

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      linePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - size.width * 0.3, 0, size.width * 0.6, size.height * 0.2),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - size.width * 0.3, size.height - size.height * 0.2, size.width * 0.6, size.height * 0.2),
      linePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - size.width * 0.15, 0, size.width * 0.3, size.height * 0.1),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - size.width * 0.15, size.height - size.height * 0.1, size.width * 0.3, size.height * 0.1),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width / 2 - size.width * 0.15, 0),
      Offset(size.width / 2 + size.width * 0.15, 0),
      linePaint..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(size.width / 2 - size.width * 0.15, size.height),
      Offset(size.width / 2 + size.width * 0.15, size.height),
      linePaint..strokeWidth = 4,
    );

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.15), 3, dotPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height - size.height * 0.15), 3, dotPaint);

    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}