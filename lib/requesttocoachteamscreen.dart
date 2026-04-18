import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestToCoachTeamScreen extends StatefulWidget {
  const RequestToCoachTeamScreen({super.key});

  @override
  _RequestToCoachTeamScreenState createState() => _RequestToCoachTeamScreenState();
}

class _RequestToCoachTeamScreenState extends State<RequestToCoachTeamScreen> {
  String? _coachName;
  String? _coachClub;
  String? _selectedTeam;
  List<String> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
    _loadTeams();
  }

  Future<void> _loadCoachData() async {
    final prefs = await SharedPreferences.getInstance();
    _coachName = prefs.getString('name');
    print('Coach Name from SharedPreferences: $_coachName');
    if (_coachName != null) {
      var coachQuery = await FirebaseFirestore.instance
          .collection('coaches')
          .where('name', isEqualTo: _coachName)
          .limit(1)
          .get();

      if (coachQuery.docs.isNotEmpty) {
        var coachDoc = coachQuery.docs.first;
        print('Coach Doc Found: ${coachDoc.id}');
        print('Club Value: ${coachDoc['club']}');
        setState(() {
          _coachClub = coachDoc['club'] != null && coachDoc['club'].isNotEmpty
              ? coachDoc['club']
              : null;
          _isLoading = false;
        });
      } else {
        print('No matching coach found for name: $_coachName');
        setState(() {
          _coachClub = null;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeams() async {
    var teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
    setState(() {
      _teams = teamsSnapshot.docs
          .map((doc) => doc['teamname'] as String)
          .toList();
      print('Teams Loaded: $_teams');
    });
  }

  Future<void> _sendCoachingRequest() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فريق')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('requests').add({
      'type': 'طلب تدريب',
      'senderName': _coachName,
      'receiverName': _selectedTeam,
      'reason': null,
      'requestStatus': 'في انتظار الرد',
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب التدريب بنجاح')),
    );
    setState(() {}); // لتحديث الواجهة بعد الإرسال
  }

  Future<void> _deleteCoachingRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف طلب التدريب بنجاح')),
    );
    setState(() {}); // لإعادة بناء الواجهة لعرض المحتوى الأساسي
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
    elevation: 0,
    title: const Text(
    "طلب تدريب فريق",
    style: TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    ),
    centerTitle: true,
    leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
    ),
    flexibleSpace: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [const Color(0xFF3D6F5D), const Color(0xFF3D6F5D).withOpacity(0.8)],
    begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    ),
    ),
        ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)))
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_coachClub != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'أنت بالفعل مدرب لـ $_coachClub. قم بالاستقالة من تدريبه أولاً',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D6F5D),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('requests')
        .where('senderName', isEqualTo: _coachName)
        .where('type', isEqualTo: 'طلب تدريب')
        .where('requestStatus', isEqualTo: 'في انتظار الرد')
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF3D6F5D)));
    }

    if (snapshot.hasError) {
    return Center(
    child: Text('حدث خطأ: ${snapshot.error}',
    style: const TextStyle(color: Colors.red)));
    }

    bool hasPendingRequest = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

    if (hasPendingRequest) {
    String requestId = snapshot.data!.docs.first.id; // الحصول على معرف الطلب
    return Center(
    child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.2),
    blurRadius: 8,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    const Text(
    'تم إرسال طلب التدريب. في انتظار الرد',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 20),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF3D6F5D),
    foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
    ),
      onPressed: () => _deleteCoachingRequest(requestId),
      child: const Text(
        "حذف الطلب",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    ),
    ],
    ),
    ),
    );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildModernDropdown("اختر الفريق", Icons.sports_soccer),
          const SizedBox(height: 250),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D6F5D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            onPressed: _sendCoachingRequest,
            child: const Text(
              "إرسال طلب التدريب",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    },
    );
  }

  Widget _buildModernDropdown(String label, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3D6F5D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF3D6F5D)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
                value: _selectedTeam,
                items: _teams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(
                      team,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeam = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}