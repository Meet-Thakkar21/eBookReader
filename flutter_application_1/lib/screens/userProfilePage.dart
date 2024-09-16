import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Models/User.dart';
import '../../Services/userServices.dart';  // Adjust the path as needed

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;  // File to store selected image

  // Method to pick and upload image
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);  // Set the selected image
        });

        // Upload to Firebase Storage and get the URL
        String? imageUrl = await uploadProfileImage(userModel.uid, _profileImage!);
        if (imageUrl != null) {
          // Update user model with the new profile image URL
          userModel.profileImageUrl = imageUrl;
          await _updateUserData();
        }
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  // Method to remove profile picture and set default
  Future<void> _removeProfileImage() async {
    setState(() {
      _profileImage = null;
      userModel.profileImageUrl = null;  // Reset profile image URL
    });

    await _updateUserData();  // Update the user data in Firestore
  }

  late UserModel userModel;
  bool _isEditing = false;

  // Text controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        setState(() {
          userModel = UserModel.fromMap(snapshot.data()!, snapshot.id);
          // Initialize controllers with the current data
          _nameController.text = userModel.name;
          _emailController.text = userModel.email;
          _selectedGender = userModel.gender ?? '';
          _dobController.text = userModel.dob ?? '';
        });
      }
    } catch (e) {
      // Handle errors here, e.g., show an error message
    }
  }

  Future<void> _updateUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userModel.name = _nameController.text;
        // Email remains unchanged and is not updated
        userModel.gender = _selectedGender;
        userModel.dob = _dobController.text;

        await updateUser(userModel);

        setState(() {
          _isEditing = false;
        });

        // Optionally, fetch the updated user data
        _fetchUserData();
      }
    } catch (e) {
      // Handle errors here, e.g., show an error message
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.blueGrey[600],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 12.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 50.0,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)  // If image selected
                          : (userModel.profileImageUrl != null
                          ? NetworkImage(userModel.profileImageUrl!) // If image URL exists
                          : AssetImage('assets/sub_assets/p1.jpg')) // Default placeholder
                      as ImageProvider,
                    ),
                    SizedBox(height: 10.0),

                    // Conditionally display Profile Picture Buttons when editing
                    if (_isEditing) ...[
                      if (userModel.profileImageUrl == null)
                        ElevatedButton.icon(
                          onPressed: _pickAndUploadImage,
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          label: Text('Set Profile Picture', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            backgroundColor: Colors.blueGrey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      if (userModel.profileImageUrl != null)
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickAndUploadImage,
                              icon: Icon(Icons.camera_alt, color: Colors.white),
                              label: Text('Set Another Profile', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                backgroundColor: Colors.blueGrey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            ElevatedButton.icon(
                              onPressed: _removeProfileImage,
                              icon: Icon(Icons.delete, color: Colors.white),
                              label: Text('Remove Profile', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                backgroundColor: Colors.red[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],

                    SizedBox(height: 20.0),

                    // User Name
                    _buildField(
                      controller: _nameController,
                      label: 'Name',
                      isEditable: _isEditing,
                    ),
                    SizedBox(height: 10.0),

                    // Conditionally show Email field only when not editing
                    if (!_isEditing)
                      Column(
                        children: [
                          _buildField(
                            controller: _emailController,
                            label: 'Email',
                            isEditable: false, // Disable editing for the email field
                          ),
                          SizedBox(height: 10.0),
                        ],
                      ),

                    // User Gender
                    _buildField(
                      label: 'Gender',
                      isEditable: _isEditing,
                      text: _selectedGender ?? 'Not specified',
                      isDropdown: true,
                      dropdownItems: ['Male', 'Female', 'Other'],
                      selectedValue: _selectedGender,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 10.0),

                    // User DOB (Date Picker)
                    _buildField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      isEditable: _isEditing,
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(height: 30.0),

                    // Toggle between Edit and Save mode
                    ElevatedButton.icon(
                      onPressed: _isEditing ? _updateUserData : () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                      label: Text(_isEditing ? 'Save Profile' : 'Update Profile', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        backgroundColor: Colors.blueGrey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    TextEditingController? controller,
    required String label,
    required bool isEditable,
    bool isDropdown = false,
    List<String>? dropdownItems,
    String? selectedValue,
    Function(String?)? onChanged,
    GestureTapCallback? onTap,
    String? text,
  }) {
    if (isDropdown) {
      return isEditable
          ? DropdownButtonFormField<String>(
        value: selectedValue,
        items: dropdownItems!.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        style: TextStyle(
          fontSize: 18.0,
          color: Colors.blueGrey[600],
        ),
      )
          : Row(
        children: [
          Expanded(child: Text('$label: ${text ?? 'Not specified'}', style: TextStyle(fontSize: 18.0, color: Colors.blueGrey[600]))),
        ],
      );
    }

    return isEditable
        ? TextFormField(
      controller: controller,
      enabled: isEditable,
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      style: TextStyle(
        fontSize: 18.0,
        color: Colors.blueGrey[600],
      ),
    )
        : Row(
      children: [
        Expanded(child: Text('$label: ${controller?.text ?? text ?? 'Not specified'}', style: TextStyle(fontSize: 18.0, color: Colors.blueGrey[600]))),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}
