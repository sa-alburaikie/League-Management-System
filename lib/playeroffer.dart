import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerOffer extends StatefulWidget {
  final String teamId; // معرف الفريق الحالي

  PlayerOffer({required this.teamId});

  @override
  State<PlayerOffer> createState() => _PlayerOfferState();
}

class _PlayerOfferState extends State<PlayerOffer> {
  String? teamName; // اسم الفريق الحالي
  bool isLoading = true; // حالة التحميل
  List<Map<String, dynamic>> players = []; // قائمة اللاعبين
  List<Map<String, dynamic>> teams = []; // قائمة الفرق
  String? selectedPlayerId; // معرف اللاعب المختار
  String? selectedTeamId; // معرف الفريق المختار

  @override
  void initState() {
    super.initState();
    _fetchData();
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
        teamName = teamDoc['teamname'] as String?;
      }

      // جلب اللاعبين المنتمين للفريق الحالي
      QuerySnapshot playersSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .where('club', isEqualTo: teamName)
          .get();
      players = playersSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();

      // جلب جميع الفرق باستثناء الفريق الحالي
      QuerySnapshot teamsSnapshot =
      await FirebaseFirestore.instance.collection('teams').get();
      teams = teamsSnapshot.docs
          .where((doc) => doc.id != widget.teamId) // استبعاد الفريق الحالي
          .map((doc) => {'id': doc.id, 'name': doc['teamname'] as String})
          .toList();

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

  // حفظ طلب العرض في collection "requests"
  Future<void> _submitOffer() async {
    if (selectedPlayerId == null || selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار لاعب وفريق')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'dateTime': Timestamp.now(),
        'reason': '',
        'receiverName': teams.firstWhere((team) => team['id'] == selectedTeamId)['name'],
        'requestStatus': 'في انتظار الرد',
        'senderName': teamName,
        'type': 'طلب عرض',
        'playerId': selectedPlayerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب العرض بنجاح')),
      );

      setState(() {
        selectedPlayerId = null;
        selectedTeamId = null;
      });
    } catch (e) {
      print('Error submitting offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب')),
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
    "عرض اللاعب",
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
            "عرض لاعب",
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
          SizedBox(height: 15),
          SizedBox(height: 220),
          MaterialButton(
            minWidth: 300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Color(0xFF3D6F5D),
            textColor: Colors.white,
            onPressed: _submitOffer,
            child: Text(
              "عرض اللاعب",
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
    List<Map<String, dynamic>>? items,
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
                height: 60, // مطابقة ارتفاع الأيقونة
                alignment: Alignment.centerRight, // محاذاة النص إلى اليمين
                child: DropdownButton<String>(
                  value: selectedId,
                  hint: Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  isExpanded: true,
                  underline: SizedBox(),
                  // تعديل حجم النص ومحاذاته
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  // محاذاة النص المختار إلى اليمين
                  alignment: AlignmentDirectional.centerStart, // يبدأ من اليمين في RTL
                  // تقليل ارتفاع العناصر في القائمة
                  itemHeight: 60,
                  items: items
                      .map((item) => DropdownMenuItem<String>(
                    value: item['id'],
                    child: Container(
                      height: 60, // مطابقة ارتفاع الأيقونة
                      alignment: Alignment.centerRight, // محاذاة عناصر القائمة إلى اليمين
                      child: Text(
                        item['name'],
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
                height: 60, // مطابقة ارتفاع الأيقونة
                alignment: Alignment.centerRight, // محاذاة النص الافتراضي إلى اليمين
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