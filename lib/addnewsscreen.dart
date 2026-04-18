import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadramootleagues/newslistscreen.dart';

class AddNewsScreen extends StatefulWidget {
  @override
  _AddNewsScreenState createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _target = 'الجميع';

  List<String> targetOptions = [
    'الجميع',
    'اللاعبين',
    'المدربين',
    'الفرق',
  ];

  bool _isLoading = false;

  Future<void> _sendNews() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('news').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'target': _target,
        'date': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الخبر بنجاح!'),
          backgroundColor: Color(0xFF3D6F5D), // اللون المتناسق مع الثيم
          duration: Duration(seconds: 2), // مدة عرض الـ Snackbar
        ),
      );

      _titleController.clear();
      _contentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Color(0xFF3D6F5D),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('إضافة خبر جديد',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          actions: [
            IconButton(
              icon: Icon(Icons.list_alt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewsListScreen()),
                );
              },
              tooltip: 'عرض الأخبار',
            ),
          ],
        ),
        body: Padding(
        padding: const EdgeInsets.all(20.0),
    child: Form(
    key: _formKey,
    child: Column(
    children: [
    TextFormField(
    controller: _titleController,
    decoration: InputDecoration(
    labelText: 'عنوان الخبر',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'يرجى كتابة عنوان الخبر';
    }
    return null;
    },
    ),
    SizedBox(height: 16),
    TextFormField(
    controller: _contentController,
    maxLines: 5,
    decoration: InputDecoration(
    labelText: 'محتوى الخبر',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'يرجى كتابة محتوى الخبر';
    }
    return null;
    },
    ),
    SizedBox(height: 16),
    DropdownButtonFormField<String>(
    value: _target,
    items: targetOptions.map((target) {
    return DropdownMenuItem(
    value: target,
    child: Text(target),
    );
    }).toList(),
    onChanged: (value) {
    setState(() {
      _target = value!;
    });
    },
      decoration: InputDecoration(
        labelText: 'إرسال إلى',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
      SizedBox(height: 24),
      _isLoading
          ? CircularProgressIndicator()
          : SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3D6F5D),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _sendNews,
          child: Text(
            'إرسال الخبر',
            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Colors.white),
          ),
        ),
      ),
    ],
    ),
    ),
        ),
    );
  }
}
