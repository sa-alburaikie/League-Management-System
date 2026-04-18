import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hadramootleagues/supabase_utils.dart';
import 'package:image_picker/image_picker.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String userId;
  const PlayerProfileScreen({required this.userId, super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool isEditing = false;
  bool isLoadingImage = false;
  bool isLoadingData = true;
  Map<String, dynamic> playerData = {};
  String? imageUrl;
  TextEditingController nameController = TextEditingController();
  TextEditingController positionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController clubController = TextEditingController();
  TextEditingController nationalityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await fetchNameFromUsers();
    await fetchPlayerData();
  }

  Future<void> fetchNameFromUsers() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final userData = doc.data() as Map<String, dynamic>;
      nameController.text = userData['name'] ?? '';
    }
  }

  Future<void> fetchPlayerData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('players').doc(widget.userId).get();
    if (doc.exists) {
      setState(() {
        playerData = doc.data() as Map<String, dynamic>;
        positionController.text = playerData['position'] ?? '';
        locationController.text = playerData['location'] ?? '';
        phoneController.text = playerData['phone'] ?? '';
        birthDateController.text = playerData['birthDate'] ?? '';
        numberController.text = playerData['number'] ?? '';
        clubController.text = playerData['club'] ?? '';
        nationalityController.text = playerData['nationality'] ?? '';
        imageUrl = playerData['imageUrl'];
        isLoadingData = false;
      });
    }
  }

  Future<void> pickImage() async {
    dynamic imageData;
    String? errorMessage;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        isLoadingImage = true;
        errorMessage = null;
      });

      if (kIsWeb) {
        imageData = await pickedFile.readAsBytes();
      } else {
        imageData = File(pickedFile.path);
      }

      final String? downloadUrl = await SupabaseUtils.uploadImage(imageData, widget.userId);

      if (downloadUrl != null) {
        setState(() {
          imageUrl = downloadUrl;
          isLoadingImage = false;
        });

        try {
          await FirebaseFirestore.instance.collection('players').doc(widget.userId).update({
            'imageUrl': downloadUrl,
          });
        } catch (e) {
          setState(() {
            errorMessage = 'Error saving URL to Firestore: $e';
          });
        }
      } else {
        setState(() {
          isLoadingImage = false;
          errorMessage = 'Failed to upload image to Supabase';
        });
      }
    }
  }

  Future<void> saveData() async {
    await FirebaseFirestore.instance.collection('players').doc(widget.userId).set({
      'name': nameController.text,
      'position': positionController.text,
      'location': locationController.text,
      'phone': phoneController.text,
      'birthDate': birthDateController.text,
      'number': numberController.text,
      'club': clubController.text,
      'nationality': nationalityController.text,
      'imageUrl': imageUrl,
    });

    setState(() {
      isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("تم حفظ البروفايل بنجاح"),
        backgroundColor: const Color(0xFF3D6F5D),
        duration: const Duration(seconds: 2),
      ),
    );
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
                child: imageUrl != null
                    ? Image.network(
                  imageUrl!,
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
                    : const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 100,
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
        title: const Text(
          "صفحة اللاعب",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoadingData
          ? Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF3D6F5D),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _showEnlargedImage, // تكبير الصورة عند النقر
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                        child: imageUrl == null
                            ? const Icon(Icons.person, size: 45, color: Colors.grey)
                            : null,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D6F5D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: isLoadingImage
                          ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            isEditing
                ? Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "اسم اللاعب",
                    border: UnderlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: "المركز",
                    border: UnderlineInputBorder(),
                  ),
                ),
              ],
            )
                : Column(
              children: [
                Text(
                  nameController.text.isNotEmpty ? nameController.text : "اسم اللاعب",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  positionController.text.isNotEmpty ? positionController.text : "المركز",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  infoTile(Icons.location_on, "الموقع", locationController),
                  divider(),
                  infoTile(Icons.phone, "رقم الهاتف", phoneController),
                  divider(),
                  infoTile(Icons.calendar_today, "تاريخ الميلاد", birthDateController),
                  divider(),
                  infoTile(Icons.numbers, "رقم القميص", numberController),
                  divider(),
                  infoTile(Icons.sports_soccer, "النادي", clubController),
                  divider(),
                  infoTile(Icons.directions_run, "الجنسية", nationalityController),
                  divider(),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D6F5D),
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  if (isEditing) {
                    saveData();
                  } else {
                    setState(() {
                      isEditing = true;
                    });
                  }
                },
                child: Text(
                  isEditing ? "حفظ" : "تحديث البروفايل",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget infoTile(IconData icon, String label, TextEditingController controller) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: label == "النادي"
              ? Text(
            controller.text.isNotEmpty ? controller.text : "لم يتم تحديد $label",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          )
              : isEditing
              ? TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "أدخل $label",
              border: InputBorder.none,
            ),
          )
              : Text(
            controller.text.isNotEmpty ? controller.text : "لم يتم تحديد $label",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget divider() {
    return Divider(
      color: Colors.grey[300],
      thickness: 1,
      height: 20,
    );
  }
}