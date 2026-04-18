import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/exitteam.dart';
import 'package:hadramootleagues/jointeam.dart';
import 'package:hadramootleagues/receivedrequests.dart';
import 'package:hadramootleagues/sendrequest.dart';

import 'package:flutter/material.dart';
import 'package:hadramootleagues/sendrequeststate.dart';

class RequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // لون الخلفية مطابق للصورة
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
              icon: Icons.logout,
              text: 'الخروج من الفريق',
              iconColor: Colors.teal[400]!,
            ),
            Divider(),
            _buildRequestItem(
              context,
              icon: Icons.phone,
              text: 'طلب الانضمام إلى فريق',
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
          if(text=="الخروج من الفريق"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ExitTeamScreen() ,));
          }
          else if(text=="طلب الانضمام إلى فريق"){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>JoinTeam() ,));
          }
          else if(text=="حالة الطلب المرسل"){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) =>SendRequestState() ,));
          }
          else if(text=="الطلبات المستقبلة"){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ReceivedRequests() ,));
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

// class RequestPage extends StatefulWidget{
//   @override
//   State<RequestPage> createState() => _RequestPageState();
// }
//
// class _RequestPageState extends State<RequestPage> {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           centerTitle: true,
//           title: Text('الطلبات'),
//         ),
//         body: Directionality(
//           textDirection: TextDirection.rtl,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 ListTile(
//                   title: Text('الخروج من الفريق'),
//                   trailing: Icon(Icons.arrow_forward),
//                   onTap: () {
//                     Navigator.of(context).push(MaterialPageRoute(builder: (context) => ExitTeamScreen(),));
//                   },
//                 ),
//                 Divider(),
//                 ListTile(
//                   title: Text('طلب الانضمام إلى فريق'),
//                   trailing: Icon(Icons.arrow_forward),
//                   onTap: () {
//                     // Action for joining a team
//                   },
//                 ),
//                 Divider(),
//                 ListTile(
//                   title: Text('حالة الطلب المرسل'),
//                   trailing: Icon(Icons.arrow_forward),
//                   onTap: () {
//                     Navigator.of(context).push(MaterialPageRoute(builder: (context) => SendRequest(),));
//                   },
//                 ),
//                 Divider(),
//                 ListTile(
//                   title: Text('الطلبات المستقبلة'),
//                   trailing: Icon(Icons.arrow_forward),
//                   onTap: () {
//                     // Action for viewing received requests
//                   },
//                 ),
//                 Divider(),
//                 Spacer(),
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
