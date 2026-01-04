import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
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
                child: widget.userPhotoUrl != null
                    ? CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(widget.userPhotoUrl!),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green.shade800,
                      ),
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
          Text(
            widget.userName,
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
      children: [
        // Full Name
        _buildProfileItem(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: widget.userName,
        ),
        const SizedBox(height: 16),
        
        // Email
        _buildProfileItem(
          icon: Icons.email_outlined,
          label: 'Email / Phone',
          value: widget.userEmail,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFarmInfoContent() {
    return Column(
      children: [
        // Farm Location
        _buildProfileItem(
          icon: Icons.location_on_outlined,
          label: 'Farm Location',
          value: widget.farmLocation!,
          isEditable: true,
        ),
        const SizedBox(height: 16),
        // Farm Size
        _buildProfileItem(
          icon: Icons.landscape_outlined,
          label: 'Farm Size',
          value: '5 Acres',
          isEditable: true,
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
                        userName: widget.userName,
                        userEmail: widget.userEmail,
                        userPhotoUrl: widget.userPhotoUrl,
                      ),
                    ),
                  );
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