import 'package:flutter/material.dart';
import '../../common/color_extension.dart';

class EditProfileView extends StatefulWidget {
  final String name;
  final String email;
  final String avatarPath;
  const EditProfileView({super.key, required this.name, required this.email, required this.avatarPath});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String avatarPath = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    avatarPath = widget.avatarPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.gray,
      appBar: AppBar(
        backgroundColor: TColor.gray,
        elevation: 0,
        title: Text('Edit Profile', style: TextStyle(color: TColor.primaryText)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: Implement avatar picker
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(avatarPath),
                child: Icon(Icons.edit, color: Colors.white70, size: 28),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: TColor.gray60,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: TColor.gray60,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              ),
              onPressed: () {
                // TODO: Save profile changes
                Navigator.pop(context, {
                  'name': _nameController.text.trim(),
                  'email': _emailController.text.trim(),
                  'avatarPath': avatarPath,
                });
              },
              child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
