import 'dart:async';
import 'package:flutter/material.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'package:corn_disease_app/services/api_service.dart';
import './login_screen.dart';
import './history_screen.dart';
import './profile_screen.dart';
import './detect_disease_screen.dart';

// ─── Design tokens ───────────────────────────────────────────────────
class _AppColors {
  static const primary       = Color(0xFF1A4D1E);
  static const primaryLight  = Color(0xFF2E7D32);
  static const surface       = Color(0xFFF1F8E9);
  static const surfaceMid    = Color(0xFFE8F5E9);
  static const accent        = Color(0xFF81C784);
  static const textPrimary   = Color(0xFF1A4D1E);
  static const textSecondary = Color(0xFF666666);
  static const textMuted     = Color(0xFF9E9E9E);
  static const divider       = Color(0xFFE8F5E9);
}

// ─── Tips data ────────────────────────────────────────────────────────────────
enum _TipType { tip, news, notification }

class _TipItem {
  final _TipType type;
  final String title;
  final String description;
  final String? location;
  const _TipItem(this.type, this.title, this.description, {this.location});
}

const _allTips = [
  _TipItem(_TipType.tip,          'Rotate crops annually',          'Rotating crops helps prevent soil depletion and reduces pest buildup.'),
  _TipItem(_TipType.news,         'New pest resistant corn',        'Scientists have developed a new corn variety resistant to common pests.'),
  _TipItem(_TipType.notification, 'Harvest season coming!',         'Prepare your equipment for the upcoming harvest season.'),
  _TipItem(_TipType.tip,          'Punjab: Optimal sowing window',  'Mid-Feb to March is ideal for spring maize. Avoid late sowing to reduce pest pressure.', location: 'Punjab'),
  _TipItem(_TipType.news,         'Multan corn yield trials',       'High-yield corn trials in Multan show 15 % improvement with new irrigation schedule.',     location: 'Multan'),
  _TipItem(_TipType.tip,          'Lahore area: Soil testing',      'Get your soil tested before kharif in Lahore division for better fertilizer use.',          location: 'Lahore'),
  _TipItem(_TipType.notification, 'Faisalabad mandi rates',         'Corn prices in Faisalabad mandi are stable. Good time to plan harvest sales.',             location: 'Faisalabad'),
  _TipItem(_TipType.tip,          'Sahiwal: Water management',      'Use drip irrigation for maize to save water and improve yield.',                            location: 'Sahiwal'),
  _TipItem(_TipType.news,         'Bahawalpur seed subsidy',        'Government seed subsidy for cotton and maize available for Bahawalpur farmers.',            location: 'Bahawalpur'),
];

// ─── Widget ───────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.showLoginSuccess = false});
  final bool showLoginSuccess;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  int    _selectedIndex = 0;
  String _userName      = 'Farmer';
  String _userEmail     = '';
  String? _userPhotoUrl;
  String? _userId;
  String? _userPhone;
  String? _userLocation;

  bool   _isLoading     = true;
  int    _totalScans    = 0;
  Map<String, dynamic>? _lastScan;
  bool   _hasLoadedStats = false;

  // PageController for tips
  final PageController _tipsCtrl = PageController(viewportFraction: 0.92);
  int _tipPage = 0;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login successful!'),
            backgroundColor: _AppColors.primaryLight,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  // ── data loading ───────────────────────────────────────────────────────────
  Future<void> _loadUserData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final backendLoggedIn      = await AuthSession.isBackendLoggedIn();
    final backendEmail         = await AuthSession.getBackendEmail();
    final backendUsername      = await AuthSession.getBackendUsername();
    final backendUserId        = await AuthSession.getBackendUserId();
    final backendPhone         = await AuthSession.getBackendPhoneNumber();
    final backendLocation      = await AuthSession.getBackendLocation();
    final backendProfilePicture = await AuthSession.getBackendProfilePicture();

    if (!backendLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (!mounted) return;
    // Debug: Print user data to see what's being loaded
    debugPrint('Backend username: $backendUsername');
    debugPrint('Backend email: $backendEmail');
    debugPrint('Backend profile picture: $backendProfilePicture');
    
    setState(() {
      _userName     = backendUsername?.isNotEmpty == true ? backendUsername! : 'Farmer';
      _userEmail    = backendEmail ?? '';
      _userPhotoUrl = backendProfilePicture;
      _userId       = backendUserId;
      _userPhone    = backendPhone;
      _userLocation = backendLocation;
      _isLoading    = false;
    });
    
    // Debug: Print final user name
    debugPrint('Final user name: $_userName');

    if (backendUserId != null && !_hasLoadedStats) {
      await _loadScanStatistics(backendUserId);
    }
  }

  Future<void> _loadScanStatistics(String userId) async {
    try {
      final historyData = await ApiService.getHistoryWithCount(userId: userId);
      if (!mounted) return;
      setState(() {
        _totalScans = historyData['count'] ?? 0;
        final dataList = historyData['data'] as List<dynamic>?;
        _lastScan       = (dataList?.isNotEmpty == true) ? dataList!.first as Map<String, dynamic> : null;
        _hasLoadedStats = true;
      });
    } catch (e) {
      debugPrint('Failed to load scan statistics: $e');
    }
  }

  Future<void> _refreshUserData() async {
    setState(() { _isLoading = true; _hasLoadedStats = false; _tipPage = 0; });
    await _loadUserData();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getLastScanDisplay() {
    if (_lastScan == null) return 'Never';
    final time = _lastScan!['time'] as String?;
    final date = _lastScan!['date'] as String?;
    if (time == null || date == null) return 'Unknown';
    try {
      final scanDate = DateTime.parse('${date}T$time:00');
      final now = DateTime.now();
      if (now.year == scanDate.year && now.month == scanDate.month && now.day == scanDate.day) {
        return 'Today $time';
      }
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[scanDate.month - 1]} ${scanDate.day}';
    } catch (_) {
      return 'Unknown';
    }
  }

  String? _getLastDiseaseName() => _lastScan?['disease'] as String?;

  List<_TipItem> get _visibleTips {
    final loc = _userLocation?.trim().toLowerCase() ?? '';
    if (loc.isEmpty) {
      return _allTips.where((t) => t.location == null).toList();
    }
    final located = _allTips.where((t) {
      final tl = t.location?.trim().toLowerCase();
      return tl != null && loc.contains(tl);
    }).toList();
    return located.isEmpty
        ? _allTips.where((t) => t.location == null).toList()
        : located;
  }

  void _onCameraTap() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DetectDiseaseScreen()),
  );

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SignOutDialog(),
    );
    if (confirmed != true) return;
    await AuthSession.clearBackendSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ── tab routing ────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 1:
        return HistoryScreen(
          userName: _userName, userEmail: _userEmail,
          userPhotoUrl: _userPhotoUrl, userId: _userId,
        );
      case 2:
        return ProfileScreen(
          userName: _userName, userEmail: _userEmail,
          userPhotoUrl: _userPhotoUrl, userId: _userId,
          userPhone: _userPhone,
          onSignOut: _handleSignOut, onRefresh: _refreshUserData,
        );
      default:
        return _HomeContent(
          key: ValueKey('homeContent'),
          isLoading:          _isLoading,
          userName:           _userName,
          userEmail:          _userEmail,
          userLocation:       _userLocation,
          greeting:           _getGreeting(),
          totalScans:         _totalScans,
          lastScanDisplay:    _getLastScanDisplay(),
          lastDiseaseName:    _getLastDiseaseName(),
          visibleTips:        _visibleTips,
          onCameraTap:        _onCameraTap,
          onRefresh:          _refreshUserData,
          tipsCtrl:           _tipsCtrl,
          tipPage:            _tipPage,
          onPageChanged:       (page) {
            final roundedPage = page.round();
            if (roundedPage != _tipPage) {
              setState(() => _tipPage = roundedPage);
            }
          },
        );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: SafeArea(child: _buildTabContent()),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo sized appropriately for full screen
          Container(
            width: 40, // Optimized size for app bar
            height: 40, // Optimized size for app bar
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: Colors.green[800],
                    size: 24, // Optimized icon size
                  ),
                );
              },
            ),
          ),
          Text(
            'Corn Disease Detector',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        // Avatar / profile button on right side
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 2),
            child: _UserAvatar(
              name: _userName,
              photoUrl: _userPhotoUrl,
              size: 42,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Home content ─────────────────────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.isLoading,
    required this.userName,
    required this.userEmail,
    required this.userLocation,
    required this.greeting,
    required this.totalScans,
    required this.lastScanDisplay,
    required this.lastDiseaseName,
    required this.visibleTips,
    required this.onCameraTap,
    required this.onRefresh,
    required this.tipsCtrl,
    required this.tipPage,
    required this.onPageChanged,
    Key? key,
  });

  final bool     isLoading;
  final String   userName;
  final String   userEmail;
  final String?  userLocation;
  final String   greeting;
  final int      totalScans;
  final String   lastScanDisplay;
  final String?  lastDiseaseName;
  final List<_TipItem> visibleTips;
  final VoidCallback onCameraTap;
  final VoidCallback onRefresh;
  final PageController tipsCtrl;
  final int tipPage;
  final Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Single-page layout — no scroll on home screen
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Greeting ──────────────────────────────────────────────────────
          _Greeting(
            greeting: isLoading ? 'Welcome...' : '$greeting 👋',
            name:     isLoading ? '' : userName,
          ),
          const SizedBox(height: 14),

          // ── Hero CTA ──────────────────────────────────────────────────────
          _HeroCTA(onTap: onCameraTap),
          const SizedBox(height: 14),

          // ── Stats row ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _StatCard(
                icon:  Icons.document_scanner_rounded,
                label: 'Total scans',
                value: isLoading ? '—' : totalScans.toString(),
                sub:   null,
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon:  Icons.schedule_rounded,
                label: 'Last scan',
                value: isLoading ? '—' : lastScanDisplay,
                sub:   lastDiseaseName,
                smallValue: false,
              )),
            ],
          ),
          const SizedBox(height: 18),

          // ── Tips header ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Tips & news',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary,
                ),
              ),
              const Spacer(),
              if (userLocation != null && userLocation!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 13, color: _AppColors.primaryLight),
                    const SizedBox(width: 2),
                    Text(
                      userLocation!,
                      style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: Icon(Icons.refresh_rounded, size: 18, color: _AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Tips horizontal PageView ──────────────────────────────
          // Uses Expanded to consume remaining space — no outer scroll needed
          Expanded(
            child: visibleTips.isEmpty
                ? Center(
                    child: Text(
                      'No tips available for your area yet.',
                      style: TextStyle(fontSize: 13, color: _AppColors.textMuted),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollUpdateNotification) {
                        final p = tipsCtrl.page?.round() ?? 0;
                        if (p != tipPage) {
                          onPageChanged(p);
                        }
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: tipsCtrl,
                      itemCount: visibleTips.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _TipCard(tip: visibleTips[i]),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          
          // ── Tips dot indicator ────────────────────────────────────
          _tipsDotRow(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Tips dot indicator ─────────────────────────────────────────
  Widget _tipsDotRow() {
    final count = visibleTips.length;
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == tipPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6, height: 6,
          decoration: BoxDecoration(
            color: active ? _AppColors.primary : _AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.name});
  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
        if (name.isNotEmpty)
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _AppColors.primary),
          ),
      ],
    );
  }
}

// ─── Hero CTA ─────────────────────────────────────────────────────────────────
class _HeroCTA extends StatelessWidget {
  const _HeroCTA({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: _AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Left text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI DETECTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detect corn disease',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point your camera at any leaf',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),

            // Right camera button
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
                  SizedBox(height: 2),
                  Text(
                    'SCAN',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.smallValue = false,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final String?  sub;
  final bool     smallValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _AppColors.primaryLight),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 15 : 22,
              fontWeight: FontWeight.w700,
              color: _AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null && sub!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub!, style: const TextStyle(fontSize: 10, color: _AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final _TipItem tip;

  @override
  Widget build(BuildContext context) {
    // Badge style per type
    final Color badgeBg;
    final Color badgeFg;
    final String badgeLabel;
    final IconData badgeIcon;

    switch (tip.type) {
      case _TipType.tip:
        badgeBg    = const Color(0xFFFFF3E0);
        badgeFg    = const Color(0xFFE65100);
        badgeLabel = 'Tip';
        badgeIcon  = Icons.lightbulb_outline_rounded;
      case _TipType.news:
        badgeBg    = const Color(0xFFE3F2FD);
        badgeFg    = const Color(0xFF1565C0);
        badgeLabel = 'News';
        badgeIcon  = Icons.newspaper_rounded;
      case _TipType.notification:
        badgeBg    = const Color(0xFFFCE4EC);
        badgeFg    = const Color(0xFF880E4F);
        badgeLabel = 'Alert';
        badgeIcon  = Icons.notifications_outlined;
    }

    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 11, color: badgeFg),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeFg),
                      ),
                    ],
                  ),
                ),
                if (tip.location != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.location_on_rounded, size: 12, color: _AppColors.primaryLight),
                  Text(
                    tip.location!,
                    style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _AppColors.primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              tip.description,
              style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded,    Icons.home_outlined,    'Home'),
    (Icons.history_rounded, Icons.history_rounded,  'History'),
    (Icons.person_rounded,  Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final (activeIcon, inactiveIcon, label) = _items[i];
            final isActive = selectedIndex == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top indicator line
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.5,
                      width: isActive ? 32 : 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: _AppColors.primary,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                      ),
                    ),
                    Icon(
                      isActive ? activeIcon : inactiveIcon,
                      size: 24,
                      color: isActive ? _AppColors.primary : _AppColors.textMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? _AppColors.primary : _AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── User avatar ──────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.photoUrl, required this.size});
  final String  name;
  final String? photoUrl;
  final double  size;

  String get _initials {
    if (name.isEmpty) return 'F';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _AppColors.surfaceMid,
      child: Text(_initials, style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w600, color: _AppColors.primary)),
    );
  }
}

// ─── Sign out dialog ──────────────────────────────────────────────────────────
class _SignOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, size: 30, color: _AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Sign out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _AppColors.primary)),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Sign out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 15, color: _AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}