import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/requestplayerjoin.dart';
import 'package:hadramootleagues/sendrequestsstatus.dart';
import 'package:hadramootleagues/teamreceivedrequests.dart';

class TeamRequests extends StatefulWidget {
  final String teamId; // معرف الفريق لجلب اسم الفريق
  TeamRequests({required this.teamId});
  @override
  State<TeamRequests> createState() => _TeamRequestsState();
}

class _TeamRequestsState extends State<TeamRequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // لون الخلفية مطابق للصورة
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
              onPressed: () {},
            ),
          ),
        ),
        title: Text(
          'الطلبات',
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
              text: 'طلب انضمام لاعب',
              iconColor: Colors.teal[400]!,
            ),
            Divider(),
            _buildRequestItem(
              context,
              icon: Icons.calendar_today,
              text: 'حالة الطلب المرسل',
              iconColor: Colors.teal[400]!,
            ),
            Divider(),
            _buildRequestItem(
              context,
              icon: Icons.notifications_outlined,
              text: 'الطلبات المستقبلة',
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
          if(text=="طلب انضمام لاعب"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>RequestPlayerJoin(teamId: widget.teamId,) ,));
          }
          else if(text=="حالة الطلب المرسل"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>TeamRequestState() ,));
          }
          else if(text=="الطلبات المستقبلة"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>TeamReceivedRequests() ,));
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
