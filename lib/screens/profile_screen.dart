import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String? userId;
  final String? userPhone;
  final VoidCallback onSignOut;
  final VoidCallback onRefresh;
  final String? farmLocation;
  final int imagesScanned;
  final int diseasesDetected;
  final String lastScanDate;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.userId,
    this.userPhone,
    required this.onSignOut,
    required this.onRefresh,
    this.farmLocation = 'Multan, Punjab',
    this.imagesScanned = 0,
    this.diseasesDetected = 0,
    this.lastScanDate = 'Never',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAccountInfoExpanded = false;
  bool _isFarmInfoExpanded = false;
  UserProfile? _userProfile;
  bool _profileLoading = false;
  Uint8List? _profileImageBytes;
  bool _isLoadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (widget.userId == null) return;
    setState(() => _profileLoading = true);
    
    // Check if we have a photo URL to determine if we need to show image loading
    final hasPhotoUrl = widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty;
    if (hasPhotoUrl) {
      setState(() => _isLoadingProfileImage = true);
    }
    
    try {
      final profile = await ApiService.getUserProfile(widget.userId!);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _profileLoading = false;
        });
        
        // Try to fetch profile image bytes to bypass CORS
        if (profile.profilePicture != null && profile.profilePicture!.isNotEmpty) {
          print('DEBUG: Attempting to fetch profile image bytes...');
          try {
            final imageBytes = await ApiService.getProfileImageBytes(widget.userId!);
            print('DEBUG: Image bytes fetch result: ${imageBytes != null ? "SUCCESS (${imageBytes!.length} bytes)" : "FAILED"}');
            if (mounted) {
              setState(() {
                _profileImageBytes = imageBytes;
                _isLoadingProfileImage = false;
              });
            }
          } catch (e) {
            print('DEBUG: Image bytes fetch error: $e');
            // If image fetch fails, keep using network image fallback
            if (mounted) {
              setState(() => _isLoadingProfileImage = false);
            }
          }
        } else {
          print('DEBUG: No profile picture URL found');
          if (mounted) {
            setState(() => _isLoadingProfileImage = false);
          }
        }
        
        await AuthSession.setBackendLoggedIn(
          email: profile.email ?? widget.userEmail,
          username: profile.username,
          userId: profile.userId,
          phoneNumber: profile.phoneNumber,
          location: profile.location,
          profilePicture: profile.profilePicture,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileLoading = false;
          _isLoadingProfileImage = false;
        });
      }
    }
  }

  String get _displayName => _userProfile?.username ?? widget.userName;
  String get _displayEmail => _userProfile?.email ?? widget.userEmail;
  Uint8List? get _displayPhotoBytes => _profileImageBytes;
  String? get _displayPhotoUrl {
    final url = _userProfile?.profilePicture ?? widget.userPhotoUrl;
    print('DEBUG: Raw profile picture URL: $url');
    if (url == null || url.isEmpty) return null;
    
    // Remove /app prefix if present - Django serves static files from /media, not /app/media
    final correctedUrl = url.startsWith('/app/media/') 
        ? url.replaceFirst('/app/media/', '/media/') 
        : url;
    print('DEBUG: Corrected profile picture URL: $correctedUrl');
    return correctedUrl;
  }
  String? get _displayLocation => _userProfile?.location ?? widget.farmLocation;
  String? get _displayPhone => _userProfile?.phoneNumber ?? widget.userPhone;

  /// Builds a fallback avatar with user's initial and a pseudo-random background color.
  Widget _buildInitialAvatar(double radius) {
    final name = _displayName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';
    const colors = [
      Color(0xFF1B5E20), // dark green
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF43A047),
      Color(0xFF558B2F),
      Color(0xFF6A1B9A),
      Color(0xFF1565C0),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Header (Always Visible)
              _buildProfileHeader(context),
              
              const SizedBox(height: 20),

              // Expandable Account Information Section
              _buildExpandableSection(
                title: 'Account Information',
                subtitle: 'Tap to view account details',
                isExpanded: _isAccountInfoExpanded,
                onTap: () {
                  setState(() {
                    _isAccountInfoExpanded = !_isAccountInfoExpanded;
                  });
                },
                icon: Icons.account_circle_outlined,
                iconColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50,
                content: _buildAccountInfoContent(),
              ),

              const SizedBox(height: 20),

              // Expandable Farm Information Section
              _buildExpandableSection(
                title: 'Farm Information',
                subtitle: 'Tap to view farm details',
                isExpanded: _isFarmInfoExpanded,
                onTap: () {
                  setState(() {
                    _isFarmInfoExpanded = !_isFarmInfoExpanded;
                  });
                },
                icon: Icons.agriculture_outlined,
                iconColor:Colors.green.shade700,
                backgroundColor:Colors.green.shade50,
                content: _buildFarmInfoContent(),
              ),

              const SizedBox(height: 20),

             
              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(context),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: _profileLoading
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      )
                    : _isLoadingProfileImage
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : (_displayPhotoBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  _displayPhotoBytes!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_displayPhotoUrl != null && _displayPhotoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _displayPhotoUrl!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildInitialAvatar(48);
                                      },
                                    ),
                                  )
                                : _buildInitialAvatar(48))),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profileLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              _displayName,
              style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsed Header
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileItem(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: _displayName,
        ),
        const SizedBox(height: 16),
        _buildProfileItem(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _displayEmail,
        ),
        const SizedBox(height: 16),
        _buildProfileItem(
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          value: (_displayPhone != null && _displayPhone!.isNotEmpty)
              ? _displayPhone!
              : 'Not set',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFarmInfoContent() {
    return Column(
      children: [
        _buildProfileItem(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: _displayLocation ?? 'Not set',
          
        ),
        const SizedBox(height: 16),
      ],
    );
  }

 
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        userName: _displayName,
                        userEmail: _displayEmail,
                        userPhotoUrl: _displayPhotoUrl,
                        userId: widget.userId,
                        userPhone: _displayPhone,
                        farmLocation: _displayLocation ?? widget.farmLocation,
                      ),
                    ),
                  ).then((result) {
                    if (result != null && mounted) {
                      widget.onRefresh();
                      _loadProfile();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),

        const SizedBox(height: 12),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onSignOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: Colors.red.shade300),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    bool isReadOnly = false,
    bool isEditable = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isReadOnly ? Colors.grey.shade100 : Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isReadOnly ? Colors.grey : Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isReadOnly ? Colors.grey.shade600 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isEditable)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade500,
          ),
      ],
    );
  }
}