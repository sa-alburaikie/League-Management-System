import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/main.dart';

class OnBorading1 extends StatefulWidget {
  @override
  State<OnBorading1> createState() => _OnBorading1State();
}

class _OnBorading1State extends State<OnBorading1> {

  void initState() {
    super.initState();
    // الانتقال بعد 3 ثوانٍ
    Future.delayed(Duration(seconds: 3), () {
      LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF3D6F5D), // اللون الأخضر الخلفي
        body:
        Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/image_15993.png", // ضع مسار الشعار هنا
                    width: 250,
                    height: 250,
                  ),
                ]
            )
        )
    );
  }
}