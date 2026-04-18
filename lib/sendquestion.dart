import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendQuestion extends StatefulWidget {
  @override
  State<SendQuestion> createState() => _SendQuestionState();
}

class _SendQuestionState extends State<SendQuestion> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _playerName;
  String? _selectedReceiver;
  String? _selectedTeam;
  String? _playerClub;
  List<String> _teams = [];
  bool _isLoading = true; // للتحقق من تحميل البيانات

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadTeams();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString('name');
    if (_playerName != null) {
      var playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(_playerName)
          .get();
      setState(() {
        _playerClub = playerDoc.exists && playerDoc['club'] != null && playerDoc['club'].isNotEmpty
            ? playerDoc['club']
            : null;
        _isLoading = false; // تم تحميل البيانات
        print('Player Club: $_playerClub'); // تصحيح أخطاء
      });
    }
  }

  Future<void> _loadTeams() async {
    var teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
    setState(() {
      _teams = teamsSnapshot.docs.map((doc) => doc['teamname'] as String).toList();
      print('Teams Loaded: $_teams'); // تصحيح أخطاء
    });
  }

  Future<void> _sendQuestion() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedReceiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    String receiverId;
    if (_selectedReceiver == 'وزارة الشباب والرياضة') {
      receiverId = 'adminId';
    } else if (_selectedReceiver == 'الفريق الحالي') {
      if (_playerClub != null && _playerClub!.isNotEmpty) {
        receiverId = _playerClub!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لست منضمًا لأي فريق بعد')),
        );
        return;
      }
    } else {
      if (_selectedTeam == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى اختيار فريق')),
        );
        return;
      }
      receiverId = _selectedTeam!;
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'title': _titleController.text,
      'content': _contentController.text,
      'receiverId': receiverId,
      'senderName': _playerName,
      'isRead': false,
      'reply': null,
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال الاستفسار بنجاح')),
    );

    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedReceiver = null;
      _selectedTeam = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    SizedBox(height: 50),
    _buildCustomListTile("العنوان", Icons.location_on, flipIcon: true, controller: _titleController),
    SizedBox(height: 30),
      _buildReceiverDropdown(),
      SizedBox(height: 30),
      if (_selectedReceiver == 'فريق موجود') ...[
        _buildTeamDropdown(),
        SizedBox(height: 30), // مسافة بين الحقل الرابع والتفاصيل
      ],
      _buildCustomListTile("التفاصيل", Icons.info, flipIcon: true, controller: _contentController),
      SizedBox(height: 50),
      MaterialButton(
        minWidth: 120,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Color(0xFF3D6F5D),
        textColor: Colors.white,
        onPressed: _sendQuestion,
        child: Text("إرسال الاستفسار", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ],
    ),
    ),
        ),
    );
  }

  Widget _buildCustomListTile(String title, IconData icon, {bool flipIcon = false, TextEditingController? controller}) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: title,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildReceiverDropdown() {
    List<String> options = ['وزارة الشباب والرياضة'];
    if (_playerClub != null && _playerClub!.isNotEmpty) {
      options.add('الفريق الحالي');
    }
    options.add('فريق موجود');

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
            child: Transform.flip(flipX: true, child: Icon(Icons.person, color: Colors.white)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'المستلم',
                  border: InputBorder.none,
                ),
                value: _selectedReceiver,
                items: options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReceiver = value;
                    if (value != 'فريق موجود') {
                      _selectedTeam = null;
                    }
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
  Widget _buildTeamDropdown() {
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
            child: Transform.flip(flipX: true, child: Icon(Icons.group, color: Colors.white)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'اختر الفريق',
                  border: InputBorder.none,
                ),
                value: _selectedTeam,
                items: _teams.isEmpty
                    ? [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('لا توجد فرق متاحة'),
                  ),
                ]
                    : _teams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
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