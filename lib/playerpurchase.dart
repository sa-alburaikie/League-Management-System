import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerPurchase extends StatefulWidget {
  final String teamId; // معرف الفريق الحالي

  PlayerPurchase({required this.teamId});

  @override
  State<PlayerPurchase> createState() => _PlayerPurchaseState();
}

class _PlayerPurchaseState extends State<PlayerPurchase> {
  String? teamName; // اسم الفريق الحالي
  bool isLoading = true; // حالة التحميل
  List<Map<String, String>> teams = []; // قائمة الفرق
  List<Map<String, String>> players = []; // قائمة اللاعبين
  String? selectedTeamId; // معرف الفريق المختار
  String? selectedPlayerId; // معرف اللاعب المختار

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  // جلب بيانات الفرق
  Future<void> _fetchTeams() async {
    try {
      // جلب اسم الفريق الحالي
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        teamName = teamDoc['teamname']?.toString();
      }

      // جلب جميع الفرق باستثناء الفريق الحالي
      QuerySnapshot teamsSnapshot =
      await FirebaseFirestore.instance.collection('teams').get();
      teams = teamsSnapshot.docs
          .where((doc) => doc.id != widget.teamId)
          .map((doc) => {
        'id': doc.id,
        'name': doc['teamname']?.toString() ?? 'غير معروف',
      })
          .toList()
          .cast<Map<String, String>>();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching teams: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // جلب اللاعبين المنتمين للفريق المختار
  Future<void> _fetchPlayers(String teamId) async {
    try {
      // جلب teamname للفريق المختار
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();
      if (!teamDoc.exists) {
        setState(() {
          players = [];
        });
        return;
      }
      String selectedTeamName = teamDoc['teamname']?.toString() ?? '';

      // جلب اللاعبين
      QuerySnapshot playersSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .where('club', isEqualTo: selectedTeamName)
          .get();
      setState(() {
        players = playersSnapshot.docs
            .map((doc) => {
          'id': doc.id,
          'name': doc['name']?.toString() ?? 'غير معروف',
        })
            .toList()
            .cast<Map<String, String>>();
      });
    } catch (e) {
      print('Error fetching players: $e');
      setState(() {
        players = [];
      });
    }
  }

  // حفظ طلب الشراء في collection "requests"
  Future<void> _submitPurchase() async {
    print('Selected Team ID: $selectedTeamId');
    print('Selected Player ID: $selectedPlayerId');
    print('Team Name: $teamName');

    if (selectedTeamId == null || selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار فريق ولاعب')),
      );
      return;
    }

    try {
      final receiverTeam = teams.firstWhere(
            (team) => team['id'] == selectedTeamId,
        orElse: () => {'id': '', 'name': 'غير معروف'},
      );
      final receiverName = receiverTeam['name'] ?? 'غير معروف';

      print('Receiver Name: $receiverName');
      print('Sender Name: ${teamName ?? 'فريق غير معروف'}');
      print('Player ID: $selectedPlayerId');

      await FirebaseFirestore.instance.collection('requests').add({
        'dateTime': Timestamp.now(),
        'reason': '',
        'receiverName': receiverName,
        'requestStatus': 'في انتظار الرد',
        'senderName': teamName ?? 'فريق غير معروف',
        'type': 'طلب شراء',
        'playerId': selectedPlayerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب الشراء بنجاح')),
      );
      setState(() {
        selectedTeamId = null;
        selectedPlayerId = null;
        players = []; // إعادة تعيين قائمة اللاعبين
      });
    } catch (e) {
      print('Error submitting purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF3D6F5D)),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          "طلب شراء لاعب",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Text(
              "طلب شراء لاعب",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            SizedBox(height: 40),
            _buildCustomListTile(
              title: "أسم الفريق",
              icon: Icons.group,
              flipIcon: false,
              items: teams,
              selectedId: selectedTeamId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTeamId = newValue;
                  selectedPlayerId = null; // إعادة تعيين اختيار اللاعب
                  players = []; // إعادة تعيين قائمة اللاعبين
                  if (newValue != null) {
                    _fetchPlayers(newValue); // جلب اللاعبين للفريق المختار
                  }
                });
              },
            ),
            SizedBox(height: 30),
            _buildCustomListTile(
              title: "أسم اللاعب",
              icon: Icons.person,
              flipIcon: true,
              items: players,
              selectedId: selectedPlayerId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedPlayerId = newValue;
                });
              },
            ),
            SizedBox(height: 220),
            MaterialButton(
              minWidth: 300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Color(0xFF3D6F5D),
              textColor: Colors.white,
              onPressed: () {
                print('Button pressed');
                _submitPurchase();
              },
              child: Text(
                "طلب الشراء",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomListTile({
  required String title,
  required IconData icon,
  bool flipIcon = false,
  List<Map<String, String>>? items,
  String? selectedId,
  void Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.teal[900],
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: flipIcon
                ? Transform.flip(
              flipX: true,
              child: Icon(icon, color: Colors.white),
            )
                : Icon(icon, color: Colors.white),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: items != null && items.isNotEmpty
                  ? Container(
                height: 60,
                alignment: Alignment.centerRight,
                child: DropdownButton<String>(
                  value: selectedId,
                  hint: Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  isExpanded: true,
                  underline: SizedBox(),
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  alignment: AlignmentDirectional.centerStart,
                  itemHeight: 60,
                  items: items
                      .map((item) => DropdownMenuItem<String>(
                    value: item['id'],
                    child: Container(
                      height: 60,
                      alignment: Alignment.centerRight,
                      child: Text(
                        item['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: onChanged,
                ),
              )
                  : Container(
                height: 60,
                alignment: Alignment.centerRight,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}