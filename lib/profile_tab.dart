import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  File? _image;
  final String _imagePathKey = 'profile_image_path';
  final String _nameKey = 'profile_name';
  final String _emailKey = 'profile_email';

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load the saved image, name, and email from SharedPreferences.
  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load image
    String? savedImagePath = prefs.getString(_imagePathKey);
    if (savedImagePath != null) {
      File imageFile = File(savedImagePath);
      if (await imageFile.exists()) {
        setState(() {
          _image = imageFile;
        });
      }
    }

    // Load name and email
    _nameController.text = prefs.getString(_nameKey) ?? '';
    _emailController.text = prefs.getString(_emailKey) ?? '';
  }

  // Function to open the camera and capture an image.
  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to save the profile image, name, and email.
  Future<void> _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save name and email
    await prefs.setString(_nameKey, _nameController.text);
    await prefs.setString(_emailKey, _emailController.text);

    if (_image != null) {
      try {
        if (!_image!.existsSync()) {
          print('Temporary image file does not exist at: ${_image!.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Temporary image file not found')),
          );
          return;
        }

        // Get the app's documents directory.
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_image!.path)}';
        final String newPath = path.join(appDir.path, fileName);

        // Copy the image file.
        final File savedImage = await _image!.copy(newPath);
        print('Profile image successfully saved at: ${savedImage.path}');

        // Store the new file path
        await prefs.setString(_imagePathKey, savedImage.path);
      } catch (e) {
        print('Error saving image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image')),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : AssetImage('assets/placeholder.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
