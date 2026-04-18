import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/leaguepage.dart';
import 'package:intl/intl.dart';

class ManageLeaguesScreen extends StatelessWidget {
  // دالة لجلب بيانات الدوريات من Firestore
  Future<List<Map<String, dynamic>>> _getLeaguesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('leagues').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id, // إضافة id هنا
        'name': data['leagueName'],
        'endDate': (data['endDate'] as Timestamp).toDate(),
        'image': data['image'], // تأكد أن الحقل image موجود في قاعدة البيانات إذا كان هناك صورة
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF3D6F5D),
        title: Text('قائمة الدوريات', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold
        )),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLeaguesFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في جلب البيانات'));
          }
          final leagues = snapshot.data ?? [];
          return ListView.builder(
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              final endDate = league['endDate'];
              final isFinished = endDate.isBefore(DateTime.now());
              final leagueStatus = isFinished ? 'مكتمل' : 'جاري';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5,
                child: ListTile(
                  leading: league['image'] != null
                      ? Image.network(league['image'])
                      : Icon(Icons.sports_soccer, size: 30, color: Color(0xFF3D6F5D)),
                  title: Text(league['name']),
                  subtitle: Text('الحالة: $leagueStatus'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // تمرير leagueId إلى صفحة LeaguePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaguePage(leagueId: league['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}