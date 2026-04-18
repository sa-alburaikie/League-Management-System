import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/drawpage.dart';
import 'package:hadramootleagues/fullleaguepage.dart';
import 'package:hadramootleagues/groupsknockoutpage.dart';
import 'package:hadramootleagues/knockoutleaguepage.dart';
import 'package:hadramootleagues/leaguestatsscreen.dart';
import 'package:hadramootleagues/leaguestatusscreen.dart';
import 'package:hadramootleagues/matchdetails.dart';
import 'package:hadramootleagues/matchpage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Leaguedetails extends StatefulWidget {
  final String leagueId;
  const Leaguedetails({Key? key, required this.leagueId}) : super(key: key);

  @override
  State<Leaguedetails> createState() => _LeaguedetailsState();
}

class _LeaguedetailsState extends State<Leaguedetails> {
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
      LeagueInfoPage(leagueId: widget.leagueId),
      if (!drawCompleted)
        DrawNotCompletedYet()
      else if (leagueType == "الدوري الكامل")
        FullLeaguePage(leagueId: widget.leagueId)
      else if (leagueType == "دور المجموعات + أدوار اقصائية")
          GroupsKnockoutPage(leagueId: widget.leagueId)
        else if (leagueType == "دور المواجهات المباشرة")
            KnockoutLeaguePage(leagueId: widget.leagueId)
          else
            Placeholder(), // في حال نوع غير معروف
      MatchesDetails(leagueId: widget.leagueId),
      LeagueStatusScreen(leagueId: widget.leagueId),
    ];

    // عناصر الـ BottomNavigationBar تتغير أيضاً
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: Icon(Icons.info_outline), label: "معلومات الدوري"),
      if (!drawCompleted)
        BottomNavigationBarItem(
            icon: Icon(Icons.casino_outlined), label: "القرعة")
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



class DrawNotCompletedYet extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Color(0xFF3D6F5D),
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text('صفحة الدوري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      body:
        Center(
          child: Text("لم يتم إجراء القرعة بعد !",style: TextStyle(color: Color(0xFF3D6F5D),fontSize: 16,fontWeight: FontWeight.bold),)
        )
    );
  }

}



class LeagueInfoPage extends StatefulWidget {
  final String leagueId;
  const LeagueInfoPage({Key? key, required this.leagueId}) : super(key: key);

  @override
  State<LeagueInfoPage> createState() => _LeagueInfoPageState();
}

class _LeagueInfoPageState extends State<LeagueInfoPage> {
  DocumentSnapshot? leagueData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeagueData();
  }

  Future<void> fetchLeagueData() async {
    final doc = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
    setState(() {
      leagueData = doc;
      isLoading = false;
    });
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
                  ],
                ),
              ),
              SizedBox(height: 12),
              buildEditableRow(
                'اسم الدوري',
                Text(data['leagueName'] ?? ''),
              ),
              buildEditableRow(
                'نوع الدوري',
                Text(data['leagueType'] ?? ''),
              ),
              buildEditableRow(
                'نظام المباريات',
                Text(data['matchType'] ?? ''),
              ),
              buildEditableRow(
                'عدد الفرق',
               Text(data['numOfTeams'].toString()),
              ),
              buildEditableRow(
                'الفرق المشاركة',
                Column(
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
                  Text(data['startDate'] != null
                    ? DateFormat('dd-MM-yyyy')
                    .format((data['startDate'] as Timestamp).toDate())
                    : ''),
              ),
              buildEditableRow(
                'تاريخ الانتهاء',
              Text(data['endDate'] != null
                    ? DateFormat('dd-MM-yyyy')
                    .format((data['endDate'] as Timestamp).toDate())
                    : ''),
              ),
              buildEditableRow(
                'حالة الدوري',
                Text(
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