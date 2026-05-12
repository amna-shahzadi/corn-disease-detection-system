import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'package:corn_disease_app/main.dart';
// ── Supported languages ────────────────────────────────────────────────────
const List<String> kSupportedLanguages = [
  'English',
  'اردو (Urdu)',
  'Punjabi',
  'Hindi',
  'Arabic',
];

// ─── ProfileScreen ───────────────────────────────────────────────────────────
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

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isAccountInfoExpanded = false;
  bool _isFarmInfoExpanded = false;
  bool _isAppSettingsExpanded = false;

  UserProfile? _userProfile;
  bool _profileLoading = false;
  Uint8List? _profileImageBytes;
  bool _isLoadingProfileImage = false;

  // Stats state variables
  int _totalScans = 0;
  int _diseasesDetected = 0;
  String _lastScanDate = 'Never';
  bool _statsLoaded = false;

  String _language = 'English';

  late AnimationController _headerController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerController.forward();

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadProfile();
      _loadStats();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize language based on current locale after context is available
    _initializeLanguage();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (widget.userId == null) return;
    setState(() => _profileLoading = true);

    final hasPhotoUrl =
        widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty;
    if (hasPhotoUrl) setState(() => _isLoadingProfileImage = true);

    try {
      final profile = await ApiService.getUserProfile(widget.userId!);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _profileLoading = false;
        });

        if (profile.profilePicture != null &&
            profile.profilePicture!.isNotEmpty) {
          try {
            final imageBytes =
                await ApiService.getProfileImageBytes(widget.userId!);
            if (mounted) {
              setState(() {
                _profileImageBytes = imageBytes;
                _isLoadingProfileImage = false;
              });
            }
          } catch (_) {
            if (mounted) setState(() => _isLoadingProfileImage = false);
          }
        } else {
          if (mounted) setState(() => _isLoadingProfileImage = false);
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileLoading = false;
          _isLoadingProfileImage = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    if (widget.userId == null) return;
    
    try {
      final d = await ApiService.getHistoryWithCount(userId: widget.userId!);
      if (!mounted) return;
      
      setState(() {
        _totalScans = d['count'] ?? 0;
        final list = d['data'] as List<dynamic>?;
        
        // Count diseases detected
        _diseasesDetected = 0;
        if (list != null && list.isNotEmpty) {
          for (final item in list) {
            final scan = item as Map<String, dynamic>;
            final diseaseName = scan['disease_name'] as String?;
            if (diseaseName != null && diseaseName.isNotEmpty && diseaseName.toLowerCase() != 'healthy') {
              _diseasesDetected++;
            }
          }
          
          // Get last scan date
          final lastScan = list.first as Map<String, dynamic>;
          final time = lastScan['time'] as String?;
          final date = lastScan['date'] as String?;
          if (time != null && date != null) {
            try {
              final dt = DateTime.parse('${date}T${time}:00');
              final now = DateTime.now();
              if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
                _lastScanDate = AppLocalizations.of(context)!.dashboardToday;
              } else {
                final l10n = AppLocalizations.of(context)!;
                final m = [
                  l10n.dashboardJanuary, l10n.dashboardFebruary, l10n.dashboardMarch,
                  l10n.dashboardApril, l10n.dashboardMay, l10n.dashboardJune,
                  l10n.dashboardJuly, l10n.dashboardAugust, l10n.dashboardSeptember,
                  l10n.dashboardOctober, l10n.dashboardNovember, l10n.dashboardDecember
                ];
                _lastScanDate = '${m[dt.month - 1]} ${dt.day}';
              }
            } catch (_) {
              _lastScanDate = 'Unknown';
            }
          }
        }
        
        _statsLoaded = true;
      });
    } catch (e) {
      debugPrint('Profile stats error: $e');
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsLoaded = false;
      _totalScans = 0;
      _diseasesDetected = 0;
      _lastScanDate = 'Never';
    });
    await _loadStats();
  }

  String get _displayName => _userProfile?.username ?? widget.userName;
  String get _displayEmail => _userProfile?.email ?? widget.userEmail;
  Uint8List? get _displayPhotoBytes => _profileImageBytes;

  String? get _displayPhotoUrl {
    final url = _userProfile?.profilePicture ?? widget.userPhotoUrl;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('/app/media/')
        ? url.replaceFirst('/app/media/', '/media/')
        : url;
  }

  String? get _displayLocation =>
      _userProfile?.location ?? widget.farmLocation;
  String? get _displayPhone => _userProfile?.phoneNumber ?? widget.userPhone;

  Widget _buildAvatar(double radius) {
    const avatarColors = [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF43A047),
      Color(0xFF4CAF50),
      Color(0xFF66BB6A),
    ];
    final name = _displayName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';
    final color = avatarColors[name.hashCode.abs() % avatarColors.length];

    if (_isLoadingProfileImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.2),
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }
    if (_displayPhotoBytes != null) {
      return CircleAvatar(
          radius: radius, backgroundImage: MemoryImage(_displayPhotoBytes!));
    }
    if (_displayPhotoUrl != null && _displayPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(
          _displayPhotoUrl!,
        ),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle network errors gracefully
          print('Profile image load error: $exception');
        },
        backgroundColor: color.withOpacity(0.15),
        child: _displayPhotoUrl != null && _displayPhotoUrl!.isNotEmpty
            ? null
            : Text(
                initial,
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFade,
              child: _buildHeader(isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStatsRow(isDark),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: AppLocalizations.of(context)!.profileAccountInfo,
                    subtitle: AppLocalizations.of(context)!.profileAccountInfoSubtitle,
                    icon: Icons.person_outline_rounded,
                    isExpanded: _isAccountInfoExpanded,
                    onTap: () => setState(() =>
                        _isAccountInfoExpanded = !_isAccountInfoExpanded),
                    content: _buildAccountContent(isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: AppLocalizations.of(context)!.profileFarmInfo,
                    subtitle: AppLocalizations.of(context)!.profileFarmInfoSubtitle,
                    icon: Icons.grass_rounded,
                    isExpanded: _isFarmInfoExpanded,
                    onTap: () => setState(
                        () => _isFarmInfoExpanded = !_isFarmInfoExpanded),
                    content: _buildFarmContent(isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: AppLocalizations.of(context)!.profileAppSettings,
                    subtitle: AppLocalizations.of(context)!.profileAppSettingsSubtitle,
                    icon: Icons.tune_rounded,
                    isExpanded: _isAppSettingsExpanded,
                    onTap: () => setState(() =>
                        _isAppSettingsExpanded = !_isAppSettingsExpanded),
                    content: _buildAppSettingsContent(isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B3A1F), const Color(0xFF0D2410)]
              : [const Color(0xFF1B5E20), const Color(0xFF123C15)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 3),
                    ),
                  ),
                  _profileLoading
                      ? const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : _buildAvatar(50),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _profileLoading
                  ? _shimmer(140, 22)
                  : Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
              const SizedBox(height: 6),
              _profileLoading
                  ? _shimmer(180, 14)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _displayEmail,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
              if (_displayLocation != null &&
                  _displayLocation!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.white.withOpacity(0.65)),
                    const SizedBox(width: 4),
                    Text(
                      _displayLocation!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    if (!_statsLoaded) {
      return Row(
        children: [
          _statCard(
              icon: Icons.image_search_rounded,
              value: '—',
              label: AppLocalizations.of(context)!.profileStatsScanned,
              color: const Color(0xFF1B5E20),
              isDark: isDark),
          const SizedBox(width: 10),
          _statCard(
              icon: Icons.bug_report_outlined,
              value: '—',
              label: AppLocalizations.of(context)!.profileStatsDiseases,
              color: const Color(0xFFE65100),
              isDark: isDark),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.calendar_today_rounded,
            value: '—',
            label: AppLocalizations.of(context)!.profileStatsLastScan,
            color: const Color(0xFF1565C0),
            isDark: isDark,
            compact: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        _statCard(
            icon: Icons.image_search_rounded,
            value: '$_totalScans',
            label: AppLocalizations.of(context)!.profileStatsScanned,
            color: const Color(0xFF1B5E20),
            isDark: isDark),
        const SizedBox(width: 10),
        _statCard(
            icon: Icons.bug_report_outlined,
            value: '$_diseasesDetected',
            label: AppLocalizations.of(context)!.profileStatsDiseases,
            color: const Color(0xFFE65100),
            isDark: isDark),
        const SizedBox(width: 10),
        _statCard(
          icon: Icons.calendar_today_rounded,
          value: _lastScanDate == 'Never'
              ? '—'
              : _lastScanDate,
          label: AppLocalizations.of(context)!.profileStatsLastScan,
          color: const Color(0xFF1565C0),
          isDark: isDark,
          compact: true,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    bool compact = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2B1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.07))
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 13 : 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.07))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        size: 20, color: const Color(0xFF1B5E20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: content,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountContent(bool isDark) => Column(
        children: [
          _infoRow(
              icon: Icons.person_outline_rounded,
              label: AppLocalizations.of(context)!.profileFullName,
              value: _displayName,
              isDark: isDark),
          _divider(isDark),
          _infoRow(
              icon: Icons.mail_outline_rounded,
              label: AppLocalizations.of(context)!.loginEmail,
              value: _displayEmail,
              isDark: isDark),
          _divider(isDark),
          _infoRow(
            icon: Icons.phone_outlined,
            label: AppLocalizations.of(context)!.profilePhoneLabel,
            value: (_displayPhone != null && _displayPhone!.isNotEmpty)
                ? _displayPhone!
                : AppLocalizations.of(context)!.profileNotSet,
            isDark: isDark,
            isPlaceholder:
                _displayPhone == null || _displayPhone!.isEmpty,
          ),
        ],
      );

  Widget _buildFarmContent(bool isDark) => _infoRow(
        icon: Icons.location_on_outlined,
        label: AppLocalizations.of(context)!.profileLocationLabel,
        value: (_displayLocation != null && _displayLocation!.isNotEmpty)
            ? _displayLocation!
            : AppLocalizations.of(context)!.profileNotSet,
        isDark: isDark,
        isPlaceholder:
            _displayLocation == null || _displayLocation!.isEmpty,
      );

  Widget _buildAppSettingsContent(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsLabel(l10n.settingsLanguage, Icons.language_rounded, isDark),
        const SizedBox(height: 10),
        _buildLanguagePicker(isDark),
      ],
    );
  }

  Widget _settingsLabel(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagePicker(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1A0D)
            : const Color(0xFFF8F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade300,
        ),
      ),
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<String>(
          value: _language,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.grey.shade600,
          ),
          underline: const SizedBox(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
          items: [
            DropdownMenuItem(
              value: 'English',
              child: Text(l10n.profileEnglish),
            ),
            DropdownMenuItem(
              value: 'اردو (Urdu)',
              child: Text(l10n.profileUrdu),
            ),
          ],
          onChanged: (lang) {
            if (lang == null) return;
            setState(() => _language = lang);
            _changeLanguage(lang);
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    userName: _displayName,
                    userEmail: _displayEmail,
                    userPhone: _displayPhone,
                    userPhotoUrl: _displayPhotoUrl,
                    userId: widget.userId,
                  ),
                ),
              );
              if (updated != null && mounted) {
                widget.onRefresh();
                _refreshStats();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(AppLocalizations.of(context)!.profileEditProfileButton),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showSignOutDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              side: BorderSide(
                  color: const Color(0xFFD32F2F).withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.profileSignOutButton,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profileSignOutTitle),
        content: Text(AppLocalizations.of(context)!.profileSignOutMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.commonCancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.profileSignOutButton),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isPlaceholder = false,
  }) {
    return Container(
      color: isDark ? const Color(0xFF2B2B2B) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPlaceholder
                        ? (isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.shade400)
                        : (isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A)),
                    fontStyle: isPlaceholder
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
          ),
        ),
    );
  }

  Widget _divider(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.shade100,
        ),
      );

 void _initializeLanguage() {
    final currentLocale = Localizations.localeOf(context);
    if (currentLocale.languageCode == 'ur') {
      setState(() {
        _language = 'اردو (Urdu)';
      });
    } else {
      setState(() {
        _language = 'English';
      });
    }
  }

  Future<void> _changeLanguage(String language) async {
  String languageCode = 'en';
  if (language.contains('اردو') || language.contains('Urdu')) {
    languageCode = 'ur';
  }
  
  CornDiseaseApp.setLocale(context, Locale(languageCode));
}

  Widget _shimmer(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}