import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/adminhome.dart';

class CreateLeagueScreen extends StatefulWidget {
  @override
  _CreateLeagueScreenState createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  String? leagueName;
  String? leagueType;
  String? matchType;
  int? numOfTeams;
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedTeams = [];
  List<String> allTeams = [];

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  void fetchTeams() async {
    final snapshot = await FirebaseFirestore.instance.collection('teams').get();
    setState(() {
      allTeams = snapshot.docs.map((doc) => doc['teamname'] as String).toList();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("إنشاء دوري", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInputField("اسم الدوري", "الاسم", onChanged: (value) {
                leagueName = value;
              }),
              buildLeagueTypeDropdown(),
              if (leagueType != null) buildMatchTypeDropdown(),
              buildNumOfTeamsDropdown(), // تعديل هنا: استخدام Dropdown بدلاً من TextField
              if (numOfTeams != null) buildTeamSelectionField(),
              buildDateField("تاريخ بدء الدوري", isStartDate: true),
              buildDateField("تاريخ نهاية الدوري", isStartDate: false),
              Center(
                child: MaterialButton(
                  minWidth: 200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Color(0xFF3D6F5D),
                  textColor: Colors.white,
                  onPressed: _createLeague,
                  child: Text("إنشاء دوري", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLeagueTypeDropdown() {
    return buildDropdownField(
      label: "نوع الدوري",
      value: leagueType,
      items: ["الدوري الكامل", "دور المجموعات + أدوار اقصائية", "دور المواجهات المباشرة"],
      onChanged: (val) {
        setState(() {
          leagueType = val;
          matchType = null; // إعادة تعيين نوع المباريات عند تغيير نوع الدوري
        });
      },
    );
  }

  Widget buildMatchTypeDropdown() {
    return buildDropdownField(
      label: "نوع المباريات",
      value: matchType,
      items: ["ذهاب وإياب", "مباراة واحدة فقط"],
      onChanged: (val) {
        setState(() {
          matchType = val;
        });
      },
    );
  }

  // دالة جديدة لإنشاء Dropdown لعدد الفرق
  Widget buildNumOfTeamsDropdown() {
    return buildDropdownField(
        label: "عدد الفرق المشاركة",
        value: numOfTeams?.toString(),
      items: List.generate(15, (index) => (index + 2).toString()), // خيارات من 2 إلى 16 فريقًا
      onChanged: (val) {
        setState(() {
          numOfTeams = int.tryParse(val!);
          selectedTeams.clear(); // مسح الفرق المختارة عند تغيير العدد
        });
      },
    );
  }

  Widget buildInputField(String label, String hintText, {Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 5),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text("اختر"),
            isExpanded: true,
            underline: SizedBox(),
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget buildTeamSelectionField() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Text("اختر الفرق (${selectedTeams.length}/$numOfTeams)", style: TextStyle(fontWeight: FontWeight.bold)),
    SizedBox(height: 5),
    GestureDetector(
    onTap: () {
    showDialog(
    context: context,
    builder: (context) {
    List<String> tempSelectedTeams = List.from(selectedTeams);
    return AlertDialog(
    title: Text("اختر الفرق"),
    content: StatefulBuilder(
    builder: (context, setStateDialog) {
    return Container(
    width: double.maxFinite,
    child: ListView(
    shrinkWrap: true,
    children: allTeams.map((team) {
    return CheckboxListTile(
    title: Text(team),
    value: tempSelectedTeams.contains(team),
    onChanged: (bool? selected) {
    if (selected == true) {
    if (tempSelectedTeams.length < numOfTeams!) {
    tempSelectedTeams.add(team);
    }
    } else {
      tempSelectedTeams.remove(team);
    }
    setStateDialog(() {}); // تحديث داخل الـ dialog نفسه
    },
    );
    }).toList(),
    ),
    );
    },
    ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("إلغاء"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              selectedTeams = List.from(tempSelectedTeams);
            });
            Navigator.pop(context);
          },
          child: Text("تم"),
        ),
      ],
    );
    },
    );
    },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedTeams.isEmpty ? "اختر الفرق" : "${selectedTeams.length} فرق مختارة",
              style: TextStyle(color: Colors.black),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    ),
          SizedBox(height: 10),
          if (selectedTeams.isNotEmpty)
            Wrap(
              spacing: 8.0,
              children: selectedTeams.map((team) {
                return Chip(
                  label: Text(team),
                  deleteIcon: Icon(Icons.cancel),
                  onDeleted: () {
                    setState(() {
                      selectedTeams.remove(team);
                    });
                  },
                );
              }).toList(),
            ),
        ],
    );
  }

  Widget buildDateField(String label, {required bool isStartDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        GestureDetector(
          onTap: () => _selectDate(context, isStartDate),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                SizedBox(width: 10),
                Text(
                  isStartDate
                      ? (startDate != null ? "${startDate!.toLocal()}".split(' ')[0] : 'اختر التاريخ')
                      : (endDate != null ? "${endDate!.toLocal()}".split(' ')[0] : 'اختر التاريخ'),
                  style: TextStyle(fontSize: 14),
                ),
                Spacer(),
                Icon(Icons.calendar_today, color: Colors.black),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  void _createLeague() {
    if (leagueName == null ||
        leagueType == null ||
        matchType == null ||
        numOfTeams == null ||
        startDate == null ||
        endDate == null ||
        selectedTeams.length != numOfTeams) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تأكد من تعبئة جميع الحقول واختيار الفرق المطلوبة"), backgroundColor: Colors.red),
      );
      return;
    }
    FirebaseFirestore.instance.collection('leagues').add({
      'leagueName': leagueName,
      'leagueType': leagueType,
      'matchType': matchType,
      'numOfTeams': numOfTeams,
      'startDate': startDate,
      'endDate': endDate,
      'selectedTeams': selectedTeams,
      'createdAt': DateTime.now(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم إنشاء الدوري بنجاح"), backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminHomePage()));
    });
  }
}