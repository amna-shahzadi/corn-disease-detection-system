import 'dart:async';
import 'package:flutter/material.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import './login_screen.dart';
import './history_screen.dart'; // Add this import
import './profile_screen.dart'; // Add this import
import './detect_disease_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.showLoginSuccess = false});

  final bool showLoginSuccess;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = 'Farmer';
  String _userEmail = '';
  String? _userPhotoUrl;
  String? _userId;
  String? _userPhone;
  String? _userLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final backendLoggedIn = await AuthSession.isBackendLoggedIn();
    final backendEmail = await AuthSession.getBackendEmail();
    final backendUsername = await AuthSession.getBackendUsername();
    final backendUserId = await AuthSession.getBackendUserId();
    final backendPhone = await AuthSession.getBackendPhoneNumber();
    final backendLocation = await AuthSession.getBackendLocation();
    final backendProfilePicture = await AuthSession.getBackendProfilePicture();

    setState(() {
      if (backendLoggedIn) {
        _userName = backendUsername?.isNotEmpty == true ? backendUsername! : 'Farmer';
        _userEmail = backendEmail ?? '';
        _userPhotoUrl = backendProfilePicture;
        _userId = backendUserId;
        _userPhone = backendPhone;
        _userLocation = backendLocation;
        _isLoading = false;
      } else {
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        });
      }
    });
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  /// Tips and news with optional location (null = show to all).
  /// `location` should be a short region tag like "Punjab", "Multan", etc.
  static const List<Map<String, String?>> _allTips = [
    {'type': 'Tip', 'title': 'Rotate crops annually', 'description': 'Rotating crops helps prevent soil depletion and reduces pest buildup.', 'location': null},
    {'type': 'News', 'title': 'New pest resistant corn', 'description': 'Scientists have developed a new corn variety resistant to common pests.', 'location': null},
    {'type': 'Notification', 'title': 'Harvest season coming!', 'description': 'Prepare your equipment for the upcoming harvest season.', 'location': null},
    {'type': 'Tip', 'title': 'Punjab: Optimal maize sowing window', 'description': 'In Punjab, mid-Feb to March is ideal for spring maize. Avoid late sowing to reduce pest pressure.', 'location': 'Punjab'},
    {'type': 'News', 'title': 'Multan corn yield trials', 'description': 'High-yield corn trials in Multan region show 15% improvement with new irrigation schedule.', 'location': 'Multan'},
    {'type': 'Tip', 'title': 'Lahore area: Soil testing', 'description': 'Get your soil tested before kharif in Lahore division for better fertilizer use.', 'location': 'Lahore'},
    {'type': 'Notification', 'title': 'Faisalabad mandi rates', 'description': 'Corn prices in Faisalabad mandi are stable. Good time to plan harvest sales.', 'location': 'Faisalabad'},
    {'type': 'Tip', 'title': 'Sahiwal: Water management', 'description': 'In Sahiwal region, use drip irrigation for maize to save water and improve yield.', 'location': 'Sahiwal'},
    {'type': 'News', 'title': 'Bahawalpur seed subsidy', 'description': 'Government seed subsidy for cotton and maize available for Bahawalpur farmers.', 'location': 'Bahawalpur'},
  ];

  /// Tips that apply to any farmer (no specific location).
  List<Map<String, String?>> get _globalTips {
    return _allTips.where((t) {
      final tipLoc = t['location'];
      return tipLoc == null || tipLoc.trim().isEmpty;
    }).toList();
  }

  /// Tips that match the user's selected location from Edit Profile.
  /// Matches if the saved location string contains the tip's `location` tag.
  List<Map<String, String?>> get _locationSpecificTips {
    final loc = _userLocation?.trim().toLowerCase() ?? '';
    return _allTips.where((t) {
      final tipLoc = t['location']?.trim().toLowerCase();
      if (tipLoc == null || tipLoc.isEmpty) return false;
      if (loc.isEmpty) return false;
      return loc.contains(tipLoc);
    }).toList();
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon with App Theme
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  size: 40,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Message
              Text(
                'Are you sure you want to Sign out?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Column(
                children: [
                  // Sign Out Button (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Cancel Button (Secondary)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade700,
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

    if (confirmed == true) {
      await AuthSession.clearBackendSession();

      // Navigate to login screen and remove all other screens
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false, // Remove all routes
      );
    }
  }

void _onCameraTap() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const DetectDiseaseScreen(),
    ),
  );
}
  // Build different content based on selected tab
  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0: // Home Tab
        return _buildHomeContent();
      case 1: // History Tab
        return HistoryScreen(
          userName: _userName,
          userEmail: _userEmail,
          userPhotoUrl: _userPhotoUrl,
          userId: _userId,
        );
      case 2: // Profile Tab
        return ProfileScreen(
          userName: _userName,
          userEmail: _userEmail,
          userPhotoUrl: _userPhotoUrl,
          userId: _userId,
          userPhone: _userPhone,
          onSignOut: _handleSignOut,
          onRefresh: _refreshUserData,
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section (moved here from top bar)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading ? 'Welcome...' : 'Welcome, $_userName!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              if (_userEmail.isNotEmpty && !_isLoading)
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // Circular Corn Disease Detection Section
        GestureDetector(
          onTap: _onCameraTap,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green[900],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.green[900],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 36,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'DETECT CORN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'DISEASE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Stats Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Scans',
                  value: '0',
                  icon: Icons.photo_camera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Last Scan',
                  value: 'Never',
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Agricultural Tips & News Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Agricultural Tips & News',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.green[800],
                        size: 20,
                      ),
                      onPressed: _refreshUserData,
                    ),
                ],
              ),
              if (_userLocation != null && _userLocation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'For: $_userLocation',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 15),

              // When no location is set, show only global tips.
              if (_userLocation == null || _userLocation!.isEmpty) ...[
                if (_globalTips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tips available yet. Please try again later.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                else
                  ..._globalTips.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTipCard(
                          type: t['type']!,
                          title: t['title']!,
                          description: t['description']!,
                          location: null,
                        ),
                      )),
              ]
              // When location is set, show ONLY location-specific tips.
              else ...[
                if (_locationSpecificTips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tips available yet for your selected location.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                else ...[
                  Text(
                    'For your area',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._locationSpecificTips.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTipCard(
                          type: t['type']!,
                          title: t['title']!,
                          description: t['description']!,
                          location: t['location'],
                        ),
                      )),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Logo
            SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Colors.green[800],
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Corn Disease Detector',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.green[900],
              ),
              onSelected: (value) {
                if (value == 'refresh') {
                  _refreshUserData();
                } else if (value == 'profile') {
                  setState(() {
                    _selectedIndex = 2;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh Data'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Go to Profile'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildTabContent(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.green[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(
              icon: Icons.home,
              label: 'Home',
              index: 0,
            ),
            _buildNavButton(
              icon: Icons.history,
              label: 'History',
              index: 1,
            ),
            _buildNavButton(
              icon: Icons.person,
              label: 'Profile',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for bottom navigation buttons
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isActive = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            border: isActive
                ? const Border(
                    top: BorderSide(
                      color: Colors.white,
                      width: 3.0,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for stat cards
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green[800], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for tip/news cards
  Widget _buildTipCard({
    required String type,
    required String title,
    required String description,
    String? location,
  }) {
    Color typeColor = Colors.grey;
    Color bgColor = Colors.grey[100]!;

    if (type == 'Tip') {
      typeColor = Colors.orange[700]!;
      bgColor = Colors.orange[50]!;
    } else if (type == 'News') {
      typeColor = Colors.blue[700]!;
      bgColor = Colors.blue[50]!;
    } else if (type == 'Notification') {
      typeColor = Colors.red[700]!;
      bgColor = Colors.red[50]!;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (location != null && location.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}