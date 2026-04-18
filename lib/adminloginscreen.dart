import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminhome.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _loginAdmin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isEmpty) {
        _showError('اسم المستخدم غير صحيح');
      } else {
        final doc = snapshot.docs.first;
        if (doc['password'] == password) {
          // حفظ البيانات في SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('password', password);
          await prefs.setString('accountType', "إدارة");

          // الانتقال إلى الصفحة الرئيسية
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomePage()),
          );
        } else {
          _showError('كلمة السر غير صحيحة');
        }
      }
    } catch (e) {
      _showError('حدث خطأ أثناء تسجيل الدخول');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    Icon(
    Icons.admin_panel_settings,
    color: Color(0xFF3D6F5D),
    size: 80,
    ),
    SizedBox(height: 20),
    Text(
    'تسجيل دخول الادمن',
    style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D6F5D),
    ),
    ),
    SizedBox(height: 40),
    Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: Offset(0, 4),
    ),
    ],
    ),
    child: Form(
    key: _formKey,
    child: Column(
    children: [
    TextFormField(
    controller: _usernameController,
    decoration: InputDecoration(
    prefixIcon: Icon(Icons.person_outline),
    labelText: 'اسم المستخدم',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    ),
      SizedBox(height: 20),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline),
          labelText: 'كلمة السر',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3D6F5D),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _loginAdmin,
          child: Text(
            'تسجيل الدخول',
            style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
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