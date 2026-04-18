import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "images/firstPicture.jpg", // استبدل بالمسار الصحيح للصورة
      "title": "تعرف على الفرق المحلية بسهولة",
      "description": "اكتشف الفرق المشاركة في الدوري واطلع على تفاصيل المباريات القادمة في منطقتك"
    },
    {
      "image": "images/secondPicture.jpg",
      "title": "تحديثات المباريات المباشرة",
      "description": "تابع النتائج الحية لكل مباراة وأحدث ترتيب الفرق في الدوري"
    },
    {
      "image": "images/thirdPicture.jpg",
      "title": "كن على استعداد للمشاركة",
      "description": "سجل فريقك أو احصل على مقعد لمتابعة المباريات القريبة منك"
    },
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    prefs.setBool('hasSeenOnBoarding', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Image.asset(
                      _pages[index]["image"]!,
                      height: 300,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _pages[index]["title"]!,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _pages[index]["description"]!,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _goToLogin,
                child: Text("     تخطي", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16, color: Color(0xFF3D6F5D))),
              ),
              Row(
                children: List.generate(_pages.length, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Color(0xFF3D6F5D) : Colors.grey[300],
                    ),
                  );
                }),
              ),
              TextButton(
                onPressed: _nextPage,
                child: Text("التالي        ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16, color: Color(0xFF3D6F5D))),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
