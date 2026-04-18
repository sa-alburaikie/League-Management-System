import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hadramootleagues/supabase_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TeamProfileScreen extends StatefulWidget {
  final String teamId;

  const TeamProfileScreen({required this.teamId, super.key});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  bool _isEditing = false;
  Map<String, dynamic>? teamData;
  bool _isLoading = true;
  dynamic _selectedImage;
  bool isLoadingImage = false;
  String? errorMessage;

  late TextEditingController _teamNameController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _dateController;
  late TextEditingController _playerNumberController;
  late TextEditingController _mainColorController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    _dateController = TextEditingController();
    _playerNumberController = TextEditingController();
    _mainColorController = TextEditingController();
    _emailController = TextEditingController();
    _fetchTeamData();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _playerNumberController.dispose();
    _mainColorController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (doc.exists) {
        setState(() {
          teamData = doc.data() as Map<String, dynamic>;
          _teamNameController.text = teamData?['teamname'] ?? '';
          _locationController.text = teamData?['location'] ?? '';
          _phoneController.text = teamData?['phone'] ?? '';
          _dateController.text = teamData?['date'] ?? '';
          _playerNumberController.text = teamData?['playernumber']?.toString() ?? '';
          _mainColorController.text = teamData?['maincolor'] ?? '';
          _emailController.text = teamData?['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching team data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      isLoadingImage = true;
      errorMessage = null;
    });

    try {
      final String? imageUrl = await SupabaseUtils.uploadImage(
        _selectedImage,
        'team_${widget.teamId}',
      );

      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .update({'imageUrl': imageUrl});

        setState(() {
          teamData?['imageUrl'] = imageUrl;
          _selectedImage = null;
          isLoadingImage = false;
        });
      } else {
        setState(() {
          isLoadingImage = false;
          errorMessage = 'Failed to upload image to Supabase';
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        isLoadingImage = false;
        errorMessage = 'Error uploading image: $e';
      });
      print('Error uploading image: $e');
      print('StackTrace: $stackTrace');
    }
  }

  Future<void> _updateTeamData() async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
        'teamname': _teamNameController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'date': _dateController.text,
        'playernumber': _playerNumberController.text,
        'maincolor': _mainColorController.text,
        'email': _emailController.text,
      });
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      print('Error updating team data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء التحديث')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        isLoadingImage = true;
        errorMessage = null;
      });

      if (kIsWeb) {
        _selectedImage = await pickedFile.readAsBytes();
      } else {
        _selectedImage = File(pickedFile.path);
      }
      await _uploadImage();
      setState(() {});
    }
  }

  // دالة لعرض الصورة المكبرة
  void _showEnlargedImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: teamData?['imageUrl'] != null
                    ? Image.network(
                  teamData!['imageUrl'],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 50,
                  ),
                )
                    : Image.asset(
                  "images/logoofleage.jpg",
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D6F5D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "صفحة الفريق",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildInfoTile(
              "العنوان",
              _locationController.text,
              Icons.location_on,
              _isEditing ? _locationController : null,
            ),
            _buildInfoTile(
              "رقم التواصل",
              _phoneController.text,
              Icons.phone,
              _isEditing ? _phoneController : null,
            ),
            _buildInfoTile(
              "تاريخ التأسيس",
              _dateController.text,
              Icons.calendar_today,
              _isEditing ? _dateController : null,
            ),
            _buildInfoTile(
              "عدد اللاعبين",
              _playerNumberController.text,
              Icons.numbers,
              _isEditing ? _playerNumberController : null,
            ),
            _buildInfoTile(
              "اللون الرسمي",
              _mainColorController.text,
              Icons.star_border,
              _isEditing ? _mainColorController : null,
            ),
            _buildInfoTile(
              "الجيميل",
              _emailController.text,
              Icons.email,
              _isEditing ? _emailController : null,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  if (_isEditing) {
                    _updateTeamData();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D6F5D),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isEditing ? "حفظ" : "تحديث البروفايل",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _showEnlargedImage, // تكبير الصورة عند النقر
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: teamData?['imageUrl'] != null
                        ? NetworkImage(teamData!['imageUrl'])
                        : const AssetImage("images/logoofleage.jpg") as ImageProvider,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D6F5D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isEditing
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _teamNameController,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          )
              : Text(
            _teamNameController.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon,
      [TextEditingController? controller]) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black54),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 5),
                    controller != null
                        ? TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    )
                        : Text(value, style: const TextStyle(color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.black26, height: 1),
        ),
      ],
    );
  }
}