import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/adminsmanagementscreen.dart';
import 'package:hadramootleagues/coachesscreen.dart';
import 'package:hadramootleagues/playerlistscreen.dart';
import 'package:hadramootleagues/teamdatascreen.dart';

class UserManagementScreen extends StatelessWidget {
  final Color primaryColor = const Color(0xFF3D6F5D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('إدارة المستخدمين',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildOption(context, 'مسؤولي وزارة الشباب والرياضة', Icons.admin_panel_settings, AdminsManagementScreen()),
            _buildOption(context, 'بيانات اللاعبين', Icons.sports_soccer, PlayersListScreen()),
            _buildOption(context, 'بيانات المدربين', Icons.sports, CoachesScreen()),
            _buildOption(context, 'بيانات الفرق', Icons.groups, TeamsDataScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, IconData icon, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}