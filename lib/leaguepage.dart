import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/drawpage.dart';
import 'package:hadramootleagues/fullleaguepage.dart';
import 'package:hadramootleagues/groupsknockoutpage.dart';
import 'package:hadramootleagues/knockoutleaguepage.dart';
import 'package:hadramootleagues/leaguestatsscreen.dart';
import 'package:hadramootleagues/matchpage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaguePage extends StatefulWidget {
  final String leagueId;
  const LeaguePage({Key? key, required this.leagueId}) : super(key: key);

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  int selectedIndex = 0;
  bool isLoading = true;
  bool drawCompleted = false;
  String leagueType = '';

  @override
  void initState() {
    super.initState();
    _loadLeagueData();
  }

  Future<void> _loadLeagueData() async {
    var doc = await FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .get();

    if (!doc.data()!.containsKey('drawCompleted')) {
      // إضافة الحقل إلى قاعدة البيانات لأول مرة
      await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).update({
        'drawCompleted': false,
      });
      // جلب البيانات المحدثة بعد التحديث
      doc = await FirebaseFirestore.instance
          .collection('leagues')
          .doc(widget.leagueId)
          .get();
    }

    setState(() {
      drawCompleted = doc['drawCompleted'] ?? false;
      leagueType = doc['leagueType'] ?? '';
      isLoading = false;
    });
  }

  void _refreshPage() async {
    await _loadLeagueData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // الصفحات تتغير حسب حالة drawCompleted
    final List<Widget> pages = [
      LeagueInfo(leagueId: widget.leagueId),
      if (!drawCompleted)
        DrawPage(
          leagueId: widget.leagueId,
          onDrawCompleted: _refreshPage,
        )
      else if (leagueType == "الدوري الكامل")
        FullLeaguePage(leagueId: widget.leagueId)
      else if (leagueType == "دور المجموعات + أدوار اقصائية")
         GroupsKnockoutPage(leagueId: widget.leagueId)
      else if (leagueType == "دور المواجهات المباشرة")
          KnockoutLeaguePage(leagueId: widget.leagueId)
        else
          Placeholder(), // في حال نوع غير معروف
      MatchesScreen(leagueId: widget.leagueId),
      LeagueStatsScreen(leagueId: widget.leagueId),
    ];

    // عناصر الـ BottomNavigationBar تتغير أيضاً
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: Icon(Icons.info_outline), label: "معلومات الدوري"),
      if (!drawCompleted)
        BottomNavigationBarItem(
            icon: Icon(Icons.casino_outlined), label: "إجراء قرعة")
      else if (leagueType == "الدوري الكامل")
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_on), label: "جدول الدوري")
      else if (leagueType == "دور المجموعات + أدوار اقصائية")
          BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined), label: "الرئيسية")
        else if (leagueType == "دور المواجهات المباشرة"||leagueType=="دوري المواجهات المباشرة")
            BottomNavigationBarItem(
                icon: Icon(Icons.account_tree_outlined), label: "الرئيسية")
        else
          BottomNavigationBarItem(icon: Icon(Icons.error), label: "غير معروف"),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined), label: "المباريات"),
      BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined), label: "إحصائيات الدوري"),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: Color(0xFF3D6F5D),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        iconSize: 20,
        items: navItems,
      ),
    );
  }
}




class LeagueInfo extends StatefulWidget {
  final String leagueId;
  const LeagueInfo({Key? key, required this.leagueId}) : super(key: key);

  @override
  State<LeagueInfo> createState() => _LeagueInfoState();
}

class _LeagueInfoState extends State<LeagueInfo> {
  DocumentSnapshot? leagueData;
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic> editableData = {};

  final List<String> leagueTypes = [
    'الدوري الكامل',
    'دور المجموعات + أدوار إقصائية',
    'دوري المواجهات المباشرة',
  ];

  final List<String> matchTypes = [
    'ذهاب وإياب',
    'مباراة واحدة',
  ];

  List<String> allTeams = [];

  @override
  void initState() {
    super.initState();
    fetchLeagueData();
    fetchAllTeams();
  }

  Future<void> fetchLeagueData() async {
    final doc = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
    setState(() {
      leagueData = doc;
      editableData = Map<String, dynamic>.from(doc.data() as Map);
      isLoading = false;
    });
  }

  Future<void> fetchAllTeams() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('teams').get();
    setState(() {
      allTeams = querySnapshot.docs.map((doc) => doc['teamname'].toString()).toList();
    });
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    File imageFile = File(pickedFile.path);
    String fileName = '${widget.leagueId}_${DateTime.now().millisecondsSinceEpoch}';
    final ref = FirebaseStorage.instance.ref().child('league_images/$fileName');
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .update({'imageUrl': imageUrl});
    fetchLeagueData();
  }

  Future<void> saveChanges() async {
    await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).update({
      'leagueName': editableData['leagueName'],
      'leagueType': editableData['leagueType'],
      'numOfTeams': editableData['numOfTeams'],
      'selectedTeams': editableData['selectedTeams'],
      'startDate': editableData['startDate'],
      'endDate': editableData['endDate'],
      'matchType': editableData['matchType'],
    });
    setState(() {
      isEditing = false;
    });
    fetchLeagueData();
  }

  String _getLeagueStatus(dynamic endDate) {
    try {
      if (endDate is Timestamp) {
        return DateTime.now().isBefore(endDate.toDate()) ? 'جاري' : 'مكتمل';
      } else {
        return 'غير معروف';
      }
    } catch (_) {
      return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color(0xFF3D6F5D),
          title: Text('صفحة الدوري', style: TextStyle(color: Colors.white)),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = leagueData!.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] ?? '';

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF3D6F5D),
    title: Text('صفحة الدوري', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
    actions: [
    isEditing
    ? IconButton(
    icon: Icon(Icons.save),
    onPressed: () {
      saveChanges();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        "تم حفظ التعديلات بنجاح",style: TextStyle(color: Colors.white),
      ),duration: Duration(seconds: 2),backgroundColor: Color(0xFF3D6F5D),));
    }
    )
        : IconButton(
    icon: Icon(Icons.edit),
    onPressed: () {
    setState(() {
    isEditing = true;
    });
    },
    ),
    ],
        ),
        body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    children: [
    Center(
    child: Stack(
    alignment: Alignment.bottomRight,
    children: [
    Container(
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.black, width: 2)),
    child: CircleAvatar(
    radius: 45,
    backgroundImage: imageUrl.isNotEmpty
    ? NetworkImage(imageUrl)
        : AssetImage('images/logoofleage.jpg') as ImageProvider,
    ),
    ),
    InkWell(
    onTap: pickAndUploadImage,
    child: Container(
    width: 25,
    height: 25,
    decoration: BoxDecoration(
    color: Color(0xFF3D6F5D),
    shape: BoxShape.circle,
    border: Border.all(color: Colors.black, width: 1),
    ),
    child: Icon(Icons.edit, color: Colors.white, size: 16),
    ),
    ),
    ],
    ),
    ),
    SizedBox(height: 12),
    buildEditableRow(
    'اسم الدوري',
    isEditing
    ? TextFormField(
    initialValue: editableData['leagueName'],
    onChanged: (val) => editableData['leagueName'] = val,
    )
        : Text(data['leagueName'] ?? ''),
    ),
    buildEditableRow(
    'نوع الدوري',
    isEditing
    ? DropdownButton<String>(
    value: editableData['leagueType'],
    onChanged: (value) {
    setState(() {
    editableData['leagueType'] = value!;
    });
    },
    items: leagueTypes.map((type) {
    return DropdownMenuItem(
    value: type,
    child: Text(type),
    );
    }).toList(),
    )
        : Text(data['leagueType'] ?? ''),
    ),
    buildEditableRow(
    'نظام المباريات',
    isEditing
    ? DropdownButton<String>(
    value: editableData['matchType'] ?? matchTypes[0],
    onChanged: (value) {
    setState(() {
    editableData['matchType'] = value!;
    });
    },
    items: matchTypes.map((type) {
    return DropdownMenuItem(
    value: type,
    child: Text(type),
    );
    }).toList(),
    )
        : Text(data['matchType'] ?? ''),
    ),
    buildEditableRow(
    'عدد الفرق',
    isEditing
    ? TextFormField(
    initialValue: editableData['numOfTeams'].toString(),
    keyboardType: TextInputType.number,
    onChanged: (val) => editableData['numOfTeams'] = int.tryParse(val) ?? 0,
    )
        : Text(data['numOfTeams'].toString()),
    ),
    buildEditableRow(
    'الفرق المشاركة',
    isEditing
    ? MultiSelectDialogField<String>(
    items: allTeams.map((team) => MultiSelectItem(team, team)).toList(),
    title: Text("اختر الفرق"),
    initialValue: List<String>.from(editableData['selectedTeams'] ?? []),
    buttonText: Text("تحديد الفرق"),
    onConfirm: (values) {
    setState(() {
    editableData['selectedTeams'] = values;
    });
    },
    )
        : Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text((data['selectedTeams'] as List).isNotEmpty
    ? (data['selectedTeams'] as List)[0]
        : 'لا توجد فرق'),
    SizedBox(height: 4),
    InkWell(
    onTap: () {
    showDialog(
    context: context,
    builder: (context) {
    return AlertDialog(
    title: Text('الفرق المشاركة'),
    content: SizedBox(
    width: double.maxFinite,
    child: ListView(
    shrinkWrap: true,
    children:
    (data['selectedTeams'] as List).map<Widget>((team) {
    return ListTile(
    leading: Icon(Icons.sports_soccer,
    color: Color(0xFF3D6F5D)),
    title: Text(team),
    );
    }).toList(),
    ),
    ),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('إغلاق'),
    ),
    ],
    );
    },
    );
    },
    child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
    Icon(Icons.expand_more, color: Colors.black54),
    ],
    ),
    )
    ],
    ),
    ),
    buildEditableRow(
    'تاريخ البدء',
    isEditing
    ? TextFormField(
    readOnly: true,
    controller: TextEditingController(
    text: editableData['startDate'] != null
    ? DateFormat('dd-MM-yyyy')
        .format((editableData['startDate'] as Timestamp).toDate())
        : ''),
    onTap: () async {
    final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        editableData['startDate'] = Timestamp.fromDate(picked);
      });
    }
    },
    )
        : Text(data['startDate'] != null
        ? DateFormat('dd-MM-yyyy')
        .format((data['startDate'] as Timestamp).toDate())
        : ''),
    ),
      buildEditableRow(
        'تاريخ الانتهاء',
        isEditing
            ? TextFormField(
          readOnly: true,
          controller: TextEditingController(
              text: editableData['endDate'] != null
                  ? DateFormat('dd-MM-yyyy')
                  .format((editableData['endDate'] as Timestamp).toDate())
                  : ''),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                editableData['endDate'] = Timestamp.fromDate(picked);
              });
            }
          },
        )
            : Text(data['endDate'] != null
            ? DateFormat('dd-MM-yyyy')
            .format((data['endDate'] as Timestamp).toDate())
            : ''),
      ),
      buildEditableRow(
        'حالة الدوري',
        isEditing
            ? DropdownButton<String>(
          value: editableData['status'] ?? 'جاري', // قيمة مبدئية تكون "جاري" إذا لم تكن موجودة
          onChanged: (newValue) {
            setState(() {
              editableData['status'] = newValue;
            });
          },
          items: <String>['جاري', 'مكتمل'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        )
            : Text(
          _getLeagueStatus(data['endDate']), // عرض حالة الدوري بناءً على تاريخ الانتهاء
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    ],
    ),
        ),
        ),
    );
  }

  Widget buildEditableRow(String title, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 3),
                width: 90,
                decoration: BoxDecoration(
                  color: Color(0xFF3D6F5D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(child: valueWidget),
            ],
          ),
          Divider(thickness: 0.5),
        ],
      ),
    );
  }
}