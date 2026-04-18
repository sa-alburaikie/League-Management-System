import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinTeam extends StatefulWidget {
  @override
  _JoinTeamState createState() => _JoinTeamState();
}

class _JoinTeamState extends State<JoinTeam> {
  String? _playerName;
  String? _playerClub;
  String? _selectedTeam;
  List<String> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadTeams();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString('name');
    print('Player Name from SharedPreferences: $_playerName');
    if (_playerName != null) {
      var playerQuery = await FirebaseFirestore.instance
          .collection('players')
          .where('name', isEqualTo: _playerName)
          .limit(1)
          .get();

      if (playerQuery.docs.isNotEmpty) {
        var playerDoc = playerQuery.docs.first;
        print('Player Doc Found: ${playerDoc.id}');
        print('Club Value: ${playerDoc['club']}');
        setState(() {
          _playerClub = playerDoc['club'] != null && playerDoc['club'].isNotEmpty
              ? playerDoc['club']
              : null;
          _isLoading = false;
        });
      } else {
        print('No matching player found for name: $_playerName');
        setState(() {
          _playerClub = null;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeams() async {
    var teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
    setState(() {
      _teams = teamsSnapshot.docs
          .map((doc) => doc['teamname'] as String)
          .toList();
      print('Teams Loaded: $_teams');
    });
  }

  Future<void> _sendJoinRequest() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار فريق')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('requests').add({
      'type': 'طلب انضمام',
      'senderName': _playerName,
      'receiverName': _selectedTeam,
      'reason': null, // ليس مطلوبًا في طلب الانضمام، لكن يمكن إضافته إذا أردت
      'requestStatus': 'في انتظار الرد',
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب الانضمام بنجاح')),
    );
    setState(() {}); // لتحديث الواجهة بعد الإرسال
  }

  Future<void> _deleteJoinRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف طلب الانضمام بنجاح')),
    );
    setState(() {}); // لإعادة بناء الواجهة لعرض المحتوى الأساسي
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
    "انضمام إلى فريق",
    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    ),
    body: _isLoading
    ? Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            SizedBox(height: 30),
        Text(
          "انضمام إلى فريق",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        SizedBox(height: 40),
        if (_playerClub != null)
      Expanded(
    child: Center(
    child: Text(
    'أنت بالفعل منضم لفريق حالياً. قم بالخروج منه ثم أعد إرسال الطلب',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3D6F5D),
      ),
    ),
    ),
    )
    else
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('requests')
        .where('senderName', isEqualTo: _playerName)
        .where('type', isEqualTo: 'طلب انضمام')
        .where('requestStatus', isEqualTo: 'في انتظار الرد')
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: TextStyle(color: Colors.red)));
    }

    bool hasPendingRequest = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

    if (hasPendingRequest) {
    String requestId = snapshot.data!.docs.first.id; // الحصول على معرف الطلب
    return Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Text(
    'تم إرسال طلب الانضمام',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    ),
    SizedBox(height: 20),
    MaterialButton(
    minWidth: 200,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    color: Color(0xFF3D6F5D),
    textColor: Colors.white,
    onPressed: () => _deleteJoinRequest(requestId),
    child: Text(
    "حذف الطلب",
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    ),
    ],
    ),
    );
    }
    return Column(
      children: [
        _buildCustomListTile("الفريق", Icons.logout, flipIcon: true),
        SizedBox(height: 250),
        MaterialButton(
          minWidth: 300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Color(0xFF3D6F5D),
          textColor: Colors.white,
          onPressed: _sendJoinRequest,
          child: Text(
            "انضمام",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
    },
    ),
    ),
            ],
        ),
    ),
    );
  }

  Widget _buildCustomListTile(String title, IconData icon, {bool flipIcon = false}) {
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
                ? Transform.flip(flipX: true, child: Icon(icon, color: Colors.white))
                : Icon(icon, color: Colors.white),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: title,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                value: _selectedTeam,
                items: _teams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team, style: TextStyle(fontSize: 16, color: Colors.black54)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeam = value;
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}


