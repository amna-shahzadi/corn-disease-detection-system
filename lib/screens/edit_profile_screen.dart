import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String? userId;
  final String? farmLocation;
  final String? userPhone;

  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.userId,
    this.farmLocation = 'Multan, Punjab',
    this.userPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  
  Uint8List? _selectedImageBytes;
  String _selectedDistrict = 'Multan';
  bool _isSaving = false;
  bool _removePhoto = false;
  Uint8List? _currentProfileImageBytes;
  bool _isLoadingProfileImage = true;

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
    _phoneController = TextEditingController(text: widget.userPhone ?? '');
    _locationController = TextEditingController(text: widget.farmLocation);
    
    // Load current profile image if user ID exists
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadCurrentProfileImage();
    }
  }

  Future<void> _loadCurrentProfileImage() async {
    if (widget.userId == null) return;
    
    try {
      // Try to fetch profile image bytes to bypass CORS (same as profile screen)
      if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
        try {
          final imageBytes = await ApiService.getProfileImageBytes(widget.userId!);
          if (mounted) {
            setState(() {
              _currentProfileImageBytes = imageBytes;
              _isLoadingProfileImage = false;
            });
          }
        } catch (e) {
          // If image fetch fails, keep using network image fallback
          print('Image bytes fetch error: $e');
          if (mounted) {
            setState(() {
              _isLoadingProfileImage = false;
            });
          }
        }
      } else {
        // No photo URL, set loading to false
        if (mounted) {
          setState(() {
            _isLoadingProfileImage = false;
          });
        }
      }
    } catch (e) {
      print('Profile image load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfileImage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
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
              if (_selectedImageBytes != null || widget.userPhotoUrl != null)
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
                      _selectedImageBytes = null;
                      _removePhoto = true;
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

  // Function to pick image (works on web and mobile - uses bytes, not File)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
            _removePhoto = false;
          });
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showSnackBar('Please enter farm location');
      return;
    }

    // Phone number is optional, no validation needed

    final userId = widget.userId;
    if (userId == null || userId.isEmpty) {
      _showSnackBar('Cannot update profile: user not identified');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final username = _nameController.text.trim();
      final location = _locationController.text.trim();

      // Always use multipart /users/edit/{user_id}/ so that phone_number and
      // location are updated consistently, with or without a new photo.
      await ApiService.updateUser(
        userId: userId,
        username: username,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        location: location,
        profilePictureBytes: _selectedImageBytes,
        removeProfilePicture: _removePhoto,
      );
      await AuthSession.setBackendLoggedIn(
        email: widget.userEmail,
        username: username,
        userId: userId,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (!mounted) return;
      _showSnackBar('Profile updated successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context, {
        'name': username,
        'location': location,
        'imageBytes': _selectedImageBytes,
      });
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatPhoneNumber(String value) {
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      return digitsOnly.substring(0, 11);
    }
    return digitsOnly;
  }

  void _onPhoneChanged(String value) {
    final formatted = _formatPhoneNumber(value);
    if (_phoneController.text != formatted) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
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

  // Safe image widget builder (uses bytes so it works on web)
  Widget _buildProfileImage() {
    // Show loading indicator while fetching the correct image
    if (_isLoadingProfileImage && widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      return const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      );
    }
    
    if (_selectedImageBytes != null && _selectedImageBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Image.memory(
          _selectedImageBytes!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade800,
            );
          },
        ),
      );
    } else if (_removePhoto) {
      // Explicitly removed by user: show default icon.
      return Icon(
        Icons.person,
        size: 50,
        color: Colors.green.shade800,
      );
    } else if (_currentProfileImageBytes != null && _currentProfileImageBytes!.isNotEmpty) {
      // Show current profile image from bytes (same as profile screen)
      return ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Image.memory(
          _currentProfileImageBytes!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade800,
            );
          },
        ),
      );
    } else if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      // Correct URL by removing /app prefix if present
      String correctedUrl = widget.userPhotoUrl!;
      if (correctedUrl.startsWith('/app/media/')) {
        correctedUrl = correctedUrl.replaceFirst('/app/media/', '/media/');
      }
      
      // Show network image from URL, with graceful fallback if it fails.
      return ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Image.network(
          correctedUrl,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade800,
            );
          },
        ),
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
            onPressed: _isSaving ? null : _saveChanges,
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
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
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
                      const SizedBox(height: 10),
                      Text(
                        'Tap to change profile picture',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 15),

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
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: 'Email address',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
  
                      // Phone Number
                      _buildFormField(
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        hintText: '03XXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        onChanged: _onPhoneChanged,
                      ),
                      
                      const SizedBox(height: 16),
                      

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
                            border: Border.all(color: Colors.grey.shade300),
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
                                      style:  TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _locationController.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 12, 12, 12),
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
                      
                    
                      const Spacer(),
                      
                      // Action Buttons
                      Column(
                        children: [
                          const SizedBox(height: 15),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
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
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Color.fromARGB(255, 12, 12, 12),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.green.shade700,
          size: 20,
        ),
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}