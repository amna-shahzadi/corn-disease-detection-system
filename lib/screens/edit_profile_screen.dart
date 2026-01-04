import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String? farmLocation;

  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.farmLocation = 'Multan, Punjab',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _locationController;
  late TextEditingController _farmSizeController;
  
  File? _selectedImage;
  String _selectedDistrict = 'Multan';

  final ImagePicker _picker = ImagePicker();
  
  // List of Punjab districts (Pakistan)
  final List<String> _districts = [
    'Multan',
    'Lahore',
    'Faisalabad',
    'Rawalpindi',
    'Gujranwala',
    'Sahiwal',
    'Sargodha',
    'Bahawalpur',
    'Rahim Yar Khan',
    'Dera Ghazi Khan',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _passwordController = TextEditingController(text: '');
    _locationController = TextEditingController(text: widget.farmLocation);
    _farmSizeController = TextEditingController(text: '5 Acres');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  // Function to show image source options
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade300, height: 1),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade700,
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              Divider(color: Colors.grey.shade300, height: 1),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Colors.green.shade700,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              Divider(color: Colors.grey.shade300, height: 1),
              if (_selectedImage != null || widget.userPhotoUrl != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade700,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Function to pick image with better error handling
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        // Validate that the file exists before using it
        final file = File(pickedFile.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
        } else {
          _showSnackBar('Selected image file does not exist');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  void _saveChanges() {
    // Validate form
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }

    if (_locationController.text.isEmpty) {
      _showSnackBar('Please select farm location');
      return;
    }

    // Show success message
    _showSnackBar('Profile updated successfully!', isError: false);
    
    // Delay navigation to show success message
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context, {
        'name': _nameController.text,
        'location': _locationController.text,
        'farmSize': _farmSizeController.text,
        'image': _selectedImage,
      });
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your District',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: _districts.map((district) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: _selectedDistrict == district
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                      title: Text(
                        district,
                        style: TextStyle(
                          fontWeight: _selectedDistrict == district
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedDistrict == district
                              ? Colors.green.shade900
                              : Colors.black87,
                        ),
                      ),
                      trailing: _selectedDistrict == district
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedDistrict = district;
                          _locationController.text = '$district, Punjab';
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Safe image widget builder
  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      // Check if file exists and is valid
      return FutureBuilder<bool>(
        future: _selectedImage!.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: Image.file(
                _selectedImage!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If there's an error loading the image, show placeholder
                  return Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.green.shade800,
                  );
                },
              ),
            );
          } else {
            // File doesn't exist, show placeholder
            return Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade800,
            );
          }
        },
      );
    } else if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      // Show network image from URL
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(widget.userPhotoUrl!),
        backgroundColor: Colors.transparent,
      );
    } else {
      // Show default icon
      return Icon(
        Icons.person,
        size: 50,
        color: Colors.green.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.green.shade900,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: constraints.maxHeight > 600 ? 20 : 10,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture Section
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: _buildProfileImage(),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade900,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to change profile picture',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 12),
                      
                      // Full Name
                      _buildFormField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        hintText: 'Enter your full name',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email (Read-only)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email / Phone',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 49, 47, 47),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Farm Information Section
                      _buildSectionHeader('Farm Information'),
                      const SizedBox(height: 12),
                      
                      // Farm Location (District Picker)
                      GestureDetector(
                        onTap: _showDistrictPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color.fromARGB(255, 44, 44, 44)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Farm Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _locationController.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Farm Size
                      _buildFormField(
                        label: 'Farm Size',
                        icon: Icons.landscape_outlined,
                        controller: _farmSizeController,
                        hintText: 'e.g., 5 Acres or 2 Hectares',
                        keyboardType: TextInputType.number,
                      ),

                      const Spacer(),
                      
                      // Action Buttons
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Save All Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade900,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(
          icon,
          color: Colors.green.shade700,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
      ),
      style: const TextStyle(fontSize: 15),
      keyboardType: keyboardType,
    );
  }
}