import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MatchesPage extends StatefulWidget {
  @override
  _MatchesPageState createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isEditing = false;
  Map<String, String> leagueNames = {};
  Map<String, String> teamNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaguesAndTeams();
  }

  Future<void> _fetchLeaguesAndTeams() async {
    try {
      QuerySnapshot leaguesSnapshot = await FirebaseFirestore.instance.collection('leagues').get();
      for (var doc in leaguesSnapshot.docs) {
        leagueNames[doc.id] = doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('leagueName')
            ? (doc.data() as Map<String, dynamic>)['leagueName']?.toString() ?? 'دوري غير معروف'
            : 'دوري غير معروف';
      }
      QuerySnapshot teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
      for (var doc in teamsSnapshot.docs) {
        teamNames[doc.id] = doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('teamname')
            ? (doc.data() as Map<String, dynamic>)['teamname']?.toString() ?? 'فريق غير معروف'
            : 'فريق غير معروف';
      }
      setState(() {});
    } catch (e) {
      print('Error fetching leagues and teams: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب بيانات الدوريات والفرق', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 0,
        title: Text(
          'المباريات',
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'اليوم'),
            Tab(text: 'الأمس'),
            Tab(text: 'الغد'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MatchesTab(dayOffset: 0, isEditing: isEditing, leagueNames: leagueNames, teamNames: teamNames),
          MatchesTab(dayOffset: -1, isEditing: isEditing, leagueNames: leagueNames, teamNames: teamNames),
          MatchesTab(dayOffset: 1, isEditing: isEditing, leagueNames: leagueNames, teamNames: teamNames),
        ],
      ),
    );
  }
}

class MatchesTab extends StatelessWidget {
  final int dayOffset;
  final bool isEditing;
  final Map<String, String> leagueNames;
  final Map<String, String> teamNames;

  MatchesTab({required this.dayOffset, required this.isEditing, required this.leagueNames, required this.teamNames});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime targetDate = DateTime.utc(now.year, now.month, now.day + dayOffset);
    Timestamp startOfDay = Timestamp.fromDate(targetDate);
    Timestamp endOfDay = Timestamp.fromDate(targetDate.add(Duration(days: 1)));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('matchDate', isGreaterThanOrEqualTo: startOfDay)
          .where('matchDate', isLessThan: endOfDay)
          .orderBy('matchDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', style: GoogleFonts.cairo()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لا توجد مباريات', style: GoogleFonts.cairo(fontSize: 18)));
        }

        Map<String, List<DocumentSnapshot>> groupedMatches = {};
        for (var doc in snapshot.data!.docs) {
          String leagueId = doc['leagueId']?.toString() ?? 'unknown';
          if (!groupedMatches.containsKey(leagueId)) {
            groupedMatches[leagueId] = [];
          }
          groupedMatches[leagueId]!.add(doc);
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: groupedMatches.length,
          itemBuilder: (context, index) {
            String leagueId = groupedMatches.keys.elementAt(index);
            String leagueName = leagueNames[leagueId] ?? 'دوري غير معروف';
            List<DocumentSnapshot> matches = groupedMatches[leagueId]!;

            return FadeInUp(
              duration: Duration(milliseconds: 300 * index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      leagueName,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...matches.asMap().entries.map((entry) {
                    int matchIndex = entry.key;
                    DocumentSnapshot matchDoc = entry.value;
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 * (index + matchIndex + 1)),
                      child: MatchItem(
                        matchDoc: matchDoc,
                        isEditing: isEditing,
                        teamNames: teamNames,
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MatchItem extends StatelessWidget {
  final DocumentSnapshot matchDoc;
  final bool isEditing;
  final Map<String, String> teamNames;

  MatchItem({required this.matchDoc, required this.isEditing, required this.teamNames});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = matchDoc.data() as Map<String, dynamic>;
    String team1Name = data['team1']?.toString() ?? 'فريق غير معروف';
    String team2Name = data['team2']?.toString() ?? 'فريق غير معروف';
    bool isFinished = data['isFinished'] ?? false;
    String result = data['result']?.toString() ?? '0-0';
    Timestamp matchDate = data['matchDate'];
    DateTime dateTime = matchDate.toDate();
    String time = DateFormat.jm('ar').format(dateTime);

    bool isLive = !isFinished &&
        dateTime.isBefore(DateTime.now().add(Duration(minutes: 120))) &&
        dateTime.isAfter(DateTime.now().subtract(Duration(minutes: 120)));

    return GestureDetector(
        onTap: isEditing
        ? () => showDialog(
          context: context,
          builder: (context) => EditMatchDialog(matchDoc: matchDoc),
        )
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailsPage(matchId: matchDoc.id),
            ),
          );
        },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team1Name,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.sports_soccer, color: Colors.grey[600], size: 30),
                  ],
                ),
              ),
              Column(
                children: [
                  if (isLive)
                    Chip(
                      label: Text('مباشر', style: GoogleFonts.cairo(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  Text(
                    isFinished ? result : time,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isLive ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team2Name,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.sports_soccer, color: Colors.grey[600], size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditMatchDialog extends StatefulWidget {
  final DocumentSnapshot matchDoc;

  EditMatchDialog({required this.matchDoc});

  @override
  _EditMatchDialogState createState() => _EditMatchDialogState();
}

class _EditMatchDialogState extends State<EditMatchDialog> {
  late DateTime selectedDateTime;
  late TextEditingController resultController;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> data = widget.matchDoc.data() as Map<String, dynamic>;
    selectedDateTime = (data['matchDate'] as Timestamp).toDate();
    resultController = TextEditingController(text: data['result']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تعديل المباراة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
        ListTile(
        title: Text('تاريخ ووقت المباراة', style: GoogleFonts.cairo()),
        subtitle: Text(
        DateFormat.yMd('ar').add_jm().format(selectedDateTime),
          style: GoogleFonts.cairo(),
        ),
          trailing: Icon(Icons.calendar_today, color: Color(0xFF3D6F5D)),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDateTime,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              locale: Locale('ar'),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
              );
              if (pickedTime != null) {
                setState(() {
                  selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            }
          },
        ),
              TextField(
                controller: resultController,
                decoration: InputDecoration(
                  labelText: 'النتيجة (مثال: 2-1)',
                  labelStyle: GoogleFonts.cairo(),
                ),
              ),
            ],
        ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        TextButton(
          onPressed: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('matches')
                  .doc(widget.matchDoc.id)
                  .update({
                'matchDate': Timestamp.fromDate(selectedDateTime),
                'result': resultController.text,
                'isFinished': resultController.text.isNotEmpty,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تحديث المباراة بنجاح', style: GoogleFonts.cairo())),
              );
            } catch (e) {
              print('Error updating match: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('فشل في تحديث المباراة', style: GoogleFonts.cairo())),
              );
            }
          },
          child: Text('حفظ', style: GoogleFonts.cairo()),
        ),
      ],
    );
  }
}

class MatchDetailsPage extends StatefulWidget {
  final String matchId;

  MatchDetailsPage({required this.matchId});

  @override
  _MatchDetailsPageState createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  bool isEditing = false;
  Map<String, dynamic>? matchData;
  List<Map<String, dynamic>> goals = [];
  List<Map<String, String>> players = [];
  String? selectedBestPlayerId;
  String? selectedBestPlayerTeam;
  TextEditingController team1PossessionController = TextEditingController();
  TextEditingController team2PossessionController = TextEditingController();
  Map<String, String> teamNames = {};
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMatchData();
  }

  Future<void> _fetchMatchData() async {
    try {
      setState(() {
        hasError = false;
      });
      DocumentSnapshot matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();
      if (matchDoc.exists) {
        setState(() {
          matchData = matchDoc.data() as Map<String, dynamic>;
          selectedBestPlayerId = matchData!['bestPlayer'];
        });
        String team1 = matchData!['team1']?.toString() ?? 'فريق غير معروف';
        String team2 = matchData!['team2']?.toString() ?? 'فريق غير معروف';
        teamNames[team1] = team1;
        teamNames[team2] = team2;
        team1PossessionController.text = (matchData!['team1Possession'] ?? 0).toString();
        team2PossessionController.text = (matchData!['team2Possession'] ?? 0).toString();
        QuerySnapshot goalsSnapshot = await FirebaseFirestore.instance
            .collection('goals')
            .where('matchId', isEqualTo: widget.matchId)
            .get();
        setState(() {
          goals = goalsSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
        List<String> teamNamesList = [team1, team2].where((name) => name.isNotEmpty).toList();
        if (teamNamesList.isNotEmpty) {
          QuerySnapshot playersSnapshot = await FirebaseFirestore.instance
              .collection('players')
              .where('club', whereIn: teamNamesList)
              .get();
          setState(() {
            players = playersSnapshot.docs
                .map((doc) => {
              'id': doc.id,
              'name': doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('name')
                  ? (doc.data() as Map<String, dynamic>)['name']?.toString() ?? 'غير معروف'
                  : 'غير معروف',
              'club': doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('club')
                  ? (doc.data() as Map<String, dynamic>)['club']?.toString() ?? 'غير معروف'
                  : 'غير معروف',
            })
                .toList()
                .cast<Map<String, String>>();
          });
          if (selectedBestPlayerId != null) {
            selectedBestPlayerTeam = players
                .firstWhere(
                  (p) => p['id'] == selectedBestPlayerId,
              orElse: () => {'club': 'غير معروف'},
            )['club'];
          }
          print('Fetched players: $players');
        } else {
          print('No valid team names for players query');
        }
      } else {
        setState(() {
          hasError = true;
        });
        print('Match document does not exist');
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print('Error fetching match data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب بيانات المباراة: $e', style: GoogleFonts.cairo())),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      int team1Possession = int.tryParse(team1PossessionController.text) ?? 0;
      int team2Possession = int.tryParse(team2PossessionController.text) ?? 0;
      if (team1Possession + team2Possession > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('مجموع الاستحواذ لا يمكن أن يتجاوز 100%', style: GoogleFonts.cairo())),
        );
        return;
      }
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'bestPlayer': selectedBestPlayerId,
        'team1Possession': team1Possession,
        'team2Possession': team2Possession,
      });
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo())),
      );
    } catch (e) {
      print('Error saving changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حفظ التغييرات', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
        children: [
        Container(
        decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
          'https://images.unsplash.com/photo-1558647524-83c7f7b0d7c8?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
        ),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
    ),
    ),
    ),
    if (matchData == null && !hasError)
    Container(
    color: Colors.black.withOpacity(0.5),
    child: Center(
    child: Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    CircularProgressIndicator(color: Color(0xFF3D6F5D)),
    SizedBox(height: 16),
    Text(
    'جارٍ جلب بيانات المباراة...',
    style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
    ),
    ],
    ),
    ),
    ),
    ),
    )
    else if (hasError)
    Container(
    color: Colors.black.withOpacity(0.5),
    child: Center(
    child: Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.error_outline, color: Colors.red, size: 48),
    SizedBox(height: 16),
    Text(
    'فشل في جلب بيانات المباراة',
    style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
    ),
    SizedBox(height: 16),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF3D6F5D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    onPressed: _fetchMatchData,
    child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
    ),
    ],
    ),
    ),
    ),
    ),
    )
    else
    CustomScrollView(
    slivers: [
    SliverAppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    pinned: true,
    flexibleSpace: FlexibleSpaceBar(
    title: Text(
    '${matchData!['team1']?.toString() ?? 'فريق غير معروف'} ضد ${matchData!['team2']?.toString() ?? 'فريق غير معروف'}',
    style: GoogleFonts.cairo(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    background: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Color(0xFF3D6F5D).withOpacity(0.8), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    ),
    ),
    ),
    ),
    actions: [
    IconButton(
    icon: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white),
    onPressed: () {
    if (isEditing) {
    _saveChanges();
    } else {
    setState(() {
    isEditing = true;
    });
    }
    },
    ),
    ],
    ),
    SliverToBoxAdapter(
    child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Hero(
    tag: 'match_${widget.matchId}',
    child: Card(
    elevation: 10,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: Colors.white.withOpacity(0.9),
    ),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: Column(
    children: [
    Icon(Icons.sports_soccer, size: 50, color: Color(0xFF3D6F5D)),
    SizedBox(height: 8),
    Text(
    matchData!['team1']?.toString() ?? 'فريق غير معروف',
    style: GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    ),
    Column(
    children: [
    if (!(matchData!['isFinished'] ?? false) &&
    matchData!['matchDate'].toDate().isBefore(DateTime.now().add(Duration(minutes: 120))) &&
    matchData!['matchDate'].toDate().isAfter(DateTime.now().subtract(Duration(minutes: 120))))
    Chip(
    label: Text('مباشر', style: GoogleFonts.cairo(color: Colors.white)),
    backgroundColor: Colors.red,
    elevation: 4,
    ),
    Text(
    (matchData!['isFinished'] ?? false) && matchData!['result']?.toString().isNotEmpty == true
    ? matchData!['result']?.toString() ?? '0-0'
        : DateFormat.jm('ar').format(matchData!['matchDate'].toDate()),
    style: GoogleFonts.cairo(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: (!(matchData!['isFinished'] ?? false) &&
    matchData!['matchDate'].toDate().isBefore(DateTime.now().add(Duration(minutes: 120))) &&
    matchData!['matchDate'].toDate().isAfter(DateTime.now().subtract(Duration(minutes: 120))))
    ? Colors.red
        : Colors.black87,
    ),
    ),
    ],
    ),
    Expanded(
    child: Column(
    children: [
    Icon(Icons.sports_soccer, size: 50, color: Color(0xFF3D6F5D)),
    SizedBox(height: 8),
    Text(
    matchData!['team2']?.toString() ?? 'فريق غير معروف',
    style: GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    ),
    ),
    SizedBox(height: 24),
    FadeInUp(
    child: Row(
    children: [
    Icon(Icons.calendar_today, color: Colors.white),
    SizedBox(width: 8),
    Text(
    'التاريخ: ${DateFormat.yMd('ar').format(matchData!['matchDate'].toDate())}',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
    ),
    ],
    ),
    ),
    SizedBox(height: 24),
    FadeInUp(
    child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: Colors.black26,
    blurRadius: 4,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Text(
    'أفضل لاعب في المباراة',
    style: GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    ),
    ),
    ),
    SizedBox(height: 8),
    FadeInUp(
    child: isEditing
    ? Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: DropdownButtonFormField<String>(
    value: selectedBestPlayerId,
    hint: Text('اختر أفضل لاعب', style: GoogleFonts.cairo()),
    isExpanded: true,
    decoration: InputDecoration(
    border: InputBorder.none,
    ),
    items: players
        .map((player) => DropdownMenuItem<String>(
    value: player['id'],
    child: Text('${player['name']} (${player['club']})', style: GoogleFonts.cairo()),
    ))
        .toList(),
    onChanged: (String? newValue) {
    setState(() {
    selectedBestPlayerId = newValue;
    selectedBestPlayerTeam = newValue != null
    ? players.firstWhere((p) => p['id'] == newValue)['club']
        : null;
    });
    },
    dropdownColor: Colors.white,
    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3D6F5D)),
    ),
    ),
    )
        : Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: EdgeInsets.all(12),
    child: Text(
    selectedBestPlayerId != null
    ? '${players.firstWhere(
    (p) => p['id'] == selectedBestPlayerId,
    orElse: () => {'name': 'لم يتم التحديد', 'club': ''},
    )['name']} (${selectedBestPlayerTeam ?? 'غير معروف'})'
        : 'لم يتم التحديد',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    ),
    ),
    ),
    SizedBox(height: 24),
    FadeInUp(
    child: Row(
    children: [
    Icon(Icons.pie_chart, color: Colors.white),
    SizedBox(width: 8),
    Text(
    'الاستحواذ:',
    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    ],
    ),
    ),
    SizedBox(height: 8),
    FadeInUp(
    child: isEditing
    ? Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: EdgeInsets.all(12),
    child: Column(
    children: [
    TextField(
    controller: team1PossessionController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
    labelText: '${matchData!['team1']?.toString() ?? 'فريق غير معروف'} (%)',
    labelStyle: GoogleFonts.cairo(),
    border: OutlineInputBorder(),
    ),
    ),
    SizedBox(height: 8),
    TextField(
    controller: team2PossessionController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
    labelText: '${matchData!['team2']?.toString() ?? 'فريق غير معروف'} (%)',
    labelStyle: GoogleFonts.cairo(),
    border: OutlineInputBorder(),
    ),
    ),
    ],
    ),
    ),
    )
        : Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: EdgeInsets.all(12),
    child: Column(
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(
    matchData!['team1']?.toString() ?? 'فريق غير معروف',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    Text(
    '${team1PossessionController.text}%',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    ],
    ),
    SizedBox(height: 4),
    LinearProgressIndicator(
    value: (int.tryParse(team1PossessionController.text) ?? 0) / 100,
    backgroundColor: Colors.grey[300],
    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D6F5D)),
    minHeight: 10,
    borderRadius: BorderRadius.circular(5),
    ),
    SizedBox(height: 8),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(
    matchData!['team2']?.toString() ?? 'فريق غير معروف',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    Text(
    '${team2PossessionController.text}%',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    ],
    ),
    SizedBox(height: 4),
    LinearProgressIndicator(
    value: (int.tryParse(team2PossessionController.text) ?? 0) / 100,
    backgroundColor: Colors.grey[300],
    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
    minHeight: 10,
    borderRadius: BorderRadius.circular(5),
    ),
    ],
    ),
    ),
    ),
    ),
    SizedBox(height: 24),
    FadeInUp(
    child: Row(
    children: [
    Icon(Icons.sports_soccer, color: Colors.white),
    SizedBox(width: 8),
    Text(
    'الأهداف:',
    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    ],
    ),
    ),
    SizedBox(height: 8),
    goals.isEmpty
    ? FadeInUp(
    child: Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: EdgeInsets.all(12),
    child: Text(
    'لا توجد أهداف',
    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
    ),
    ),
    ),
    )
        : Column(
    children: goals.asMap().entries.map((entry) {
    int index = entry.key;
    Map<String, dynamic> goal = entry.value;
    String playerName = players.firstWhere(
    (p) => p['id'] == goal['playerId'],
    orElse: () => {'id': '', 'name': 'غير معروف', 'club': 'غير معروف'},
    )['name'] ?? 'غير معروف';
    String teamName = goal['team']?.toString() ?? 'غير معروف';
    bool isTeam1 = teamName == matchData!['team1']?.toString();
    return SlideInRight(
      duration: Duration(milliseconds: 300 * (index + 1)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isTeam1 ? Colors.green[50] : Colors.red[50],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isTeam1 ? Color(0xFF3D6F5D) : Colors.red,
            child: Icon(Icons.sports_soccer, color: Colors.white, size: 20),
          ),
          title: Text(
            '$playerName ($teamName)',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'الدقيقة ${goal['minute']}',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black54),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
        ),
      ),
    );
    }).toList(),
    ),
      SizedBox(height: 80),
    ],
    ),
    ),
    ),
    ],
    ),
        ],
        ),
      floatingActionButton: isEditing
          ? ZoomIn(
        child: FloatingActionButton(
          backgroundColor: Color(0xFF3D6F5D),
          child: Icon(Icons.add, size: 30),
          onPressed: () {
            if (players.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('لا يوجد لاعبون متاحون لإضافة هدف', style: GoogleFonts.cairo())),
              );
              return;
            }
            showDialog(
              context: context,
              builder: (context) => AddGoalDialog(
                players: players,
                matchId: widget.matchId,
                leagueId: matchData!['leagueId'],
                team1: matchData!['team1']?.toString() ?? 'فريق غير معروف',
                team2: matchData!['team2']?.toString() ?? 'فريق غير معروف',
              ),
            );
          },
        ),
      )
          : null,
    );
  }
}

class AddGoalDialog extends StatefulWidget {
  final List<Map<String, String>> players;
  final String matchId;
  final String leagueId;
  final String team1;
  final String team2;

  AddGoalDialog({
    required this.players,
    required this.matchId,
    required this.leagueId,
    required this.team1,
    required this.team2,
  });

  @override
  _AddGoalDialogState createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  String? selectedTeam;
  String? selectedPlayerId;
  TextEditingController minuteController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredPlayers = selectedTeam != null
        ? widget.players.where((player) => player['club'] == selectedTeam).toList()
        : widget.players;

    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('إضافة هدف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedTeam,
                hint: Text('اختر الفريق', style: GoogleFonts.cairo()),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [widget.team1, widget.team2]
                    .map((team) => DropdownMenuItem<String>(
                  value: team,
                  child: Text(team, style: GoogleFonts.cairo()),
                ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTeam = newValue;
                    selectedPlayerId = null; // إعادة تعيين اللاعب عند تغيير الفريق
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3D6F5D)),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlayerId,
                hint: Text('اختر اللاعب', style: GoogleFonts.cairo()),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: filteredPlayers
                    .map((player) => DropdownMenuItem<String>(
                  value: player['id'],
                  child: Text(player['name']!, style: GoogleFonts.cairo()),
                ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPlayerId = newValue;
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3D6F5D)),
              ),
              SizedBox(height: 16),
              TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الدقيقة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
        TextButton(
        onPressed: () => Navigator.pop(context),
    child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
    ),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF3D6F5D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    onPressed: () async {
    if (selectedTeam != null && selectedPlayerId != null && minuteController.text.isNotEmpty) {
    try {
    await FirebaseFirestore.instance.collection('goals').add({
    'minute': int.parse(minuteController.text),
      'playerId': selectedPlayerId,
      'team': selectedTeam,
      'leagueId': widget.leagueId,
      'matchId': widget.matchId,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إضافة الهدف بنجاح', style: GoogleFonts.cairo())),
    );
    } catch (e) {
      print('Error adding goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة الهدف', style: GoogleFonts.cairo())),
      );
    }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار فريق، لاعب، وإدخال الدقيقة', style: GoogleFonts.cairo())),
      );
    }
    },
      child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white)),
    ),
        ],
    );
  }
}