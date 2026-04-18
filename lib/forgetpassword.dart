import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  String _selectedOption = "phone"; // الخيار الافتراضي

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "نسيت كلمة السر",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // دعم الاتجاه من اليمين لليسار
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              // الصورة
              Container(
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    "images/logoofleage.jpg", // استبدلها بالصورة المناسبة
                    height: 200,
                  ),
                ),
              ),

              SizedBox(height: 20),

              Text(
                "حدد التفاصيل التي يجب أن نستخدمها لإعادة تعيين كلمة المرور الخاصة بك.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              SizedBox(height: 20),

              // خيار التواصل عبر الرقم
              ListTile(
                title: Text("+967 776447108",
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                leading: Radio(
                  value: "phone",
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value.toString();
                    });
                  },
                  activeColor: Colors.green, // اللون الأخضر
                ),
              ),

              // خيار التواصل عبر الجيميل
              ListTile(
                title: Text("hashem@gmail.com",
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                leading: Radio(
                  value: "email",
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value.toString();
                    });
                  },
                  activeColor: Colors.green, // اللون الأخضر
                ),
              ),

              SizedBox(height: 20),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2F5D50), // اللون الأخضر الداكن
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("إرسال",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              SizedBox(height: 20),

              // العودة إلى تسجيل الدخول
              TextButton(
                onPressed: () {},
                child: Text(
                  "عد إلى تسجيل الدخول",
                  style: TextStyle(fontSize: 16, color: Color(0xFF2F5D50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
