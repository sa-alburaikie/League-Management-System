import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowPlayers extends StatefulWidget {
  final String teamId; // معرف الفريق لجلب اسم الفريق

  ShowPlayers({required this.teamId});

  @override
  State<ShowPlayers> createState() => _ShowPlayersState();
}

class _ShowPlayersState extends State<ShowPlayers> {
  String? teamName; // اسم الفريق
  bool isLoading = true; // حالة التحميل

  @override
  void initState() {
    super.initState();
    _fetchTeamName();
  }

  // جلب اسم الفريق من Firestore
  Future<void> _fetchTeamName() async {
    try {
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        setState(() {
          teamName = teamDoc['teamname'] as String?;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching team name: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // الاستغناء عن اللاعب
  Future<void> _releasePlayer(String playerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .update({'club': null});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الاستغناء عن اللاعب بنجاح')),
      );
    } catch (e) {
      print('Error releasing player: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الاستغناء عن اللاعب')),
      );
    }
  }

  // إظهار مربع حوار التأكيد
  void _showReleaseConfirmationDialog(String playerId, String playerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الاستغناء'),
        content: Text('هل أنت متأكد من الاستغناء عن اللاعب $playerName؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await _releasePlayer(playerId);
              Navigator.pop(context);
            },
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        leading: Padding(
        padding: const EdgeInsets.all(10),
    child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
    color: Color(0xFF3D6F5D),
    borderRadius: BorderRadius.circular(10),
    ),
    child: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
    ),
    ),
    ),
    title: Text(
    'لاعبي الفريق',
    style: TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    ),
    ),
    centerTitle: true,
    backgroundColor: Color(0xFF3D6F5D),
    elevation: 0,
    ),
    body: isLoading
    ? Center(child: CircularProgressIndicator())
        : Container(
    width: double.infinity,
    child: Column(
    children: [
    SizedBox(height: 16),
    Expanded(
    child: Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    ),
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('players')
        .where('club', isEqualTo: teamName)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لا يوجد لاعبين في الفريق'));
        }

        final players = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 10),
          itemCount: players.length,
          separatorBuilder: (context, index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(thickness: 1),
          ),
          itemBuilder: (context, index) {
            final player = players[index];
            return _buildRequestItem(
              playerId: player.id,
              name: player['name'] ?? 'غير معروف',
              birthDate: player['birthDate'] ?? '',
              imageUrl: player['imageUrl'],
            );
          },
        );
      },
    ),
    ),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildRequestItem({
    required String playerId,
    required String name,
    required String birthDate,
    required String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(Icons.person, color: Colors.black54, size: 28)
                : null,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: birthDate.isNotEmpty
            ? Text(
          birthDate,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        )
            : Text("لم يتم تحديده"),
        trailing: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showReleaseConfirmationDialog(playerId, name),
              child: _buildActionButton("Release", Colors.teal[700]!, Colors.white),
            ),
            SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color bgColor, Color textColor) {
    return Container(
      width: 60,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}