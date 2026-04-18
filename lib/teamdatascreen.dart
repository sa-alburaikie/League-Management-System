import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/teampage.dart';

class TeamsDataScreen extends StatelessWidget {
  final Color primaryColor = Color(0xFF3D6F5D);

  Future<void> _deleteTeam(BuildContext context, String teamId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من حذف هذا الفريق؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("حذف")),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('teams').doc(teamId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم حذف الفريق")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("بيانات الفرق",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("لا توجد بيانات للفرق"));

          var teams = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              var team = teams[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.group, size: 40, color: primaryColor),
                  title: Text(team['teamname'] ?? "بدون اسم", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("عدد اللاعبين: ${team['playernumber'] ?? 0}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'details') {
                        Navigator.push(context,MaterialPageRoute(builder: (context) => TeamProfileScreen(teamId:team.id),));
                      } else if (value == 'delete') {
                        _deleteTeam(context, team.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'details', child: Text("عرض التفاصيل")),
                      PopupMenuItem(value: 'delete', child: Text("حذف")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}