import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadramootleagues/coachhomepage.dart';
import 'package:hadramootleagues/leagueslistscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminhome.dart';
import 'leaguedetails.dart';
import 'news.dart';
import 'playerhome.dart';
import 'teampage.dart';

class SignUpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String uid;

  SignUpScreen({required this.email, required this.name, required this.uid});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  String _selectedOption = "لاعب";
  bool _isChecked = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name; // ملء الاسم تلقائيًا
  }

  Future<void> _saveUserData() async {
    if (!_isChecked) {
      setState(() {
        _errorMessage = "عليك القبول بالشروط والأحكام أولاً";
      });
      return;
    }

    setState(() {
      _errorMessage = null; // إزالة رسالة الخطأ إذا تم التحقق
    });

    final userData = {
      "name": _nameController.text,
      "email": widget.email,
      "accountType": _selectedOption,
      "uid": widget.uid
    };

    await _firestore.collection("users").doc(widget.uid).set(userData);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", _nameController.text);
    await prefs.setString("email", widget.email);
    await prefs.setString("accountType", _selectedOption);

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Widget nextScreen;
    switch (_selectedOption) {
      case "لاعب":
        nextScreen = PlayerHomePage();
        break;
      case "فريق":
        nextScreen = News();
        break;
      case "مدرب":
        nextScreen = CoachHomePage();
        break;
      default:
        nextScreen = AdminHomePage();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }

  void _showTermsAndConditions() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'الشروط والأحكام',
        style: TextStyle(
          color: Color(0xFF3D6F5D),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
      'باستخدامك لنظام إدارة دوريات كرة القدم بوادي حضرموت، فإنك توافق على الالتزام بالشروط التالية:',
      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
    ),
    SizedBox(height: 10),
    _buildTermItem(
    '1. استخدامك لنظام إدارة دوريات كرة القدم بوادي حضرموت يوجب عليك الالتزام بجميع القوانين واللوائح التي تقر بها وزارة الشباب والرياضة في المحافظة.'),
    _buildTermItem(
    '2. لإدارة التطبيق الحق في الوصول لمعلوماتك الشخصية وتعديلها إذا رأوا شيئاً منها غير دقيق، وكذلك حذف معلوماتك من النظام في حالة وجدت ضدك أي مخالفة.'),
    _buildTermItem(
    '3. توقيعك لعقد مع لاعب أو فريق هو وثيقة رسمية يجب عليك الإيفاء بها.'),
    _buildTermItem(
    '4. يُمنع استخدام النظام لأغراض غير قانونية أو لنشر محتوى يسيء للآخرين.'),
    _buildTermItem(
    '5. يجب عليك تحديث بياناتك الشخصية بشكل دوري لضمان دقة المعلومات.'),
        _buildTermItem(
            '6. إدارة النظام غير مسؤولة عن أي أخطاء ناتجة عن سوء استخدامك للتطبيق.'),
        _buildTermItem(
            '7. يحق لإدارة النظام تعليق حسابك مؤقتًا أو دائمًا في حالة انتهاك الشروط.'),
      ],
      ),
      ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: TextStyle(color: Color(0xFF3D6F5D)),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildTermItem(String term) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        term,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D6F5D),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "تسجيل حساب جديد",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              _buildTextField("الاسم", Icons.person, _nameController, false),
              SizedBox(height: 20),
              _buildTextField("البريد الإلكتروني", Icons.email, TextEditingController(text: widget.email), false,
                  readOnly: true),
              SizedBox(height: 50),
              Divider(),
              SizedBox(height: 20),
              Text("نوع الحساب", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              _buildAccountTypeSelection(),
              SizedBox(height: 20),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showTermsAndConditions,
                      child: Text(
                        "أنا أوافق على الشروط والأحكام",
                        style: TextStyle(
                          color: Color(0xFF3D6F5D),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value!;
                        if (_isChecked) _errorMessage = null; // إزالة الخطأ عند التحديد
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 90),
                height: 40,
                child: ElevatedButton(
                  onPressed: _isChecked ? _saveUserData : null, // تعطيل الزر إذا لم يتم التحديد
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isChecked ? Color(0xFF3D6F5D) : Colors.grey, // تغيير اللون إذا كان معطلًا
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "إنشاء حساب",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isPassword,
      {bool readOnly = false}) {
    return Container(
      height: 50,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Color(0xFF3D6F5D)),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ["لاعب", "فريق", "مدرب"].map((type) => RadioListTile(
        value: type,
        groupValue: _selectedOption,
        onChanged: (value) => setState(() => _selectedOption = value.toString()),
        title: Text(type),
        controlAffinity: ListTileControlAffinity.trailing,
        visualDensity: VisualDensity(vertical: -4),
      )).toList(),
    );
  }
}