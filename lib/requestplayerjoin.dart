import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestPlayerJoin extends StatefulWidget {
  final String teamId; // معرف الفريق الحالي

  RequestPlayerJoin({required this.teamId});

  @override
  State<RequestPlayerJoin> createState() => _RequestPlayerJoinState();
}

class _RequestPlayerJoinState extends State<RequestPlayerJoin> {
  String? teamName; // اسم الفريق الحالي
  bool isLoading = true; // حالة التحميل
  List<Map<String, String>> players = []; // قائمة اللاعبين غير المنتمين
  String? selectedPlayerId; // معرف اللاعب المختار

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // جلب بيانات الفريق الحالي واللاعبين غير المنتمين
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

      // جلب جميع اللاعبين
      QuerySnapshot playersSnapshot =
      await FirebaseFirestore.instance.collection('players').get();
      players = playersSnapshot.docs
          .where((doc) {
        var club = doc['club'];
        return club == null || club == ''; // تصفية حيث club هو null أو فارغ
      })
          .map((doc) => {
        'id': doc.id,
        'name': doc['name']?.toString() ?? 'غير معروف',
      })
          .toList()
          .cast<Map<String, String>>();

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

  // التحقق من وجود طلب سابق وحفظ الطلب الجديد
  Future<void> _submitRequest() async {
    print('Selected Player ID: $selectedPlayerId');
    print('Team Name: $teamName');

    if (selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار لاعب')),
      );
      return;
    }

    try {
      // التحقق من وجود طلب سابق
      QuerySnapshot existingRequests = await FirebaseFirestore.instance
          .collection('requests')
          .where('playerId', isEqualTo: selectedPlayerId)
          .where('type', isEqualTo: 'طلب انضمام')
          .where('requestStatus', isEqualTo: 'في انتظار الرد')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إرسال طلب مسبق لهذا اللاعب')),
        );
        return;
      }

      // جلب اسم اللاعب المختار
      final selectedPlayer = players.firstWhere(
            (player) => player['id'] == selectedPlayerId,
        orElse: () => {'name': 'غير معروف'},
      );
      final receiverName = selectedPlayer['name'] ?? 'غير معروف';

      print('Receiver Name: $receiverName');
      print('Sender Name: ${teamName ?? 'فريق غير معروف'}');

      // حفظ الطلب في collection "requests"
      await FirebaseFirestore.instance.collection('requests').add({
        'dateTime': Timestamp.now(),
        'reason': '',
        'receiverName': receiverName,
        'requestStatus': 'في انتظار الرد',
        'senderName': teamName ?? 'فريق غير معروف',
        'type': 'طلب انضمام',
        'playerId': selectedPlayerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب الانضمام بنجاح')),
      );

      setState(() {
        selectedPlayerId = null;
      });
    } catch (e) {
      print('Error submitting request: $e');
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
            "طلب انضمام لاعب",
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
              "طلب انضمام لاعب",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            SizedBox(height: 40),
            _buildCustomListTile(
              title: "الاسم",
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
            SizedBox(height: 250),
            MaterialButton(
              minWidth: 300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Color(0xFF3D6F5D),
              textColor: Colors.white,
              onPressed: () {
                print('Button pressed');
                _submitRequest();
              },
              child: Text(
                "ارسال الطلب",
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
      Icon(Icons.arrow_forward, color: Colors.black54),
      SizedBox(width: 10),
    ],
    ),
    );
  }
}