import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DetectDiseaseScreen extends StatefulWidget {
  const DetectDiseaseScreen({super.key});

  @override
  State<DetectDiseaseScreen> createState() => _DetectDiseaseScreenState();
}

class _DetectDiseaseScreenState extends State<DetectDiseaseScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String? _diseaseResult;
  String? _confidenceLevel;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _diseaseResult = null;
          _confidenceLevel = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _diseaseResult = null;
          _confidenceLevel = null;
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  void _detectDisease() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final mockDiseases = [
      {'name': 'Common Rust', 'confidence': '92%'},
      {'name': 'Northern Leaf Blight', 'confidence': '87%'},
      {'name': 'Gray Leaf Spot', 'confidence': '78%'},
      {'name': 'Healthy Corn', 'confidence': '95%'},
    ];

    final randomResult = mockDiseases[DateTime.now().millisecond % mockDiseases.length];

    setState(() {
      _isProcessing = false;
      _diseaseResult = randomResult['name'];
      _confidenceLevel = randomResult['confidence'];
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _diseaseResult = null;
      _confidenceLevel = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with Back Button
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Logo and Title Section in same row (matching screenshot)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bigger Logo like in screenshot
                    Container(
                      width: 60, // Increased from 40 to 60
                      height: 60, // Increased from 40 to 60
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.eco,
                              color: Colors.green[800],
                              size: 36, // Increased from 24 to 36
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Title and Subtitle Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISEASE DETECTION',
                            style: TextStyle(
                              fontSize: 20, // Slightly increased
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 27, 94, 32),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Corn Disease Detection',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Image Placeholder Section - Matches the screenshot
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildImageSourceSheet(),
                  );
                },
                child: Container(
                  width: 300,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Selected Image
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: 300,
                            height: 250,
                          ),
                        ),
                      
                      // Placeholder Content with square brackets
                      if (_selectedImage == null)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                ' Tap to capture or upload image',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Clear button when image is selected
                      if (_selectedImage != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _clearImage,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons (Capture and Upload) with Icons and square brackets
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Capture Button with Icon and square brackets
                  ElevatedButton.icon(
                    onPressed: _captureImageFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color.fromARGB(255, 27, 94, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 27, 94, 32),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 20,
                    ),
                    label: const Text(
                      'Capture',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // Upload Button with Icon and square brackets
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color.fromARGB(255, 27, 94, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 27, 94, 32),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.upload,
                      size: 20,
                    ),
                    label: const Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Detect Disease Button
              SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedImage != null ? _detectDisease : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 27, 94, 32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'DETECT DISEASE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                ),
              ),

              const SizedBox(height: 40),

              // Results Section
              if (_diseaseResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: Color.fromARGB(255, 27, 94, 32),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Detection Result',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 27, 94, 32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.bug_report, color: Colors.green, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Disease: $_diseaseResult',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.analytics, color: Colors.green, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Confidence: $_confidenceLevel',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            _getRecommendedAction(_diseaseResult!),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceSheet() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Image Source',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 27, 94, 32),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _captureImageFromCamera();
                    },
                    icon: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color.fromARGB(255, 27, 94, 32),
                        size: 35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    icon: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.blue,
                        size: 35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendedAction(String disease) {
    switch (disease) {
      case 'Common Rust':
        return 'Apply fungicide containing chlorothalonil or propiconazole. Remove severely infected leaves.';
      case 'Northern Leaf Blight':
        return 'Use resistant corn varieties. Apply fungicides early in the season. Practice crop rotation.';
      case 'Gray Leaf Spot':
        return 'Apply fungicide at first sign. Improve air circulation. Avoid overhead irrigation.';
      case 'Healthy Corn':
        return 'Corn appears healthy. Continue regular monitoring and maintain good agricultural practices.';
      default:
        return 'Consult with agricultural expert for specific treatment recommendations.';
    }
  }
}