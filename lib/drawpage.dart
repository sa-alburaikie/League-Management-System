import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class DrawPage extends StatefulWidget {
  final String leagueId;
  final VoidCallback? onDrawCompleted;

  const DrawPage({Key? key, required this.leagueId, this.onDrawCompleted}) : super(key: key);

  @override
  _DrawPageState createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> selectedMatchDays = [];
  int? selectedMatchesPerDay;
  List<String> selectedMatchTimes = [];

  String leagueType = '';
  String matchType = '';
  String drawType = '';

  bool isLoading = true;

  final List<String> daysOfWeek = [
    'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];
  final List<int> matchesPerDayOptions = [1, 2, 3, 4, 5, 6];
  final List<String> matchTimeOptions = [
    '8 إلى 10 صباحاً',
    '10 إلى 12 صباحاً',
    '4 إلى 6 مساءً',
    '6 إلى 8 مساءً',
    '8 إلى 10 مساءً'
  ];

  @override
  void initState() {
    super.initState();
    _loadLeagueSettings();
  }

  Future<void> _loadLeagueSettings() async {
    var doc = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
    setState(() {
      leagueType = doc['leagueType'] ?? '';
      matchType = doc['matchType'] ?? 'مباراة واحدة';
      drawType = leagueType == 'الدوري الكامل'
          ? 'قرعة شاملة'
          : leagueType == 'دور المجموعات + أدوار اقصائية'
          ? 'قرعة دور المجموعات'
          : 'قرعة مواجهات مباشرة';
      isLoading = false;
    });
  }

  Future<void> _executeDraw() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      // تحديث إعدادات الدوري
      await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).update({
        'matchDays': selectedMatchDays,
        'matchesPerDay': selectedMatchesPerDay,
        'matchTimes': selectedMatchTimes,
        'drawCompleted': true,
      });

      var leagueDoc = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
      List<String> teams = List.from(leagueDoc['selectedTeams']);
      teams.shuffle(); // خلط الفرق للقرعة العشوائية

      if (leagueType == 'الدوري الكامل') {
        await _drawFullLeague(teams);
      } else if (leagueType == 'دور المجموعات + أدوار اقصائية') {
        await _drawGroupsAndKnockout(teams);
      } else if (leagueType == 'دوري المواجهات المباشرة' || leagueType == 'دور المواجهات المباشرة') {
        await _drawKnockoutLeague(teams);
      }

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت القرعة بنجاح!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      if (widget.onDrawCompleted != null) widget.onDrawCompleted!();
    }
  }

  Future<void> _drawFullLeague(List<String> teams) async {
    List<Map<String, dynamic>> matches = [];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add({
          'team1': teams[i],
          'team2': teams[j],
          'result': '',
          'goals1': 0,
          'goals2': 0,
          'leagueId': widget.leagueId,
        });
        if (matchType == 'ذهاب وإياب') {
          matches.add({
            'team1': teams[j],
            'team2': teams[i],
            'result': '',
            'goals1': 0,
            'goals2': 0,
            'leagueId': widget.leagueId,
          });
        }
      }
    }
    await _distributeMatchesOnDaysAndTimes(matches);
  }

  Future<void> _drawGroupsAndKnockout(List<String> teams) async {
    // تقسيم الفرق إلى مجموعات
    int groupSize = 4;
    List<List<String>> groups = [];
    for (int i = 0; i < teams.length; i += groupSize) {
      groups.add(teams.sublist(i, i + groupSize > teams.length ? teams.length : i + groupSize));
    }
    // إنشاء مباريات دور المجموعات
    List<Map<String, dynamic>> groupMatches = [];
    for (int g = 0; g < groups.length; g++) {
      var group = groups[g];
      String groupName = String.fromCharCode(65 + g); // A, B, C...
      for (int i = 0; i < group.length; i++) {
        for (int j = i + 1; j < group.length; j++) {
          groupMatches.add({
            'team1': group[i],
            'team2': group[j],
            'result': '',
            'goals1': 0,
            'goals2': 0,
            'leagueId': widget.leagueId,
            'roundId': 'group_$groupName',
          });
          if (matchType == 'ذهاب وإياب') {
            groupMatches.add({
              'team1': group[j],
              'team2': group[i],
              'result': '',
              'goals1': 0,
              'goals2': 0,
              'leagueId': widget.leagueId,
              'roundId': 'group_$groupName',
            });
          }
        }
      }
      // حفظ المجموعة في rounds
      await FirebaseFirestore.instance.collection('rounds').doc('group_$groupName').set({
        'leagueId': widget.leagueId,
        'type': 'group',
        'groupName': groupName,
        'teams': group,
      });
    }
    await _distributeMatchesOnDaysAndTimes(groupMatches);
  }

  Future<void> _drawKnockoutLeague(List<String> teams) async {
    // التأكد من أن عدد الفرق قوة 2 (مثل 8، 16)
    int targetSize = pow(2, (log(teams.length) / log(2)).ceil()).toInt();
    while (teams.length < targetSize) teams.add('فريق وهمي'); // إضافة فرق وهمية إذا لزم الأمر

    List<Map<String, dynamic>> matches = [];
    for (int i = 0; i < teams.length; i += 2) {
      matches.add({
        'team1': teams[i],
        'team2': teams[i + 1],
        'result': '',
        'goals1': 0,
        'goals2': 0,
        'leagueId': widget.leagueId,
        'roundId': 'round_1_${i ~/ 2}',
      });
      if (matchType == 'ذهاب وإياب') {
        matches.add({
          'team1': teams[i + 1],
          'team2': teams[i],
          'result': '',
          'goals1': 0,
          'goals2': 0,
          'leagueId': widget.leagueId,
          'roundId': 'round_1_${i ~/ 2}',
        });
      }
    }
    await FirebaseFirestore.instance.collection('rounds').doc('round_1').set({
      'leagueId': widget.leagueId,
      'type': 'knockout',
      'roundNumber': 1,
      'teams': teams,
    });
    await _distributeMatchesOnDaysAndTimes(matches);
  }

  Future<void> _distributeMatchesOnDaysAndTimes(List<Map<String, dynamic>> matches) async {
    Map<String, int> dayToInt = {
      'الأحد': DateTime.sunday,
      'الإثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
    };

    int matchesPerDay = selectedMatchesPerDay ?? 1;
    int matchIndex = 0;

    DateTime startDate = DateTime.now();
    for (int dayIndex = 0; matchIndex < matches.length; dayIndex++) {
      String day = selectedMatchDays[dayIndex % selectedMatchDays.length];
      int weekday = dayToInt[day]!;
      DateTime matchDate = startDate.add(Duration(days: (weekday - startDate.weekday + 7) % 7 + dayIndex ~/ selectedMatchDays.length * 7));

      for (int i = 0; i < matchesPerDay && matchIndex < matches.length; i++) {
        String time = selectedMatchTimes[matchIndex % selectedMatchTimes.length];
        List<String> timeRange = time.split(' إلى ');
        int startHour = int.parse(timeRange[0].split(':')[0]);
        if (time.contains('مساء') && startHour < 12) startHour += 12;

        DateTime matchTime = DateTime(matchDate.year, matchDate.month, matchDate.day, startHour);
        matches[matchIndex]['matchDate'] = matchTime;
        await FirebaseFirestore.instance.collection('matches').add(matches[matchIndex]);
        matchIndex++;
      }
    }
  }
  Widget _buildMultipleTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('وقت المباريات'),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: matchTimeOptions.map((time) {
            return FilterChip(
              label: Text(time),
              selected: selectedMatchTimes.contains(time),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) selectedMatchTimes.add(time);
                  else selectedMatchTimes.remove(time);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultipleDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('أيام المباريات'),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: daysOfWeek.map((day) {
            return FilterChip(
              label: Text(day),
              selected: selectedMatchDays.contains(day),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) selectedMatchDays.add(day);
                  else selectedMatchDays.remove(day);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String label,
    required Function(T?) onChanged,
    required String? Function(T?) validator,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        value: value,
        hint: Text(hint),
        items: items.map((T valueItem) {
          return DropdownMenuItem<T>(value: valueItem, child: Text(valueItem.toString()));
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _executeDraw,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF3D6F5D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
            'إجراء القرعة',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContextContext) {
    if (isLoading && leagueType.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3D6F5D),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('صفحة الدوري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3D6F5D),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('صفحة الدوري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMultipleDaysSelector(),
                SizedBox(height: 14),
                _buildLabel('عدد المباريات في اليوم'),
                _buildDropdown<int>(
                  hint: 'اختر العدد',
                  value: selectedMatchesPerDay,
                  items: matchesPerDayOptions,
                  label: 'العدد',
                  onChanged: (value) => setState(() => selectedMatchesPerDay = value),
                  validator: (value) => value == null ? "الرجاء اختيار عدد المباريات" : null,
                ),
                SizedBox(height: 14),
                _buildMultipleTimeSelector(),
                SizedBox(height: 14),
                _buildLabel('نوع القرعة'),
                _buildReadOnlyField('النوع', drawType),
                SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      height: 45,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.centerLeft,
      child: Text(value, style: TextStyle(fontSize: 16, color: Colors.black87)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 14, color: Colors.black87)),
    );
  }
}