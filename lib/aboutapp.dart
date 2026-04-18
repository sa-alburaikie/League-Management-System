import 'package:flutter/material.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
          Color(0xFF3D6F5D), // اللون الأساسي
          // Color(0xFFF5F7F6), // خلفية فاتحة
        title: Text("حول التطبيق",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF3D6F5D), // اللون الأساسي
                Color(0xFFF5F7F6), // خلفية فاتحة
              ],
            ),
          ),
          child: SafeArea(
          child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
      // الجزء العلوي مع الأيقونة
      Container(
      margin: EdgeInsets.only(top: 40, bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'images/logoofleage.jpg', // مسار الصورة
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    ),
    // اسم النظام
    Text(
    'نظام إدارة دوريات كرة القدم بوادي حضرموت',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
    Shadow(
    color: Colors.black45,
    offset: Offset(2, 2),
    blurRadius: 5,
    ),
    ],
    ),
    textAlign: TextAlign.center,
    ),
    SizedBox(height: 20),
    // نبذة عن النظام
    _buildSection(
    title: 'نبذة عن النظام',
    content:
    'نظام إدارة دوريات كرة القدم بوادي حضرموت هو منصة متكاملة تهدف إلى تنظيم وتسهيل إدارة الدوريات الرياضية، حيث يوفر تجربة مستخدم سلسة وحديثة لمتابعة المباريات وإدارة الفرق واللاعبين بكفاءة عالية.',
    ),
    // صمم النظام لـ
    _buildSection(
    title: 'صُمم النظام لـ',
    content: 'وزارة الشباب والرياضة بوادي حضرموت',
    ),
    // المستفيدون من النظام
    _buildSection(
    title: 'المستفيدون من النظام',
    contentWidget: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    _buildBeneficiaryItem('وزارة الشباب والرياضة'),
    _buildBeneficiaryItem('اللاعبون'),
    _buildBeneficiaryItem('المدربون'),
    _buildBeneficiaryItem('الفرق'),
    _buildBeneficiaryItem('المستخدمون العاديون'),
    ],
    ),
    ),
    // مطورو النظام
    _buildSection(
    title: 'مطورو النظام',
    contentWidget: Column(
    children: [
    _buildDeveloperCard(
    name: 'سالم مبارك البريكي',
    description: 'مبرمج تطبيقات موبايل',
    ),
      _buildDeveloperCard(
        name: 'مهند محمد السياغي',
        description: 'مبرمج تطبيقات موبايل',
      ),
      _buildDeveloperCard(
        name: 'هاشم محمد طرشوم',
        description: 'مبرمج تطبيقات موبايل',
      ),
      _buildDeveloperCard(
        name: 'سالم عبدالله باحلوان',
        description: 'مبرمج تطبيقات موبايل',
      ),
    ],
    ),
    ),
            SizedBox(height: 40),
          ],
          ),
          ),
          ),
      ),
    );
  }

  // دالة لإنشاء قسم
  Widget _buildSection({
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3D6F5D).withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D6F5D),
            ),
          ),
          SizedBox(height: 10),
          if (content != null)
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          if (contentWidget != null) contentWidget,
        ],
      ),
    );
  }

  // دالة لعنصر المستفيدين
  Widget _buildBeneficiaryItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF3D6F5D),
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لكرت المطور
  Widget _buildDeveloperCard({required String name, required String description}) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    Color(0xFF3D6F5D),
    Color(0xFF5A8F7B),
    ],
    ),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
    BoxShadow(
    color: Colors.black26,
    blurRadius: 8,
    offset: Offset(0, 3),
    ),
    ],
    ),
    child: Row(
    children: [
    CircleAvatar(
    radius: 25,
    backgroundColor: Colors.white,
    child: Icon(
    Icons.code, // أيقونة تدل على المبرمجين
    size: 30,
    color: Color(0xFF3D6F5D),
    ),
    ),
    SizedBox(width: 15),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    name,
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
      SizedBox(height: 5),
      Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    ],
    ),
    ),
    ],
    ),
    );
  }
}