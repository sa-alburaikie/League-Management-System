// import 'package:flutter/material.dart';
// import 'package:hadramootleagues/signup.dart';
//
// class LoginWithPhone extends StatefulWidget {
//   @override
//   State<LoginWithPhone> createState() => _LoginWithPhoneState();
// }
//
// class _LoginWithPhoneState extends State<LoginWithPhone> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Color(0xFF2F6D52),
//         centerTitle: true,
//         iconTheme: IconThemeData(color: Colors.white),
//         title: Text("تسجيل الدخول",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 40),
//             // عنوان الصفحة
//             Center(
//               child: Text(
//                 "تسجيل الدخول عبر الهاتف",
//                 style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[700]
//                 ),
//               ),
//             ),
//             SizedBox(height: 30),
//
//             _buildTextField(
//               hintText: "ادخل رقم الهاتف",
//               icon: Icons.phone_android,
//             ),
//             SizedBox(height: 30),
//
//             _buildTextField(
//               hintText: "ادخل كلمة السر",
//               icon: Icons.lock_outline,
//               isPassword: true,
//             ),
//             SizedBox(height: 90),
//             Row(
//               children: [
//                 Expanded(
//                   child: Align(
//                     alignment: Alignment.centerRight,
//                     child: Text(
//                       "نسيت كلمة السر",
//                       style: TextStyle(
//                           color: Color(0xFF2F6D52),
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 12),
//                 Text("تذكرني", style: TextStyle(fontSize: 14)),
//                 Checkbox(
//                   value: true,
//                   onChanged: (value) {},
//                   activeColor: Color(0xFF2F6D52),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//
//             SizedBox(
//               width: double.infinity,
//               height: 52,
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF2F6D52),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   "تسجيل الدخول",
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//
//             Center(
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignUpScreen(),));
//                 },
//                 child: Text(
//                   style: TextStyle(
//                       color: Color(0xFF2F6D52),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField({String? hintText, IconData? icon, bool isPassword = false}) {
//     return TextField(
//         obscureText: isPassword,
//         decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: TextStyle(color: Colors.black87, fontSize: 16),
//           prefixIcon: Icon(icon, color: Colors.black54),
//           suffixIcon: isPassword
//               ? Icon(Icons.visibility_off, color: Colors.black54)
//               : null,
//           filled: true,
//           fillColor: Colors.grey[200],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//         ),
//     );
//   }
// }