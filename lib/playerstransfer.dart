import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/playerpurchase.dart';
import 'package:hadramootleagues/playerloan.dart';
import 'package:hadramootleagues/playeroffer.dart';

class PlayersTransfer extends StatefulWidget {
  final String teamId; // معرف الفريق لجلب اسم الفريق
  PlayersTransfer({required this.teamId});

  @override
  State<PlayersTransfer> createState() => _PlayersTransferState();
}

class _PlayersTransferState extends State<PlayersTransfer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // لون الخلفية مطابق للصورة
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF3D6F5D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'انتقالات اللاعبين',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF3D6F5D),
        elevation: 0,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildRequestItem(
              context,
              icon: Icons.group,
              text: 'عرض لاعب',
              iconColor: Colors.teal[400]!,
            ),
            Divider(),
            _buildRequestItem(
              context,
              icon: Icons.calendar_today,
              text: 'إعارة لاعب',
              iconColor: Colors.teal[400]!,
            ),
            Divider(),
            _buildRequestItem(
              context,
              icon: Icons.notifications_outlined,
              text: 'شراء لاعب',
              iconColor: Colors.teal[400]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(
      BuildContext context,
      {
        required IconData icon,
        required String text,
        required Color iconColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: (){
          if(text=="عرض لاعب"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>PlayerOffer(teamId: widget.teamId) ,));
          }
          else if(text=="إعارة لاعب"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>PlayerLoan(teamId: widget.teamId) ,));
          }
          else if(text=="شراء لاعب"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>PlayerPurchase(teamId: widget.teamId) ,));
          }
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 8,),
            Text(
              text,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
