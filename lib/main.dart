import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hadramootleagues/adminloginscreen.dart';
import 'package:hadramootleagues/coachhomepage.dart';
import 'package:hadramootleagues/firstuse.dart';
import 'package:hadramootleagues/leagueslistscreen.dart';
import 'package:hadramootleagues/news.dart';
import 'package:hadramootleagues/signup.dart';
import 'package:hadramootleagues/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'adminhome.dart';
import 'firebase_options.dart';
import 'leaguedetails.dart';
import 'playerhome.dart';
import 'teampage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform
  );
  await supabase.Supabase.initialize(
    url: 'https://atpgexatmjshlwmjeeqj.supabase.co', // استبدل بـ URL الخاص بك
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0cGdleGF0bWpzaGx3bWplZXFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2NTI2ODIsImV4cCI6MjA2NDIyODY4Mn0.fEqbnTqCT2Wz0O1T7GocG-AEr66CwRQaPNKmJpjGOy0', // استبدل بالمفتاح العام
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(),
      // home: AdminHomePage(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnBoarding = prefs.getBool("hasSeenOnBoarding") ?? false;
    String? accountType = prefs.getString("accountType");

    await Future.delayed(Duration(seconds: 2)); // وقت قصير لعرض شاشة البداية

    if (!hasSeenOnBoarding) {
    Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => OnboardingScreen()),
    );
    }  else if (accountType != null) {
      _navigateToHome(accountType);
    }

    else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _navigateToHome(String accountType) {
    Widget nextScreen;
    switch (accountType) {
      case "لاعب":
        nextScreen = PlayerHomePage();
        break;
      case "فريق":
        nextScreen = News();
        break;
      case "مدرب":
        nextScreen = CoachHomePage();
        break;
      case "مستخدم":
        nextScreen = UserHome();
        break;
      case "إدارة":
        nextScreen = AdminHomePage();
        break;
      default:
        nextScreen = LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    if (googleAuth == null) return;

    final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
    );


    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      await _checkUserExists(user);
    }
    } catch (e) {
     print("Error signing in with Google: $e");
     }
     }


  // 🔹 التحقق مما إذا كان المستخدم موجودًا مسبقًا
  Future<void> _checkUserExists(User user) async {
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();

    if (userDoc.exists) {
      // ✅ الحساب موجود → جلب البيانات وحفظها محليًا
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      await _saveUserData(userData);
      _navigateToNextScreen(userData["accountType"]);
    } else {
      // ❌ الحساب غير موجود → الانتقال إلى SignUpScreen
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => SignUpScreen(
          email: user.email!,
          name: user.displayName ?? "",
          uid: user.uid,
      )
      )
      );
    }
  }

  // 🔹 تخزين بيانات المستخدم في Shared Preferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", userData["name"]);
    await prefs.setString("email", userData["email"]);
    // await prefs.setString("phone", userData["phone"]);
    await prefs.setString("accountType", userData["accountType"]);
    await prefs.setBool("hasSeenOnBoarding", true);

  }
  void loglog() async{
  await FirebaseAuth.instance.signOut();
  GoogleSignIn().signOut();
  // الحصول على مثيل SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // حفظ قيمة hasSeenOnBoarding قبل المسح
  bool? hasSeenOnBoarding = prefs.getBool('hasSeenOnBoarding');

  // مسح جميع البيانات من SharedPreferences
  await prefs.clear();

  // إعادة تعيين قيمة hasSeenOnBoarding إلى قيمتها الأصلية
  if (hasSeenOnBoarding != null) {
  await prefs.setBool('hasSeenOnBoarding', hasSeenOnBoarding);
  }
}
@override
  void initState() {
    loglog();
    // TODO: implement initState
    super.initState();
  }
  // 🔹 التوجيه للصفحة المناسبة بناءً على نوع الحساب
  void _navigateToNextScreen(String accountType) {
    Widget nextScreen;

    switch (accountType) {
      case "لاعب":
        nextScreen = PlayerHomePage();
        break;
      case "فريق":
        nextScreen = News();
        break;
      case "مدرب":
        nextScreen = CoachHomePage();
        break;
      case "management":
        nextScreen = AdminHomePage();
        break;
      default:
        nextScreen = PlayerHomePage();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }

  Future<void> _loginAsGuest(BuildContext context) async {
    // الحصول على مثيل SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // تخزين القيم في SharedPreferences
    await prefs.setBool('hasSeenOnBoarding', true);
    await prefs.setString('accountType', 'مستخدم');

    // الانتقال إلى صفحة LeagueDetails
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserHome()), // تأكد من تمرير أي معلمات مطلوبة إذا لزم الأمر
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3D6F5D), // اللون الأخضر الخلفي
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/image_15993.png", // ضع مسار الشعار هنا
                    width: 250,
                    height: 250,
                  ),
                  SizedBox(height: 10),
                  // Text(
                  //   "WADI HADHRAMAUT\nLEAGUE",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 22,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                children: [
                  // _buildButton("تسجيل الدخول بالبريد الإلكتروني", Color(0xFF3D6F5D), Colors.white, () {
                  //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginWithEmail(),));
                  // }),
                  const SizedBox(height: 10),
                  // _buildButton("تسجيل الدخول برقم الهاتف", Colors.grey[300]!, Colors.black, () {
                  //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginWithPhone(),));
                  //
                  // }),
                  const SizedBox(height: 10),
                  _buildButton("تسجيل الدخول باستخدام جوجل", Color(0xFF3D6F5D), Colors.white, () {
                    _signInWithGoogle(context);
                    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginWithEmail(),));

                  }),
                  SizedBox(height: 10,),
                  _buildButton("تسجيل الدخول كمسؤول", Color(0xFF3D6F5D), Colors.white, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AdminLoginScreen()),
                    );
                  }),
                  SizedBox(height: 70,),
                  MaterialButton(
                    height: 45,
                    minWidth: 200,
                    shape: OutlineInputBorder(borderRadius: BorderRadius.circular(20),borderSide: BorderSide(color:Color(0xFF3D6F5D) )),
                    color: Color(0xFF3D6F5D),
                      child: Text("الدخول كضيف",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 16),),
                    onPressed: (){
                _loginAsGuest(context);
                  }),
                  // TextButton(
                  //   onPressed: () {
                  //     // Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignUpScreen(email: email, name: name, uid: uid),));
                  //   },
                  //   child: const Text(
                  //     "ليس لديك حساب؟ سجل الآن",
                  //     style: TextStyle(color: Color(0xFF3D6F5D), fontWeight: FontWeight.bold),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor, VoidCallback onTap, {IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      label: Text(text, style: TextStyle(color: textColor, fontSize: 16,fontWeight: FontWeight.bold)),
      icon: icon != null ? Icon(icon, color: textColor) : const SizedBox.shrink(),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

