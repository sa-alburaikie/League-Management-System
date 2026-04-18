import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/coachprofilescreen.dart';

class CoachesScreen extends StatelessWidget {
  final Color primaryColor = const Color(0xFF3D6F5D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('بيانات المدربين',style: TextStyle(
          color: Colors.white,fontWeight: FontWeight.bold
        ),),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coaches').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد بيانات مدربين"));
          }

          var coaches = snapshot.data!.docs;
          return ListView.builder(
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              var coach = coaches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: coach['imageUrl'] != null && coach['imageUrl'].toString().isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(coach['imageUrl']))
                      : const CircleAvatar(child: Icon(Icons.person,color: Colors.white,),backgroundColor: Color(0xFF3D6F5D),),
                  title: Text(coach['name'] ?? 'بدون اسم'),
                  subtitle: Text(coach['club'] != null ? "${coach['club']}" : "لا يوجد فريق"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoachProfileScreen(userId: coach.id),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, coach.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Text('عرض التفاصيل'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
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

  void _showDeleteDialog(BuildContext context, String coachId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المدرب؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('حذف'),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('coaches').doc(coachId).delete();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المدرب بنجاح')),
              );
            },
          ),
        ],
      ),
    );
  }
}