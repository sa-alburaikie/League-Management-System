import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExitTeamScreen extends StatefulWidget {
  @override
  _ExitTeamScreenState createState() => _ExitTeamScreenState();
}

class _ExitTeamScreenState extends State<ExitTeamScreen> {
  String? _playerName;
  String? _playerClub;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
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

  Future<void> _sendExitRequest() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال سبب الخروج')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('requests').add({
      'type': 'طلب خروج',
      'senderName': _playerName,
      'receiverName': _playerClub,
      'reason': _reasonController.text,
      'requestStatus': 'في انتظار الرد',
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب الخروج بنجاح')),
    );

    _reasonController.clear();
    setState(() {}); // لتحديث الواجهة بعد الإرسال
  }

  Future<void> _deleteExitRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف طلب الخروج بنجاح')),
    );
    setState(() {}); // لإعادة بناء الواجهة لعرض الحقول مرة أخرى
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
            "الخروج من الفريق",
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
              "الخروج من فريق",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            SizedBox(height: 40),
            if (_playerClub == null)
      Expanded(
    child: Center(
    child: Text(
    'لا يوجد فريق حالي للخروج منه',
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
        .where('type', isEqualTo: 'طلب خروج')
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
    'تم إرسال الطلب بنجاح',
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
    onPressed: () => _deleteExitRequest(requestId),
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
    _buildCustomListTile("الفريق", Icons.logout,
    flipIcon: true, value: _playerClub, isEditable: false),
    SizedBox(height: 15),
    _buildCustomListTile("اللاعب", Icons.person,
        flipIcon: false, value: _playerName, isEditable: false),
      SizedBox(height: 15),
      _buildCustomListTile("السبب", Icons.help_outline,
          flipIcon: false, controller: _reasonController, isEditable: true),
      SizedBox(height: 150),
      MaterialButton(
        minWidth: 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Color(0xFF3D6F5D),
        textColor: Colors.white,
        onPressed: _sendExitRequest,
        child: Text(
          "إرسال طلب الخروج",
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

  Widget _buildCustomListTile(String title, IconData icon,
      {bool flipIcon = false, String? value, TextEditingController? controller, bool isEditable = false}) {
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
              child: isEditable
                  ? SizedBox(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: title,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  maxLines: 1,
                ),
              )
                  : Text(
                value ?? '',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}