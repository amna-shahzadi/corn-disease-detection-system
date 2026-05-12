import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import 'detect_disease_screen.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../config/api_config.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRearCamera = true;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  FlashMode _flashMode = FlashMode.off; // Track actual flash mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission().then((granted) {
        if (granted) {
          _initializeCamera();
        }
      });
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Start with back camera by default
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      // Set flash to OFF by default after initialization
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isFlashOn = false; // Ensure flash state is false initially
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }
    
    final result = await Permission.camera.request();
    if (result.isGranted) return true;
    
    if (result.isPermanentlyDenied) {
      _showPermissionDialog();
    }
    return false;
  }

  void _showPermissionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.cameraNoPermission),
        content: Text(l10n.cameraNoPermission),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(l10n.dashboardSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    
    try {
      // Don't change flash mode during capture - let it work as set
      final XFile image = await _controller!.takePicture();
      
      if (image != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (image != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;

    setState(() => _isRearCamera = !_isRearCamera);
    
    final newCamera = _isRearCamera
        ? _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back)
        : _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    
    // Maintain flash mode when flipping camera
    await _controller!.setFlashMode(_flashMode);
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      // Cycle through: OFF → AUTO → ON → OFF...
      FlashMode newMode;
      bool newIsFlashOn;
      
      if (_flashMode == FlashMode.off) {
        newMode = FlashMode.auto;
        newIsFlashOn = false; // AUTO is not "on" in UI
      } else if (_flashMode == FlashMode.auto) {
        newMode = FlashMode.always;
        newIsFlashOn = true;
      } else {
        newMode = FlashMode.off;
        newIsFlashOn = false;
      }
      
      await _controller!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
        _isFlashOn = newIsFlashOn;
      });
    } catch (e) {
      _showError('Failed to toggle flash: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  Color _getFlashIconColor() {
    switch (_flashMode) {
      case FlashMode.off:
        return Colors.white;
      case FlashMode.auto:
        return Colors.orange;
      case FlashMode.always:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen camera preview - fills entire screen
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(
                _controller!,
                child: Container(),
              ),
            ),
          
          // Black background for uninitialized state
          if (!_isInitialized)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          
          // Top bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    // Flash button
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _getFlashIcon(),
                          color: _getFlashIconColor(),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom controls - properly positioned at bottom with spacing
          Positioned(
            left: 0,
            right: 0,
            bottom: 30, // Added 30px spacing from bottom edge
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery button
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // White loading overlay (only visible when capturing)
                          if (_isCapturing)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Flip camera button
                  GestureDetector(
                    onTap: _flipCamera,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Image Preview Screen
class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({super.key, required this.imagePath});
  
  final String imagePath;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isProcessing = false;
  
  void _retakePhoto() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  Future<void> _analyzeImage() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      
      if (bytes.isEmpty) {
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
      
      // Get current user ID to save prediction to history
      final userId = await AuthSession.getBackendUserId();
      
      // Retry logic for network issues
      DetectDiseaseResponse? result;
      int maxRetries = 3;
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('DEBUG: API attempt $attempt of $maxRetries');
          
          result = await ApiService.detectDiseaseFromBytes(
            bytes, 
            filename, 
            userId: userId,
          );
          
          // If we get here, the call was successful
          break;
          
        } catch (e) {
          print('DEBUG: Attempt $attempt failed: $e');
          
          if (attempt == maxRetries) {
            // Last attempt failed, rethrow the error
            rethrow;
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }

      if (!mounted) return;
      
      if (result == null) {
        throw Exception('No response received from server');
      }
      
      // Navigate to DetectDiseaseScreen with the response data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetectDiseaseScreen(
            capturedImagePath: widget.imagePath,
            initialResponse: result,
          ),
        ),
      );
      
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      
      // Provide more user-friendly error messages
      String errorMessage = 'Detection failed';
      if (e.toString().contains('connection was aborted') || 
          e.toString().contains('incomplete envelope')) {
        errorMessage = 'Network connection unstable. Please check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('No response received')) {
        errorMessage = 'Server is not responding. Please try again later.';
      } else {
        errorMessage = 'Detection failed: ${e.toString()}';
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen image preview
          Positioned.fill(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Retake button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _retakePhoto,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.cameraRetake,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Analyze button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isProcessing ? Colors.grey[600] : const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : _analyzeImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isProcessing)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isProcessing ? AppLocalizations.of(context)!.cameraAnalyzing : AppLocalizations.of(context)!.cameraAnalyze,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
