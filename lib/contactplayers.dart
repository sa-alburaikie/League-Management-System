import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactPlayers extends StatefulWidget {
  final String teamId;

  const ContactPlayers({required this.teamId});

  @override
  State<ContactPlayers> createState() => _ContactPlayersState();
}

class _ContactPlayersState extends State<ContactPlayers> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _teamName;
  String? _selectedPlayerId;
  List<Map<String, String>> _players = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeamAndPlayers();
  }

  Future<void> _loadTeamAndPlayers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // جلب teamName من مجموعة teams
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      final teamName = teamDoc.data()?['teamname'] as String?;

      if (teamName != null) {
        setState(() {
          _teamName = teamName;
        });

        // جلب اللاعبين الذين يكون club يساوي teamName
        final playersSnapshot = await FirebaseFirestore.instance
            .collection('players')
            .where('club', isEqualTo: teamName)
            .get();

        setState(() {
          _players = playersSnapshot.docs.map((doc) {
            return {
              'id': doc.id, // doc.id هو String بالفعل
              'name': (doc['name'] as String?) ?? 'بدون اسم', // صب صريح إلى String
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء جلب البيانات: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول واختيار مستلم')),
      );
      return;
    }

    if (_teamName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على اسم الفريق')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'senderName': _teamName,
        'receiverId': _selectedPlayerId,
        'dateTime': Timestamp.now(),
        'isRead': false,
        'reply': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرسالة بنجاح')),
      );

      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedPlayerId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء إرسال الرسالة: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3D6F5D)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "التواصل مع اللاعبين",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "التواصل مع اللاعبين",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 40),
            _buildCustomListTile("العنوان", Icons.location_on, _titleController, flipIcon: true),
            const SizedBox(height: 30),
            _buildPlayerDropdown(),
            const SizedBox(height: 30),
            _buildCustomListTile("التفاصيل", Icons.info, _contentController, flipIcon: true, maxLines: 3),
            const SizedBox(height: 100),
            MaterialButton(
              minWidth: 120,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: const Color(0xFF3D6F5D),
              textColor: Colors.white,
              onPressed: _isLoading ? null : _sendMessage,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("تواصل", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomListTile(String title, IconData icon, TextEditingController controller, {bool flipIcon = false, int maxLines = 1}) {
    double containerHeight = maxLines == 1 ? 60.0 : 120.0;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: Colors.teal[900],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: flipIcon
                  ? Transform.flip(
                flipX: true,
                child: Icon(icon, color: Colors.white, size: 30),
              )
                  : Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              constraints: BoxConstraints(minHeight: containerHeight),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: title,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: maxLines == 1 ? 15.0 : 10.0,
                    horizontal: 10.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildPlayerDropdown() {
    double containerHeight = 60.0;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: Colors.teal[900],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child:  Center(
              child: Transform.flip(
                flipX: true,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              constraints: BoxConstraints(minHeight: containerHeight),
              child: DropdownButton<String>(
                value: _selectedPlayerId,
                hint: const Text("اختر اللاعب"),
                isExpanded: true,
                underline: const SizedBox(),
                items: _players.map((player) {
                  return DropdownMenuItem<String>(
                    value: player['id'],
                    child: Text(player['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlayerId = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}