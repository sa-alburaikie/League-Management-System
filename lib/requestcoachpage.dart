import 'package:flutter/material.dart';
import 'package:hadramootleagues/coachreceivedrequests.dart';
import 'package:hadramootleagues/coachrequeststate.dart';
import 'package:hadramootleagues/exitteam.dart';
import 'package:hadramootleagues/jointeam.dart';
import 'package:hadramootleagues/receivedrequests.dart';
import 'package:hadramootleagues/requesttocoachteamscreen.dart';
import 'package:hadramootleagues/resignfromteamscreen.dart';
import 'package:hadramootleagues/sendrequeststate.dart';

class RequestCoachPage extends StatelessWidget {
  const RequestCoachPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300], // خلفية ناعمة
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildModernRequestItem(
                  context,
                  icon: Icons.exit_to_app,
                  text: 'الاستقالة من تدريب فريق',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ResignFromTeamScreen()),
                  ),
                ),
                _buildModernRequestItem(
                  context,
                  icon: Icons.sports_soccer,
                  text: 'طلب تدريب فريق',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RequestToCoachTeamScreen()),
                  ),
                ),
                _buildModernRequestItem(
                  context,
                  icon: Icons.hourglass_empty,
                  text: 'حالة الطلب المرسل',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CoachRequestState()),
                  ),
                ),
                _buildModernRequestItem(
                  context,
                  icon: Icons.notifications,
                  text: 'الطلبات المستقبلة',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CoachReceivedRequests()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRequestItem(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Colors.white, Colors.grey[50]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.2),
    blurRadius: 8,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: Row(
    children: [
    // أيقونة ديناميكية
    Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color: const Color(0xFF3D6F5D).withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: Icon(
    icon,
    color: const Color(0xFF3D6F5D),
      size: 28,
    ),
    ),
      const SizedBox(width: 16),
      // النص
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      // أيقونة انتقال
      const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Color(0xFF3D6F5D),
      ),
    ],
    ),
    ),
    ),
    );
  }
}