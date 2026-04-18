import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminsManagementScreen extends StatefulWidget {
  @override
  _AdminsManagementScreenState createState() => _AdminsManagementScreenState();
}

class _AdminsManagementScreenState extends State<AdminsManagementScreen> {
  final Color primaryColor = Color(0xFF3D6F5D);

  void _addNewAdmin() {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("إضافة مسؤول جديد"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "اسم المستخدم"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "كلمة السر"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("إلغاء"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text("إضافة",style: TextStyle(color: Colors.white),),
            onPressed: () async {
              if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('admin').add({
                  'username': usernameController.text.trim(),
                  'password': passwordController.text.trim(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تمت إضافة المسؤول بنجاح")));
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  void _editAdmin(String id, String currentUsername, String currentPassword) {
    TextEditingController usernameController = TextEditingController(text: currentUsername);
    TextEditingController passwordController = TextEditingController(text: currentPassword);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تعديل المسؤول"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "اسم المستخدم"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "كلمة السر"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("إلغاء"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text("تعديل",style: TextStyle(color: Colors.white),),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('admin').doc(id).update({
                'username': usernameController.text.trim(),
                'password': passwordController.text.trim(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تعديل البيانات بنجاح")));
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _deleteAdmin(String id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
        title: Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من حذف هذا المسؤول؟"),
        actions: [
    TextButton(
    child: Text("إلغاء"),
    onPressed: () => Navigator.pop(ctx),
    ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text("حذف",style: TextStyle(color: Colors.white),),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('admin').doc(id).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم حذف المسؤول")));
              setState(() {});
            },
          ),
        ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: Text("إدارة مسؤولي وزارة الشباب",style: TextStyle(color: Colors.white),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admin').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("لا يوجد مسؤولي وزارة الشباب"));

          var admins = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: admins.length,
            itemBuilder: (ctx, index) {
              var admin = admins[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Icon(Icons.person, color: primaryColor),
                  ),
                  title: Text(admin['username'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("كلمة السر: ${admin['password']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor),
                        onPressed: () => _editAdmin(admin.id, admin['username'], admin['password']),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: primaryColor),
                        onPressed: () => _deleteAdmin(admin.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: _addNewAdmin,
        child: Icon(Icons.add),
      ),
    );
  }
}