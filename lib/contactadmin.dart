import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactAdmin extends StatefulWidget {
  final String teamId;

  const ContactAdmin({required this.teamId});

  @override
  State<ContactAdmin> createState() => _ContactAdminState();
}

class _ContactAdminState extends State<ContactAdmin> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _teamName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeamName();
  }

  Future<void> _loadTeamName() async {
    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      setState(() {
        _teamName = teamDoc.data()?['teamname'] as String?;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء جلب اسم الفريق: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
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
        'receiverId': 'adminId',
        'dateTime': Timestamp.now(),
        'isRead': false,
        'reply': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرسالة بنجاح')),
      );

      _titleController.clear();
      _contentController.clear();
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
    if (_teamName == null && !_isLoading) {
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
          "التواصل مع وزارة الشباب والرياضة",
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
                "التواصل مع الإدارة",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 40),
            _buildCustomListTile("ضع عنوان رسالتك هنا", Icons.title, _titleController, flipIcon: true),
            const SizedBox(height: 30),
            _buildCustomListTile("اكتب تفاصيل الرسالة", Icons.info, _contentController, flipIcon: true, maxLines: 3),
            const SizedBox(height: 100),
            MaterialButton(
              minWidth: 120,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: const Color(0xFF3D6F5D),
              textColor: Colors.white,
              onPressed: _isLoading ? null : _sendMessage,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("إرسال", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomListTile(String title, IconData icon, TextEditingController controller, {bool flipIcon = false, int maxLines = 1}) {
    // حساب ارتفاع الحاوية بناءً على عدد الأسطر
    double containerHeight = maxLines == 1 ? 60.0 : 120.0;

    return Container(
      height: containerHeight, // ضبط ارتفاع الحاوية الكلية
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // تمديد العناصر لملء الحاوية
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
              constraints: BoxConstraints(
                minHeight: containerHeight, // ضمان تطابق ارتفاع الحقل مع حاوية الأيقونة
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: title,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: maxLines == 1 ? 15.0 : 10.0, // ضبط المسافة العمودية
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
}