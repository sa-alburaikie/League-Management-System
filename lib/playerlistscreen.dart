import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/playerpage.dart';

class PlayersListScreen extends StatelessWidget {
  final Color primaryColor = const Color(0xFF3D6F5D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('بيانات اللاعبين',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('players').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد بيانات لاعبين'));

          var players = snapshot.data!.docs;
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (ctx, index) {
              var player = players[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: player['imageUrl'] != null
                      ? CircleAvatar(backgroundImage: NetworkImage(player['imageUrl']))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(player['name'] ?? 'بدون اسم'),
                  subtitle: Text(player['position'] ?? 'بدون مركز'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileScreen(userId: player.id)));
                      } else if (value == 'delete') {
                        _confirmDelete(context, player.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('عرض التفاصيل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف اللاعب')),
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

  void _confirmDelete(BuildContext context, String playerId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا اللاعب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor,foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('players').doc(playerId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف اللاعب')));
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}