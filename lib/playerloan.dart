import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerLoan extends StatefulWidget {
  final String teamId; // معرف الفريق الحالي

  PlayerLoan({required this.teamId});

  @override
  State<PlayerLoan> createState() => _PlayerLoanState();
}

class _PlayerLoanState extends State<PlayerLoan> {
  String? teamName; // اسم الفريق الحالي
  bool isLoading = true; // حالة التحميل
  List<Map<String, String>> players = []; // قائمة اللاعبين
  List<Map<String, String>> teams = []; // قائمة الفرق
  String? selectedPlayerId; // معرف اللاعب المختار
  String? selectedTeamId; // معرف الفريق المختار
  final TextEditingController _durationController = TextEditingController(); // تحكم بحقل المدة

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  // جلب بيانات الفريق الحالي واللاعبين والفرق
  Future<void> _fetchData() async {
    try {
      // جلب اسم الفريق الحالي
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        teamName = teamDoc['teamname']?.toString();
      }

      // جلب اللاعبين المنتمين للفريق الحالي
      QuerySnapshot playersSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .where('club', isEqualTo: teamName)
          .get();
      players = playersSnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'name': doc['name']?.toString() ?? 'غير معروف',
      })
          .toList()
          .cast<Map<String, String>>(); // تحديد النوع صراحة

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
          .cast<Map<String, String>>(); // تحديد النوع صراحة

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // حفظ طلب الإعارة في collection "requests"
  Future<void> _submitLoan() async {
    print('Selected Player ID: $selectedPlayerId');
    print('Selected Team ID: $selectedTeamId');
    print('Duration: ${_durationController.text}');
    print('Team Name: $teamName');

    if (selectedPlayerId == null  ||selectedTeamId == null || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار لاعب وفريق وإدخال المدة')),
      );
      return;
    }

    try {
      // البحث عن اسم الفريق المستلم
      final receiverTeam = teams.firstWhere(
            (team) => team['id'] == selectedTeamId,
        orElse: () => {'id': '', 'name': 'غير معروف'},
      );
      final receiverName = receiverTeam['name'] ?? 'غير معروف';

      // التحقق من جميع القيم قبل الإرسال
      print('Receiver Name: $receiverName');
      print('Sender Name: ${teamName ?? 'فريق غير معروف'}');
      print('Player ID: $selectedPlayerId');
      print('Duration: ${_durationController.text}');

      await FirebaseFirestore.instance.collection('requests').add({
        'dateTime': Timestamp.now(),
        'reason': '',
        'receiverName': receiverName,
        'requestStatus': 'في انتظار الرد',
        'senderName': teamName ?? 'فريق غير معروف',
        'type': 'طلب إعارة',
        'playerId': selectedPlayerId,
        'duration': _durationController.text, // يقبل أي نص
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب الإعارة بنجاح')),
      );
      setState(() {
        selectedPlayerId = null;
        selectedTeamId = null;
        _durationController.clear();
      });
    } catch (e) {
      print('Error submitting loan: $e');
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
          "إعارة لاعب",
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
              "إعارة لاعب",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            SizedBox(height: 40),
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
            SizedBox(height: 30),
            _buildCustomListTile(
              title: "أسم الفريق",
              icon: Icons.group,
              flipIcon: false,
              items: teams,
              selectedId: selectedTeamId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTeamId = newValue;
                });
              },
            ),
            SizedBox(height: 30),
            _buildCustomListTile(
              title: "المدة",
              icon: Icons.data_exploration,
              flipIcon: false,
              textController: _durationController,
            ),
            SizedBox(height: 150),
            MaterialButton(
              minWidth: 300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Color(0xFF3D6F5D),
              textColor: Colors.white,
              onPressed: () {
                print('Button pressed');
                _submitLoan();
              },
              child: Text(
                "إعارة اللاعب",
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
  TextEditingController? textController,
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
              child: textController != null
                  ? Container(
                height: 60,
                alignment: Alignment.centerRight,
                child: TextField(
                  controller: textController,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: title,
                    hintStyle: TextStyle(fontSize: 16, color: Colors.black54),
                    border: InputBorder.none,
                  ),
                ),
              )
                  : items != null && items.isNotEmpty
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