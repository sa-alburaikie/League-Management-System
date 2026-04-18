import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hadramootleagues/main.dart';
import 'package:hadramootleagues/playerpage.dart';
import 'package:hadramootleagues/playerupdates.dart';
import 'package:hadramootleagues/requestpage.dart';
import 'package:hadramootleagues/inbox.dart';
import 'package:hadramootleagues/sendquestion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browse.dart';

class PlayerHomePage extends StatefulWidget {
  @override
  State<PlayerHomePage> createState() => _PlayerHomePageState();
}

class _PlayerHomePageState extends State<PlayerHomePage> {
  int selectedIndex = 0;
  String? userId;
  String? playerName;
  String? playerPosition;
  String? imageUrl;

  final List<Widget> pages = [
    Playerupdates(),
    RequestsPage(),
    InboxScreen(),
    SendQuestion(),
    Browse(),
  ];

  @override
  void initState() {
    super.initState();
    createData();
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('players').doc(userId).get();
      if (doc.exists) {
        setState(() {
          playerName = doc['name'] ?? ''; // إذا كان null، استخدم قيمة افتراضية
          playerPosition = doc['club'] ?? '';
          imageUrl = doc['imageUrl'] ?? '';
        });
      }
    } catch (e) {
      print('Error in _getUserData: $e');
    }
  }

  Future<void> createData() async {
    String _name;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? '';
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
        });
      }
      // الحصول على مرجع الـ document
      DocumentReference docRef = FirebaseFirestore.instance.collection('players').doc(userId);

      // التحقق مما إذا كان الـ document موجودًا
      DocumentSnapshot docSnapshot = await docRef.get();

      // إذا لم يكن الـ document موجودًا، قم بإنشائه
      if (!docSnapshot.exists) {
        await docRef.set({
          'name': _name,
          'position': null,
          'location': null,
          'phone': null,
          'birthDate': null,
          'number': null,
          'club': null,
          'nationality': null,
          'imageUrl': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error in createData: $e');
    }
    _getUserData();
  }

  Future<void> logout(BuildContext context) async {
    try {
      // تسجيل الخروج من Firebase
      await FirebaseAuth.instance.signOut();

      // حذف بيانات SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      GoogleSignIn().signOut();

      // إظهار رسالة تأكيد وتوجيه المستخدم لصفحة البداية
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم تسجيل الخروج بنجاح")),
      );
      // التوجيه إلى صفحة تسجيل الدخول
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      // إذا حدث خطأ أثناء تسجيل الخروج
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تسجيل الخروج: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
    elevation: 0,
    title: Builder(
    builder: (context) {
    switch (selectedIndex) {
    case 0:
    return const Text(
    "تحديثات وأخبار",
    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    );
    case 1:
    return const Text(
    "الطلبات",
    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    );
    case 2:
    return const Text(
    "البريد الوارد",
    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    );
    case 3:
    return const Text(
    "إرسال استفسار",
    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    );
    case 4:
      return const Text(
      "تصفح",
      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      );
    }
    return const SizedBox(); // Avoid errors if no matching value
    },
    ),
    iconTheme: IconThemeData(color: Colors.white),
    centerTitle: true,
    actions: [
    StreamBuilder<DocumentSnapshot>(
    stream: userId != null
    ? FirebaseFirestore.instance.collection('players').doc(userId).snapshots()
        : null, // لا يوجد Stream إذا لم يكن userId متاحًا بعد
    builder: (context, snapshot) {
    // إذا لم يكن هناك بيانات بعد، استخدم القيم الأولية مع التحقق
    if (snapshot.connectionState == ConnectionState.waiting||  !snapshot.hasData || userId == null) {
    return PopupMenuButton<int>(
    icon: Icon(Icons.more_vert, color: Colors.white),
    itemBuilder: (context) => [
    PopupMenuItem(
    height: 100,
    enabled: false,
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: Colors.grey[300],
    backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
    ? NetworkImage(imageUrl!) as ImageProvider
        : null,
    child: imageUrl == null || imageUrl!.isEmpty
    ? const Icon(Icons.person, size: 30, color: Color(0xFF3D6F5D))
        : null,
    ),
    title: Text(
    playerName != null && playerName!.isNotEmpty ? playerName! : "لا يوجد اسم",
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    ),
    subtitle: Text(
    playerPosition != null && playerPosition!.isNotEmpty ? playerPosition! : "لا يوجد فريق",
    style: TextStyle(color: Colors.black),
    ),
    ),
    ),
    PopupMenuDivider(),
    PopupMenuItem(
    padding: EdgeInsets.only(top: 40, right: 10),
    value: 1,
    child: Row(
    children: [
    Icon(Icons.person, color: Color(0xFF3D6F5D)),
    SizedBox(width: 10),
    Text("عرض البروفايل"),
    ],
    ),
    ),
    PopupMenuItem(
    padding: EdgeInsets.only(top: 20, bottom: 20, right: 10),
    value: 2,
    child: Row(
    children: [
    Icon(Icons.logout, color: Colors.red),
    SizedBox(width: 10),
    Text("تسجيل الخروج"),
    ],
    ),
    ),
    ],
    onSelected: (value) async {
    if (value == 1) {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => PlayerProfileScreen(userId: userId!),
    ),
    );
    } else if (value == 2) {
    logout(context);
    }
    },
    );
    }

    // إذا كانت هناك بيانات، قم بتحديث القيم مع التحقق من null أو القيم الفارغة
    var data = snapshot.data!.data() as Map<String, dynamic>?;
    String updatedPlayerName = data?['name'] != null && data!['name'].isNotEmpty
    ? data['name']
        : "لا يوجد اسم";
    String updatedPlayerPosition = data?['club'] != null && data!['club'].isNotEmpty
    ? data['club']
        : "لا يوجد فريق";
    String updatedImageUrl = data?['imageUrl'] ?? imageUrl ?? "";

    return PopupMenuButton<int>(
    icon: Icon(Icons.more_vert, color: Colors.white),
    itemBuilder: (context) => [
    PopupMenuItem(
    height: 100,
    enabled: false,
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: Colors.grey[300],
    backgroundImage: updatedImageUrl.isNotEmpty
    ? NetworkImage(updatedImageUrl) as ImageProvider
        : null,
    child: updatedImageUrl.isEmpty
    ? const Icon(Icons.person, size: 30, color: Color(0xFF3D6F5D))
        : null,
    ),
    title: Text(
    updatedPlayerName,
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    ),
    subtitle: Text(
    updatedPlayerPosition,
    style: TextStyle(color: Colors.black),
    ),
    ),
    ),
    PopupMenuDivider(),
    PopupMenuItem(
    padding: EdgeInsets.only(top: 40, right: 10),
    value: 1,
    child: Row(
    children: [
    Icon(Icons.person, color: Color(0xFF3D6F5D)),
    SizedBox(width: 10),
    Text("عرض البروفايل"),
    ],
    ),
    ),
    PopupMenuItem(
    padding: EdgeInsets.only(top: 20, bottom: 20, right: 10),
    value: 2,
    child: Row(
    children: [
    Icon(Icons.logout, color: Colors.red),
    SizedBox(width: 10),
    Text("تسجيل الخروج"),
    ],
    ),
    ),
    ],
    onSelected: (value) async {
    if (value == 1) {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => PlayerProfileScreen(userId: userId!),
    ),
    );
    } else if (value == 2) {
    logout(context);
    }
    },
    );
    },
    ),
    ],
    ),
    body: pages[selectedIndex], // Body content changes based on the selected index
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
      iconSize: 20, // Reduce icon size
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.update), label: "تحديثات"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "الطلبات"),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: "البريد الوارد"),
        BottomNavigationBarItem(icon: Icon(Icons.help), label: "استفسار"),
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "تصفح"),

      ],
    ),
    );
  }
}