import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class DetectDiseaseScreen extends StatefulWidget {
  const DetectDiseaseScreen({super.key});

  @override
  State<DetectDiseaseScreen> createState() => _DetectDiseaseScreenState();
}

class _DetectDiseaseScreenState extends State<DetectDiseaseScreen> {
  /// Image bytes for display and API (works on mobile and web)
  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _diseaseResult;
  String? _confidenceLevel;
  DetectDiseaseResponse? _detectionResponse;
  double? _originalImageWidth;
  double? _originalImageHeight;

  final ImagePicker _picker = ImagePicker();

  bool get _hasImage => _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
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
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _diseaseResult = null;
          _confidenceLevel = null;
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  void _detectDisease() async {
    if (!_hasImage) {
      _showError('Please select an image first');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = _selectedImageBytes;
      if (bytes == null || bytes.isEmpty) {
        _showError('Could not read image data');
        return;
      }
      
      // Debug: Print image info
      print('DEBUG: Image bytes length: ${bytes.length}');
      print('DEBUG: Image bytes type: ${bytes.runtimeType}');
      
      // Simple format detection
      String filename = 'image.jpg';
      if (bytes.length >= 4) {
        // PNG signature: 89 50 4E 47
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && 
            bytes[2] == 0x4E && bytes[3] == 0x47) {
          filename = 'image.png';
          print('DEBUG: Detected PNG format');
        }
        // JPEG signature: FF D8 FF
        else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
          filename = 'image.jpg';
          print('DEBUG: Detected JPEG format');
        }
      }
      
      print('DEBUG: Using filename: $filename');
      print('DEBUG: Sending to endpoint: ${ApiConfig.detectPath}');
      
      final result = await ApiService.detectDiseaseFromBytes(bytes, filename);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _detectionResponse = result;
        _diseaseResult = result.diseaseName ?? result.message ?? 'Unknown';
        _confidenceLevel = result.confidence != null
            ? (result.confidence!.endsWith('%') ? result.confidence : '${result.confidence}%')
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Detection failed: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _diseaseResult = null;
      _confidenceLevel = null;
      _detectionResponse = null;
      _originalImageWidth = null;
      _originalImageHeight = null;
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

              // Image with Bounding Boxes - Professional Responsive Display
              if (_hasImage)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive image size based on screen width
                      double imageSize = constraints.maxWidth > 600 
                          ? 400 
                          : constraints.maxWidth * 0.9;
                      
                      return Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Original Image with professional styling
                              Container(
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                ),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.contain,
                                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                    // Get image dimensions when frame is available
                                    if (frame != null && _originalImageWidth == null) {
                                      final codec = ui.instantiateImageCodec(_selectedImageBytes!);
                                      codec.then((codec) {
                                        codec.getNextFrame().then((frame) {
                                          if (mounted) {
                                            setState(() {
                                              _originalImageWidth = frame.image.width.toDouble();
                                              _originalImageHeight = frame.image.height.toDouble();
                                            });
                                          }
                                        });
                                      });
                                    }
                                    return child;
                                  },
                                ),
                              ),
                              
                              // Bounding Boxes Overlay with proper scaling
                              if (_detectionResponse?.detections != null && _originalImageWidth != null)
                                ..._detectionResponse!.detections!.map(
                                  (detection) => _buildScaledBoundingBox(detection, imageSize, imageSize),
                                ).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Image Placeholder when no image selected
              if (!_hasImage)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildImageSourceSheet(),
                    );
                  },
                  child: Container(
                    width: 350,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
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
                            'Tap to capture or upload image',
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
                  ),
                ),

              const SizedBox(height: 30),

              // Action Buttons (only show when no detection yet)
              if (_detectionResponse == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Capture Button with Icon
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
                    
                    // Upload Button with Icon
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

              // Detect Disease Button (only show when no detection yet)
              if (_detectionResponse == null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasImage ? _detectDisease : null,
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
                ),

              const SizedBox(height: 30),

              // Results Section with Professional Responsive Layout
              if (_detectionResponse != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Header - Responsive
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 27, 94, 32),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row - Responsive
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                  size: MediaQuery.of(context).size.width > 600 ? 32 : 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Detection Analysis',
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: MediaQuery.of(context).size.width > 600 ? 20 : 16),
                            
                            // Summary Stats - Responsive Layout
                            MediaQuery.of(context).size.width > 600
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Detections',
                                          '${_detectionResponse!.totalDetections ?? 0}',
                                          Icons.search,
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Primary Disease',
                                          _diseaseResult ?? 'None',
                                          Icons.bug_report,
                                          Colors.orange,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildStatCard(
                                        'Total Detections',
                                        '${_detectionResponse!.totalDetections ?? 0}',
                                        Icons.search,
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildStatCard(
                                        'Primary Disease',
                                        _diseaseResult ?? 'None',
                                        Icons.bug_report,
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 20),
                      
                      // Individual Detection Cards - Responsive
                      if (_detectionResponse!.detections != null && _detectionResponse!.detections!.isNotEmpty)
                        ..._detectionResponse!.detections!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final detection = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.width > 600 ? 16 : 12),
                            child: _buildDetailedDetectionCard(detection, index + 1),
                          );
                        }).toList(),
                      
                      // Recommendations - Responsive
                      if (_diseaseResult != null)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: MediaQuery.of(context).size.width > 600 ? 24 : 20),
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 20),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Color.fromARGB(255, 27, 94, 32),
                                    size: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Recommendations',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 27, 94, 32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),
                              Text(
                                _getRecommendedAction(_diseaseResult!),
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Action Buttons After Detection - Responsive
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width > 600 ? 24 : 20),
                        child: MediaQuery.of(context).size.width > 600
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _clearImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('New Analysis'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showError('Save functionality coming soon!');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromARGB(255, 27, 94, 32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save Results'),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _clearImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('New Analysis'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showError('Save functionality coming soon!');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromARGB(255, 27, 94, 32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save Results'),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaledBoundingBox(DiseaseDetection detection, double displayWidth, double displayHeight) {
    if (detection.bbox == null || detection.bbox!.length < 4 ||
        _originalImageWidth == null || _originalImageHeight == null) {
      print('DEBUG: Skipping detection - missing bbox or dimensions');
      return const SizedBox.shrink();
    }

    // Calculate aspect ratio and actual image display area
    final imageAspectRatio = _originalImageWidth! / _originalImageHeight!;
    final containerAspectRatio = displayWidth / displayHeight;
    
    double actualDisplayWidth, actualDisplayHeight, offsetX, offsetY;
    
    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider than container - fits width, has vertical padding
      actualDisplayWidth = displayWidth;
      actualDisplayHeight = displayWidth / imageAspectRatio;
      offsetX = 0;
      offsetY = (displayHeight - actualDisplayHeight) / 2;
    } else {
      // Image is taller than container - fits height, has horizontal padding
      actualDisplayWidth = displayHeight * imageAspectRatio;
      actualDisplayHeight = displayHeight;
      offsetX = (displayWidth - actualDisplayWidth) / 2;
      offsetY = 0;
    }

    // Calculate scaling factors based on actual display area
    final scaleX = actualDisplayWidth / _originalImageWidth!;
    final scaleY = actualDisplayHeight / _originalImageHeight!;

    // Scale bounding box coordinates
    final scaledX = detection.bbox![0] * scaleX + offsetX;
    final scaledY = detection.bbox![1] * scaleY + offsetY;
    final scaledWidth = (detection.bbox![2] - detection.bbox![0]) * scaleX;
    final scaledHeight = (detection.bbox![3] - detection.bbox![1]) * scaleY;

    // Debug logging for each detection
    print('DEBUG: Detection: ${detection.disease}');
    print('DEBUG: Original bbox: [${detection.bbox![0]}, ${detection.bbox![1]}, ${detection.bbox![2]}, ${detection.bbox![3]}]');
    print('DEBUG: Image dimensions: ${_originalImageWidth}x${_originalImageHeight}');
    print('DEBUG: Display area: ${actualDisplayWidth}x${actualDisplayHeight}');
    print('DEBUG: Offsets: X=$offsetX, Y=$offsetY');
    print('DEBUG: Scale factors: X=$scaleX, Y=$scaleY');
    print('DEBUG: Scaled position: X=$scaledX, Y=$scaledY');
    print('DEBUG: Scaled size: ${scaledWidth}x${scaledHeight}');
    print('---');

    // Get color from API or default to red
    Color boxColor = Colors.red;
    if (detection.color != null && detection.color!.length >= 3) {
      boxColor = Color.fromARGB(
        255,
        detection.color![0],
        detection.color![1],
        detection.color![2],
      );
    }

    // Create abbreviated disease name for box
    String abbreviatedName = _getAbbreviatedDiseaseName(detection.disease ?? 'Unknown');

    return Positioned(
      top: scaledY,
      left: scaledX,
      child: Container(
        width: scaledWidth,
        height: scaledHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: boxColor,
            width: 2,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$abbreviatedName (${(detection.confidence! * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalBoundingBox(DiseaseDetection detection) {
    if (detection.bbox == null || detection.bbox!.length < 4) {
      print('DEBUG: Skipping detection - missing bbox');
      return const SizedBox.shrink();
    }

    // Use original API coordinates directly (no scaling)
    final x = detection.bbox![0];
    final y = detection.bbox![1];
    final width = detection.bbox![2] - detection.bbox![0];
    final height = detection.bbox![3] - detection.bbox![1];

    // Debug logging for each detection
    print('DEBUG: Detection: ${detection.disease}');
    print('DEBUG: Original bbox: [${detection.bbox![0]}, ${detection.bbox![1]}, ${detection.bbox![2]}, ${detection.bbox![3]}]');
    print('DEBUG: Image dimensions: ${_originalImageWidth}x${_originalImageHeight}');
    print('DEBUG: Using original coordinates - no scaling');
    print('DEBUG: Box position: X=$x, Y=$y');
    print('DEBUG: Box size: ${width}x${height}');
    print('---');

    // Get color from API or default to red
    Color boxColor = Colors.red;
    if (detection.color != null && detection.color!.length >= 3) {
      boxColor = Color.fromARGB(
        255,
        detection.color![0],
        detection.color![1],
        detection.color![2],
      );
    }

    // Create abbreviated disease name for box
    String abbreviatedName = _getAbbreviatedDiseaseName(detection.disease ?? 'Unknown');

    return Positioned(
      top: y,
      left: x,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: boxColor,
            width: 2,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$abbreviatedName (${(detection.confidence! * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAbbreviatedDiseaseName(String diseaseName) {
    switch (diseaseName.toLowerCase()) {
      case 'fusarium ear rot':
        return 'FER';
      case 'grey leaf spot':
        return 'GLS';
      case 'northern leaf blight':
        return 'NLB';
      case 'common rust':
        return 'RUST';
      case 'healthy corn':
        return 'HLTH';
      default:
        // For unknown diseases, use first 3 letters in uppercase
        if (diseaseName.length >= 3) {
          return diseaseName.substring(0, 3).toUpperCase();
        } else {
          return diseaseName.toUpperCase();
        }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedDetectionCard(DiseaseDetection detection, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: detection.color != null 
                      ? Color.fromARGB(
                          255, 
                          detection.color![0], 
                          detection.color![1], 
                          detection.color![2],
                        )
                      : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detection.disease ?? 'Unknown Disease',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 27, 94, 32),
                  ),
                ),
              ),
              Text(
                detection.confidence != null 
                    ? '${(detection.confidence! * 100).toStringAsFixed(1)}%'
                    : 'N/A',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: detection.confidence != null && detection.confidence! > 0.5
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
          if (detection.bbox != null && detection.bbox!.length >= 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.crop_free, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Location: (${detection.bbox![0].toStringAsFixed(0)}, ${detection.bbox![1].toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
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