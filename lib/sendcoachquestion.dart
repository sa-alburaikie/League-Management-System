import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendCoachQuestion extends StatefulWidget {
  const SendCoachQuestion({super.key});

  @override
  State<SendCoachQuestion> createState() => _SendCoachQuestionState();
}

class _SendCoachQuestionState extends State<SendCoachQuestion> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _coachName;
  String? _selectedReceiver;
  String? _selectedTeam;
  String? _coachClub;
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
    if (_coachName != null) {
      try {
        var coachQuery = await FirebaseFirestore.instance
            .collection('coaches')
            .where('name', isEqualTo: _coachName)
            .limit(1) // لأننا نتوقع وثيقة واحدة فقط بنفس الاسم
            .get();

        if (coachQuery.docs.isNotEmpty) {
          var coachDoc = coachQuery.docs.first;
          setState(() {
            _coachClub = coachDoc['club'] != null ? coachDoc['club'] : null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading coach data: $e');
        setState(() {
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
      _teams = teamsSnapshot.docs.map((doc) => doc['teamname'] as String).toList();
      print('Teams Loaded: $_teams');
    });
  }

  Future<void> _sendQuestion() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedReceiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    String receiverId;
    if (_selectedReceiver == 'وزارة الشباب والرياضة') {
      receiverId = 'adminId';
    } else if (_selectedReceiver == 'الفريق الحالي') {
      if (_coachClub != null && _coachClub!.isNotEmpty) {
        receiverId = _coachClub!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لست منضمًا لأي فريق بعد')),
        );
        return;
      }
    } else {
      if (_selectedTeam == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار فريق')),
        );
        return;
      }
      receiverId = _selectedTeam!;
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'title': _titleController.text,
      'content': _contentController.text,
      'receiverId': receiverId,
      'senderName': _coachName,
      'isRead': false,
      'reply': null,
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الاستفسار بنجاح')),
    );

    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedReceiver = null;
      _selectedTeam = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const SizedBox(height: 20),
    _buildCustomInputField("العنوان", Icons.title, controller: _titleController),
    const SizedBox(height: 25),
    _buildReceiverDropdown(),
    const SizedBox(height: 25),
          if (_selectedReceiver == 'فريق موجود') ...[
            _buildTeamDropdown(),
            const SizedBox(height: 25),
          ],
          _buildCustomInputField("التفاصيل", Icons.description, controller: _contentController, maxLines: 4),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D6F5D), // اللون الأساسي
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            onPressed: _sendQuestion,
            child: const Text(
              "إرسال الاستفسار",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        ),
        ),
    );
  }

  Widget _buildCustomInputField(String label, IconData icon, {TextEditingController? controller, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.circle, color: Color(0xFF3D6F5D)), // اللون الأساسي
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReceiverDropdown() {
    List<String> options = ['وزارة الشباب والرياضة'];
    if (_coachClub != null && _coachClub!.isNotEmpty) {
      options.add('الفريق الحالي');
    }
    options.add('فريق موجود');
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'المستلم',
          prefixIcon: const Icon(Icons.person, color: Color(0xFF3D6F5D)), // اللون الأساسي
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        value: _selectedReceiver,
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedReceiver = value;
            if (value != 'فريق موجود') {
              _selectedTeam = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildTeamDropdown() {
    return Container(
        decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
    ],
    ),
    child: DropdownButtonFormField<String>(
    decoration: InputDecoration(
    labelText: 'اختر الفريق',
    prefixIcon: const Icon(Icons.group, color: Color(0xFF3D6F5D)), // اللون الأساسي
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
      value: _selectedTeam,
      items: _teams.isEmpty
          ? [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('لا توجد فرق متاحة'),
        ),
      ]
          : _teams.map((team) {
        return DropdownMenuItem<String>(
          value: team,
          child: Text(team),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTeam = value;
        });
      },
    ),
    );
  }
}