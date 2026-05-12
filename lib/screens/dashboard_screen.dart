import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'package:corn_disease_app/services/api_service.dart';
import '../config/api_config.dart';
import './login_screen.dart';
import './history_screen.dart';
import './profile_screen.dart';
import './detect_disease_screen.dart';
import './camera_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF2E7D32);
  static const surface      = Color(0xFFF1F8E9);
  static const surfaceMid   = Color(0xFFE8F5E9);
  static const accent       = Color(0xFF81C784);
  static const textSub      = Color(0xFF6B7280);
  static const textMuted    = Color(0xFF9CA3AF);
  static const border       = Color(0xFFE8F5E9);
}

const _kGap = 12.0; // single spacing unit used everywhere

class _Responsive {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 380; // Small phones like iPhone SE
  }
  
  static bool isMediumScreen(BuildContext context) {
    return getScreenWidth(context) < 420; // Medium phones
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) return baseSize * 0.85;
    if (isMediumScreen(context)) return baseSize * 0.92;
    return baseSize;
  }
  
  static double getResponsivePadding(BuildContext context, double basePadding) {
    if (isSmallScreen(context)) return basePadding * 0.75;
    if (isMediumScreen(context)) return basePadding * 0.85;
    return basePadding;
  }
  
  static double getResponsiveGap(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 10.0;
    return _kGap;
  }
}

// ─── Tips data ────────────────────────────────────────────────────────────────
enum _TipType { tip, news, alert }

class _Tip {
  final _TipType type;
  final String title, desc;
  final String? loc;
  const _Tip(this.type, this.title, this.desc, {this.loc});
}

const _kTips = [
  // General tips
  _Tip(_TipType.tip,   'Rotate crops annually',         'Rotating crops prevents soil depletion and reduces pest buildup.'),
  _Tip(_TipType.news,  'New pest-resistant corn',       'Scientists developed a variety resistant to common pests.'),
  _Tip(_TipType.alert, 'Harvest season coming!',        'Prepare your equipment for the upcoming harvest season.'),
  
  // Multan
  _Tip(_TipType.news,  'Multan yield trials',           'High-yield trials show 15% improvement with new irrigation.',   loc: 'Multan'),
  _Tip(_TipType.tip,   'Multan cotton-maize rotation',  'Alternate cotton and maize for better soil health in Multan region.', loc: 'Multan'),
  _Tip(_TipType.alert, 'Multan heat warning',           'Extreme heat expected - protect young maize plants.', loc: 'Multan'),
  
  // Lahore
  _Tip(_TipType.tip,   'Soil testing reminder',         'Test your soil before kharif for better fertilizer use.',        loc: 'Lahore'),
  _Tip(_TipType.news,  'Lahore agriculture expo',       'Modern farming equipment showcase next month.', loc: 'Lahore'),
  _Tip(_TipType.tip,   'Lahore pest control',           'Monitor for armyworm in Lahore district maize fields.', loc: 'Lahore'),
  
  // Faisalabad
  _Tip(_TipType.alert, 'Faisalabad mandi rates',        'Corn prices are stable — good time to plan harvest sales.',     loc: 'Faisalabad'),
  _Tip(_TipType.news,  'Faisalabad research center',    'New maize varieties developed for local conditions.', loc: 'Faisalabad'),
  _Tip(_TipType.tip,   'Faisalabad fertilizer tips',     'Balanced NPK application recommended for Faisalabad soils.', loc: 'Faisalabad'),
  
  // Rawalpindi
  _Tip(_TipType.tip,   'Rawalpindi sowing time',        'Start maize sowing in March for optimal yield in Potohar region.', loc: 'Rawalpindi'),
  _Tip(_TipType.news,  'Rawalpindi farming subsidy',     'Govt announces subsidy for maize farmers in northern Punjab.', loc: 'Rawalpindi'),
  _Tip(_TipType.alert, 'Rawalpindi weather alert',       'Unseasonal rains may affect maize germination.', loc: 'Rawalpindi'),
  
  // Gujranwala
  _Tip(_TipType.news,  'Gujranwala grain market',       'Maize prices rising due to increased demand.', loc: 'Gujranwala'),
  _Tip(_TipType.tip,   'Gujranwala soil health',        'Add organic matter to improve Gujranwala soil structure.', loc: 'Gujranwala'),
  _Tip(_TipType.alert, 'Gujranwala pest alert',         'Fall armyworm detected - take preventive measures.', loc: 'Gujranwala'),
  
  // Sahiwal
  _Tip(_TipType.tip,   'Water management',              'Use drip irrigation for maize to save water and improve yield.', loc: 'Sahiwal'),
  _Tip(_TipType.news,  'Sahiwal agriculture fair',       'Annual farming fair starts next week with maize focus.', loc: 'Sahiwal'),
  _Tip(_TipType.tip,   'Sahiwal hybrid varieties',      'Try new hybrid varieties adapted for Sahiwal climate.', loc: 'Sahiwal'),
  
  // Sargodha
  _Tip(_TipType.news,  'Sargodha citrus-maize',         'Intercropping maize with citrus shows promising results.', loc: 'Sargodha'),
  _Tip(_TipType.tip,   'Sargodha irrigation schedule',    'Optimize irrigation for Sargodha\'s water conditions.', loc: 'Sargodha'),
  _Tip(_TipType.alert, 'Sargodha fertilizer shortage',  'Urea shortage reported - plan fertilizer purchases early.', loc: 'Sargodha'),
  
  // Bahawalpur
  _Tip(_TipType.news,  'Bahawalpur seed subsidy',       'Govt seed subsidy for cotton and maize available now.',          loc: 'Bahawalpur'),
  _Tip(_TipType.tip,   'Bahawalpur desert farming',     'Drought-resistant maize varieties recommended for Bahawalpur.', loc: 'Bahawalpur'),
  _Tip(_TipType.alert, 'Bahawalpur water crisis',       'Groundwater levels dropping - adopt water conservation.', loc: 'Bahawalpur'),
  
  // Rahim Yar Khan
  _Tip(_TipType.news,  'Rahim Yar Khan sugar mill',     'New sugar mill increases maize demand in the region.', loc: 'Rahim Yar Khan'),
  _Tip(_TipType.tip,   'Rahim Yar Khan sowing tips',    'Early sowing recommended for Rahim Yar Khan climate.', loc: 'Rahim Yar Khan'),
  _Tip(_TipType.alert, 'Rahim Yar Khan flood risk',     'Monitor flood warnings during monsoon season.', loc: 'Rahim Yar Khan'),
  
  // Dera Ghazi Khan
  _Tip(_TipType.news,  'DG Khan agriculture college',     'New research on maize disease resistance published.', loc: 'Dera Ghazi Khan'),
  _Tip(_TipType.tip,   'DG Khan hilly terrain',         'Use contour farming for maize on DG Khan slopes.', loc: 'Dera Ghazi Khan'),
  _Tip(_TipType.alert, 'DG Khan drought warning',        'Below-average rainfall expected - plan accordingly.', loc: 'Dera Ghazi Khan'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.showLoginSuccess = false});
  final bool showLoginSuccess;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int     _tab          = 0;
  int     _previousTab  = 0;
  String  _name         = 'Farmer';
  String  _email        = '';
  String? _photoUrl;
  String? _userId;
  String? _phone;
  String? _location;
  bool    _loading      = true;
  int     _totalScans   = 0;
  Map<String, dynamic>? _lastScan;
  bool    _statsLoaded  = false;
    bool    _tipsLoading  = false;
  List<Map<String, dynamic>> _dynamicTips = [];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
      if (widget.showLoginSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.commonSuccess),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ));
        });
      }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes to foreground (user returns from profile/settings/detection)
    if (state == AppLifecycleState.resumed) {
      // Single refresh with delay to catch any changes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndRefreshProfile();
      });
    }
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when returning to this screen (especially from profile)
    if (oldWidget.showLoginSuccess != widget.showLoginSuccess) {
      _refreshFromProfileUpdate();
    }
  }

  // ── data ──────────────────────────────────────────────────────────────────
  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final ok       = await AuthSession.isBackendLoggedIn();
    final email    = await AuthSession.getBackendEmail();
    final username = await AuthSession.getBackendUsername();
    final uid      = await AuthSession.getBackendUserId();
    final phone    = await AuthSession.getBackendPhoneNumber();
    final loc      = await AuthSession.getBackendLocation();
    final photo    = await AuthSession.getBackendProfilePicture();

    if (!ok) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (!mounted) return;
    setState(() {
      _name    = username?.isNotEmpty == true ? username! : 'Farmer';
      _email   = email ?? '';
      _photoUrl = photo;
      _userId  = uid;
      _phone   = phone;
      _location = loc;
      _loading  = false;
    });
    
    // Debug: Check what photo URL we're getting
    debugPrint('Dashboard photo URL: $photo');
    debugPrint('Dashboard _photoUrl set to: $_photoUrl');
    if (uid != null && !_statsLoaded) await _loadStats(uid);
    await _loadTips();
  }

  Future<void> _loadStats(String uid) async {
    try {
      final d = await ApiService.getHistoryWithCount(userId: uid);
      if (!mounted) return;
      setState(() {
        _totalScans  = d['count'] ?? 0;
        final list   = d['data'] as List<dynamic>?;
        _lastScan    = list?.isNotEmpty == true ? list!.first as Map<String, dynamic> : null;
        _statsLoaded = true;
        
        // Debug logging to see what data we actually get
        debugPrint('DEBUG: Dashboard received _lastScan: $_lastScan');
        if (_lastScan != null) {
          debugPrint('DEBUG: _lastScan keys: ${_lastScan!.keys.toList()}');
          debugPrint('DEBUG: Full _lastScan JSON: ${_lastScan.toString()}');
          debugPrint('DEBUG: Looking for disease in fields: disease, diseaseName, label, prediction');
          debugPrint('DEBUG: disease field: ${_lastScan!['disease']}');
          debugPrint('DEBUG: diseaseName field: ${_lastScan!['diseaseName']}');
          debugPrint('DEBUG: label field: ${_lastScan!['label']}');
          debugPrint('DEBUG: prediction field: ${_lastScan!['prediction']}');
          debugPrint('DEBUG: result field: ${_lastScan!['result']}');
          debugPrint('DEBUG: detectedDisease field: ${_lastScan!['detectedDisease']}');
          debugPrint('DEBUG: scanResult field: ${_lastScan!['scanResult']}');
          debugPrint('DEBUG: title field: ${_lastScan!['title']}');
        }
      });
    } catch (e) {
      debugPrint('stats error: $e');
    }
  }

  
  Future<void> _loadTips() async {
    if (_location == null || _location!.isEmpty) return;
    
    setState(() => _tipsLoading = true);
    try {
      final dynamicTips = await ApiService.getTipsAndNews(location: _location);
      if (!mounted) return;
      setState(() { 
        _dynamicTips = dynamicTips; 
        _tipsLoading = false; 
      });
    } catch (_) {
      if (mounted) setState(() => _tipsLoading = false);
    }
  }

  Future<void> _checkAndRefreshProfile() async {
    // Check if profile data has changed and refresh if needed
    final currentLocation = await AuthSession.getBackendLocation();
    final currentName = await AuthSession.getBackendUsername();
    final currentPhoto = await AuthSession.getBackendProfilePicture();
    
    if (currentLocation != _location || 
        currentName != _name || 
        currentPhoto != _photoUrl) {
      await _boot();
    }
  }

  
  Future<void> _refresh() async {
    setState(() { _loading = true; _statsLoaded = false; _dynamicTips = []; });
    await _boot();
  }

  Future<void> _refreshFromProfileUpdate() async {
    // Force refresh all data when profile is updated
    setState(() { 
      _loading = true; 
      _statsLoaded = false; 
      _dynamicTips = []; 
    });
    await _boot();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String get _greeting {
    final l10n = AppLocalizations.of(context)!;
    final h = DateTime.now().hour;
    if (h < 12) return '${l10n.loginTitle} 👋';
    if (h < 17) return '${l10n.loginTitle} 👋';
    return '${l10n.loginTitle} 👋';
  }

  /// Short date like "May 6" or "Today"
  String get _lastScanDate {
    if (_lastScan == null) return '—';
    final t = _lastScan!['time'] as String?;
    final d = _lastScan!['date'] as String?;
    if (t == null || d == null) return '—';
    try {
      final dt  = DateTime.parse('${d}T$t:00');
      final now = DateTime.now();
      final l10n = AppLocalizations.of(context)!;
      if (now.year == dt.year && now.month == dt.month && now.day == dt.day) return l10n.dashboardToday;
      final m = [
        l10n.dashboardJanuary, l10n.dashboardFebruary, l10n.dashboardMarch,
        l10n.dashboardApril, l10n.dashboardMay, l10n.dashboardJune,
        l10n.dashboardJuly, l10n.dashboardAugust, l10n.dashboardSeptember,
        l10n.dashboardOctober, l10n.dashboardNovember, l10n.dashboardDecember
      ];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) { return '—'; }
  }

  String? get _disease {
    if (_lastScan == null) return null;
    
    // History API uses flat structure with disease_name field directly
    final diseaseName = _lastScan!['disease_name'] as String?;
    debugPrint('DEBUG: Found disease_name field: $diseaseName');
    
    if (diseaseName != null && diseaseName.isNotEmpty) {
      // Handle multiple diseases separated by semicolon
      final diseases = diseaseName.split(';');
      if (diseases.isNotEmpty) {
        debugPrint('DEBUG: Returning first disease: ${diseases.first.trim()}');
        return diseases.first.trim();
      }
    }
    
    // Fallback to other field names for backward compatibility
    final disease = _lastScan!['disease'] as String?;
    final label = _lastScan!['label'] as String?;
    final prediction = _lastScan!['prediction'] as String?;
    final result = _lastScan!['result'] as String?;
    final detectedDisease = _lastScan!['detectedDisease'] as String?;
    final scanResult = _lastScan!['scanResult'] as String?;
    
    // Debug what we found
    debugPrint('DEBUG: Checking fallback fields:');
    debugPrint('  disease: $disease');
    debugPrint('  label: $label');
    debugPrint('  prediction: $prediction');
    debugPrint('  result: $result');
    debugPrint('  detectedDisease: $detectedDisease');
    debugPrint('  scanResult: $scanResult');
    
    // Return the first non-null value in priority order
    return diseaseName ?? disease ?? label ?? prediction ?? result ?? detectedDisease ?? scanResult;
  }

  List<_Tip> get _tips {
    // If dynamic tips are available, use them
    if (_dynamicTips.isNotEmpty) {
      return _dynamicTips.map((tip) {
        final typeStr = tip['type']?.toString().toLowerCase();
        final type = switch (typeStr) {
          'tip' => _TipType.tip,
          'news' => _TipType.news,
          'alert' => _TipType.alert,
          _ => _TipType.tip,
        };
        final title = _getLocalizedTipTitle(type);
        final description = _getLocalizedTipDescription(type);
        return _Tip(type, title, description);
      }).toList();
    }
    
    // Fallback to hardcoded tips if no dynamic tips
    final loc = _location?.trim().toLowerCase() ?? '';
    final located = loc.isEmpty ? <_Tip>[] :
        _kTips.where((t) {
          final tl = t.loc?.trim().toLowerCase();
          return tl != null && loc.contains(tl);
        }).toList();
    final general = _kTips.where((t) => t.loc == null).toList();
    return [...located, ...general];
  }

  String _getLocalizedTipTitle(_TipType type) {
    switch (type) {
      case _TipType.tip:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanYieldTrials;
          case 'lahore':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFair;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFair;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaIrrigationSchedule;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadResearchCenter;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiSowingTime;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaGrainMarket;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurWaterCrisis;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanSugarMill;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanAgricultureCollege;
          default:
            return AppLocalizations.of(context)!.tipRotateCropsAnnually;
        }
      case _TipType.news:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanCottonMaizeRotation;
          case 'lahore':
            return AppLocalizations.of(context)!.tipLahoreAgricultureExpo;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFair;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaCitrusMaize;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadMandiRates;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiFarmingSubsidy;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaSoilHealth;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurDesertFarming;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanFloodRisk;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanDroughtWarning;
          default:
            return AppLocalizations.of(context)!.tipNewPestResistantCorn;
        }
      case _TipType.alert:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanHeatWarning;
          case 'lahore':
            return AppLocalizations.of(context)!.tipLahorePestControl;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFair;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaFertilizerShortage;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadFertilizerTips;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiWeatherAlert;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaPestAlert;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurWaterCrisis;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanFloodRisk;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanDroughtWarning;
          default:
            return AppLocalizations.of(context)!.tipHarvestSeasonComing;
        }
    }
  }

  String _getLocalizedTipDescription(_TipType type) {
    switch (type) {
      case _TipType.tip:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanYieldTrialsDesc;
          case 'lahore':
            return AppLocalizations.of(context)!.tipSahiwalWaterManagementDesc;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalHybridVarietiesDesc;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaIrrigationScheduleDesc;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadFertilizerTipsDesc;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiSowingTimeDesc;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaSoilHealthDesc;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurDesertFarmingDesc;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanSowingTipsDesc;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanHillyTerrainDesc;
          default:
            return AppLocalizations.of(context)!.tipRotateCropsAnnuallyDesc;
        }
      case _TipType.news:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanCottonMaizeRotationDesc;
          case 'lahore':
            return AppLocalizations.of(context)!.tipLahoreAgricultureExpoDesc;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFairDesc;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaCitrusMaizeDesc;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadMandiRatesDesc;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiFarmingSubsidyDesc;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaPestAlertDesc;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurWaterCrisisDesc;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanFloodRiskDesc;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanDroughtWarningDesc;
          default:
            return AppLocalizations.of(context)!.tipNewPestResistantCornDesc;
        }
      case _TipType.alert:
        switch (_location?.toLowerCase()) {
          case 'multan':
            return AppLocalizations.of(context)!.tipMultanHeatWarningDesc;
          case 'lahore':
            return AppLocalizations.of(context)!.tipLahorePestControlDesc;
          case 'sahiwal':
            return AppLocalizations.of(context)!.tipSahiwalAgricultureFairDesc;
          case 'sargodha':
            return AppLocalizations.of(context)!.tipSargodhaFertilizerShortageDesc;
          case 'faisalabad':
            return AppLocalizations.of(context)!.tipFaisalabadFertilizerTipsDesc;
          case 'rawalpindi':
            return AppLocalizations.of(context)!.tipRawalpindiWeatherAlertDesc;
          case 'gujranwala':
            return AppLocalizations.of(context)!.tipGujranwalaPestAlertDesc;
          case 'bahawalpur':
            return AppLocalizations.of(context)!.tipBahawalpurWaterCrisisDesc;
          case 'rahim yar khan':
            return AppLocalizations.of(context)!.tipRahimYarKhanFloodRiskDesc;
          case 'dg khan':
            return AppLocalizations.of(context)!.tipDGKhanDroughtWarningDesc;
          default:
            return AppLocalizations.of(context)!.tipHarvestSeasonComingDesc;
        }
    }
  }

  void _showTipDetail(_Tip tip) {
    // Show tip detail in a modal or navigate to detail screen
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          tip.title,
          style: TextStyle(
            fontSize: _Responsive.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.green[300]! 
                : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            tip.desc,
            style: TextStyle(
              fontSize: _Responsive.getResponsiveFontSize(context, 14),
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400]! 
                  : _C.textSub,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(
                fontSize: _Responsive.getResponsiveFontSize(context, 16),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.green[400]! 
                    : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkStoragePermission() async {
    // For Android 13+, use photos permission
    if (await _isAndroid13OrHigher()) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog('Gallery', 'photos');
        return false;
      }
      
      final result = await Permission.photos.request();
      if (result.isGranted) return true;
      
      if (result.isPermanentlyDenied) {
        _showPermissionDialog('Gallery', 'photos');
      }
      return false;
    } else {
      // For older Android versions
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog('Gallery', 'storage');
        return false;
      }
      
      final result = await Permission.storage.request();
      if (result.isGranted) return true;
      
      if (result.isPermanentlyDenied) {
        _showPermissionDialog('Gallery', 'storage');
      }
      return false;
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    try {

      return true; // Assume Android 13+ for now
    } catch (e) {
      return false;
    }
  }

  void _showPermissionDialog(String feature, String permissionType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('$feature Permission Required'),
        content: Text('Please enable $permissionType permission in Settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _onScan() => _fromCamera();

  Future<void> _fromCamera() async {
    try {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const CameraScreen()));
    } catch (e) { _err('Camera error: $e'); }
  }

  Future<void> _fromGallery() async {
    try {
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) return;
      
      final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (f != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetectDiseaseScreen(capturedImagePath: f.path)));
      }
    } catch (e) { _err('Gallery error: $e'); }
  }

  void _err(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  // ── sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    await AuthSession.clearBackendSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5), // off-white page bg
      appBar: _tab == 0 ? _appBar() : null,
      body: SafeArea(child: _body()),
      bottomNavigationBar: _Nav(selected: _tab, onTap: (i) {
        setState(() {
          _previousTab = _tab;
          _tab = i;
        });
        
        // Check for profile changes when switching from profile tab (2) back to home tab (0)
        if (_previousTab == 2 && _tab == 0) {
          _checkAndRefreshProfile();
        }
      }),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    titleSpacing: 8, // Positive spacing to move logo away from mobile edge
    toolbarHeight: 72, // Increased from 64 for better vertical spacing
    leading: null, // Completely remove leading widget
    title: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical centering
      children: [
        // Logo with responsive sizing
        SizedBox(
          width: _Responsive.isSmallScreen(context) ? 40 : 44, 
          height: _Responsive.isSmallScreen(context) ? 40 : 44,
          child: Image.asset(
            'assets/images/app_logo.png', 
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1A2B1A) 
                    : _C.surface, 
                borderRadius: BorderRadius.circular(10)
              ),
              child: Icon(
                Icons.eco_rounded, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.green[400]! 
                    : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight, 
                size: _Responsive.isSmallScreen(context) ? 20 : 24
              )
            )
          )
        ),
        SizedBox(width: _Responsive.isSmallScreen(context) ? 4 : 6), // Reduced spacing between logo and title
        // App title aligned with logo center - responsive font size
        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppLocalizations.of(context)!.appBrandName.contains('Corn') ? 'Corn' : 'کورن',
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF1B5E20),
                    height: 1.0, // Ensure proper line height for alignment
                  ),
                ),
                TextSpan(
                  text: AppLocalizations.of(context)!.appBrandName.contains('Corn') ? 'Care' : 'کیئر',
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                    color: Color(0xFF2E7D32),
                    height: 1.0, // Ensure proper line height for alignment
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    actions: [
      // Refresh icon with proper alignment and responsive sizing
      Padding(
        padding: EdgeInsets.only(
          right: 12,
          left: Localizations.localeOf(context).languageCode == 'ur' ? 0 : 0,
        ),
        child: GestureDetector(
          onTap: _refresh,
          child: Container(
            width: _Responsive.isSmallScreen(context) ? 36 : 40,
            height: _Responsive.isSmallScreen(context) ? 36 : 40,
            decoration: BoxDecoration(
              color: Color(0xFF1B5E20).withOpacity(0.08),
              borderRadius: BorderRadius.circular(_Responsive.isSmallScreen(context) ? 18 : 20),
            ),
            child: Icon(
              Icons.refresh_rounded, 
              color: Color(0xFF2E7D32), 
              size: _Responsive.isSmallScreen(context) ? 18 : 20
            ),
          ),
        ),
      ),
      // Profile avatar with proper alignment and responsive sizing
      Padding(
        padding: EdgeInsets.only(
          right: Localizations.localeOf(context).languageCode == 'ur' ? 6 : 16,
          left: Localizations.localeOf(context).languageCode == 'ur' ? 16 : 0,
        ),
        child: GestureDetector(
          onTap: () => setState(() => _tab = 2),
          child: _Avatar(name: _name, photoUrl: _photoUrl, size: _Responsive.isSmallScreen(context) ? 38 : 42),
        ),
      ),
    ],
  );

  Widget _body() {
    switch (_tab) {
      case 1: return HistoryScreen(userName: _name, userEmail: _email, userPhotoUrl: _photoUrl, userId: _userId);
      case 2: return ProfileScreen(userName: _name, userEmail: _email, userPhotoUrl: _photoUrl,
                  userId: _userId, userPhone: _phone, onSignOut: _signOut, onRefresh: _refreshFromProfileUpdate);
      default:      return _Home(
        loading:      _loading,
        name:         _name,
        greeting:     _greeting,
        location:     _location,
        totalScans:   _totalScans,
        lastScanDate: _lastScanDate,
        disease:      _disease,
        tips:         _tips,
        tipsLoading:  _tipsLoading,
        onScan:       _onScan,
        onGallery:    _fromGallery,
        onRefresh:    _refresh,
        onShowTipDetail: _showTipDetail,
      );
    }
  }
}

// ─── Home tab — fixed height, zero scroll ─────────────────────────────────────
class _Home extends StatelessWidget {
  final VoidCallback onScan, onGallery, onRefresh;
  final Function(_Tip)? onShowTipDetail;

  const _Home({
    required this.loading,
    required this.name,
    required this.greeting,
    required this.location,
    required this.totalScans,
    required this.lastScanDate,
    required this.disease,
    required this.tips,
    required this.tipsLoading,
    required this.onScan,
    required this.onGallery,
    required this.onRefresh,
    required this.onShowTipDetail,
  });

  final bool    loading, tipsLoading;
  final String  name, greeting, lastScanDate;
  final String? location, disease;
  final int     totalScans;
  final List<_Tip> tips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmall = _Responsive.isSmallScreen(context);
    final responsiveGap = _Responsive.getResponsiveGap(context);
    final responsivePadding = _Responsive.getResponsivePadding(context, 16);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(responsivePadding, 10, responsivePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Greeting column ───────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loading ? l10n.dashboardWelcome : greeting,
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 17), 
                    fontWeight: FontWeight.w400, 
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green[300]! 
                        : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary
                  )),
              SizedBox(height: isSmall ? 2 : 4),
              Text(loading ? '' : name,
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 24), 
                    fontWeight: FontWeight.w700, 
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green[300]! 
                        : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),

          SizedBox(height: responsiveGap),

          // ── Hero CTA ──────────────────────────────────────────────────────
          _HeroCTA(onTap: onScan, onGallery: onGallery),

          SizedBox(height: responsiveGap),

          // ── Stat cards ────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.document_scanner_outlined,
                label: l10n.dashboardTotalScans,
                value: loading ? '—' : '$totalScans',
                sub: 'since signup',
                bigValue: true,
              )),
              SizedBox(width: responsiveGap),
              Expanded(child: _StatCard(
                icon: Icons.history_rounded,
                label: l10n.profileStatsLastScan,
                value: loading ? '—' : lastScanDate,
                sub: disease != null ? disease! : l10n.detectDiseaseNoDisease,
                subIsDisease: disease != null,
                bigValue: false,
              )),
            ]),
          ),

          SizedBox(height: responsiveGap),

          // ── Tips header ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: isSmall ? 6 : 8),
            child: Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight, size: isSmall ? 18 : 20),
              SizedBox(width: isSmall ? 6 : 8),
              Text(l10n.dashboardTipsNews,
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 17), 
                    fontWeight: FontWeight.w600, 
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green[300]! 
                        : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary
                  )),
              const Spacer(),
              if (location?.isNotEmpty == true) ...[
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location!, 
                    style: TextStyle(
                      fontSize: _Responsive.getResponsiveFontSize(context, 12), 
                      color: _C.textSub, 
                      fontWeight: FontWeight.w500
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ]),
          ),

          SizedBox(height: isSmall ? 6 : 8),

          // ── Tips strip — Expanded fills remaining space ────────────────────
          Expanded(
            child: tipsLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 2))
                : tips.isEmpty
                    ? Center(child: Text('No tips for your area yet.',
                        style: TextStyle(
                          fontSize: _Responsive.getResponsiveFontSize(context, 13), 
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[500]! 
                              : _C.textMuted
                        )))
                    : LayoutBuilder(builder: (ctx, box) {
                        // Responsive card width: smaller on small screens
                        final cardW = isSmall 
                            ? box.maxWidth * 0.90  // Even wider on small screens
                            : box.maxWidth * 0.72;  // Original width for larger screens
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: tips.length,
                          separatorBuilder: (_, __) => SizedBox(width: isSmall ? 8 : 10),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () {
                              // Handle tip card tap - show detail if callback provided
                              if (onShowTipDetail != null) {
                                onShowTipDetail!(tips[i]);
                              }
                            },
                            child: SizedBox(
                              width: cardW, 
                              child: _TipCard(tip: tips[i])
                            ),
                          ),
                        );
                      }),
          ),

          SizedBox(height: isSmall ? 6 : 8),

          // ── Scroll hint ───────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.dashboardScrollForMore,
              style: TextStyle(
                fontSize: _Responsive.getResponsiveFontSize(context, 13), 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight, 
                fontWeight: FontWeight.w600
              ),
            ),
          ),

          SizedBox(height: isSmall ? 12 : 16),
        ],
      ),
    );
  }
}


// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// ─── Hero CTA ─────────────────────────────────────────────────────────────────
class _HeroCTA extends StatelessWidget {
  const _HeroCTA({required this.onTap, required this.onGallery});
  final VoidCallback onTap, onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmall = _Responsive.isSmallScreen(context);
    
    return Material(
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.green[300]! 
          : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary,
      borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        splashColor: Colors.white10,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _Responsive.getResponsivePadding(context, 22), 
            vertical: isSmall ? 16 : 20
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lowercase badge — 2026 pattern
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 6 : 8, 
                    vertical: isSmall ? 3 : 4
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
                  ),
                  child: Text(l10n.dashboardHeroBadge,
                      style: TextStyle(
                        fontSize: _Responsive.getResponsiveFontSize(context, 12), 
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.green[400]! 
                            : _C.accent, 
                        letterSpacing: 0.3
                      )),
                ),
                SizedBox(height: isSmall ? 4 : 6),
                Text(l10n.dashboardHeroMainText,
                    style: TextStyle(
                      fontSize: _Responsive.getResponsiveFontSize(context, 21), 
                      fontWeight: FontWeight.w700, 
                      color: Colors.white
                    )),
                SizedBox(height: isSmall ? 1 : 2),
                Text(l10n.dashboardHeroSubText,
                    style: TextStyle(
                      fontSize: _Responsive.getResponsiveFontSize(context, 13), 
                      color: Colors.white.withValues(alpha: 0.65)
                    )),
              ],
            )),
            SizedBox(width: isSmall ? 16 : 20),
            // Main capture button (center)
            Container(
              width: isSmall ? 60 : 72, 
              height: isSmall ? 60 : 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular((isSmall ? 60 : 72) / 2),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: isSmall ? 6 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular((isSmall ? 60 : 72) / 2),
                  splashColor: Colors.black12,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary,
                    size: isSmall ? 30 : 36,
                  ),
                ),
              ),
            )
            ],
          ),
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
    required this.bigValue,
    this.subIsDisease = false,
  });

  final IconData icon;
  final String   label, value;
  final String?  sub;
  final bool     bigValue, subIsDisease;

  @override
  Widget build(BuildContext context) {
    final isSmall = _Responsive.isSmallScreen(context);
    
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary.withValues(alpha: 0.05),
            blurRadius: isSmall ? 3 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 4 : 5),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isSmall ? 5 : 7),
              ),
              child: Icon(icon, size: isSmall ? 16 : 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight),
            ),
            SizedBox(width: isSmall ? 5 : 7),
            Text(label, style: TextStyle(
              fontSize: _Responsive.getResponsiveFontSize(context, 13), 
              color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight, 
              fontWeight: FontWeight.w600
            )),
          ]),
          SizedBox(height: isSmall ? 6 : 9),
          Text(value,
            style: TextStyle(
              fontSize: _Responsive.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary,
              height: 1.1,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (sub != null && sub!.isNotEmpty) ...[
            SizedBox(height: isSmall ? 3 : 5),
            Text(sub!,
              style: TextStyle(
                fontSize: _Responsive.getResponsiveFontSize(context, 13),
                color: subIsDisease ? const Color(0xFFB45309) : Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary.withValues(alpha: 0.7),
                fontWeight: subIsDisease ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
// ─── Tip card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmall = _Responsive.isSmallScreen(context);
    
    final (Color bg, Color fg, String lbl, IconData ico) = switch (tip.type) {
      _TipType.tip   => (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4CAF50) : const Color(0xFFFFF7ED), Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFFC2410C), 'Tip',   Icons.lightbulb_outline_rounded),
      _TipType.news  => (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), 'News',  Icons.newspaper_rounded),
      _TipType.alert => (const Color(0xFFFFF1F2), const Color(0xFF9F1239), 'Alert', Icons.notifications_outlined),
    };

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[600]! 
            : _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge row
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 6 : 8, 
                vertical: isSmall ? 3 : 4
              ),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(isSmall ? 4 : 6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ico, size: isSmall ? 10 : 12, color: fg),
                SizedBox(width: isSmall ? 3 : 4),
                Text(lbl, style: TextStyle(
                  fontSize: _Responsive.getResponsiveFontSize(context, 14), 
                  fontWeight: FontWeight.w700, 
                  color: fg
                )),
              ]),
            ),
            if (tip.loc != null) ...[
              SizedBox(width: isSmall ? 4 : 6),
               Icon(Icons.location_on_rounded, size: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primaryLight),
              const SizedBox(width: 1),
              Flexible(child: Text(tip.loc!,
                  style: TextStyle(
                    fontSize: _Responsive.getResponsiveFontSize(context, 14), 
                    color: _C.textSub
                  ),
                  overflow: TextOverflow.ellipsis)),
            ],
          ]),

          SizedBox(height: isSmall ? 8 : 10),

          Text(_getLocalizedTipTitle(l10n, tip.type, tip.loc),
            style: TextStyle(
              fontSize: _Responsive.getResponsiveFontSize(context, 17), 
              fontWeight: FontWeight.w600, 
              color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary, 
              height: 1.2
            ),
            maxLines: isSmall ? 1 : 2, 
            overflow: TextOverflow.ellipsis),

          SizedBox(height: isSmall ? 4 : 6),

          // Use Flexible for description to prevent overflow
          Flexible(
            child: Text(_getLocalizedTipDescription(l10n, tip.type, tip.loc),
              style: TextStyle(
                fontSize: _Responsive.getResponsiveFontSize(context, 15), 
                color: _C.textSub, 
                height: 1.3
              ),
              maxLines: isSmall ? 2 : 3, 
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTipTitle(AppLocalizations l10n, _TipType type, String? location) {
    switch (type) {
      case _TipType.tip:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanYieldTrials;
          case 'lahore':
            return l10n.tipSahiwalAgricultureFair;
          case 'sahiwal':
            return l10n.tipSahiwalAgricultureFair;
          case 'sargodha':
            return l10n.tipSargodhaIrrigationSchedule;
          case 'faisalabad':
            return l10n.tipFaisalabadResearchCenter;
          case 'rawalpindi':
            return l10n.tipRawalpindiSowingTime;
          case 'gujranwala':
            return l10n.tipGujranwalaGrainMarket;
          case 'bahawalpur':
            return l10n.tipBahawalpurWaterCrisis;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanSugarMill;
          case 'dg khan':
            return l10n.tipDGKhanAgricultureCollege;
          default:
            return l10n.tipRotateCropsAnnually;
        }
      case _TipType.news:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanCottonMaizeRotation;
          case 'lahore':
            return l10n.tipLahoreAgricultureExpo;
          case 'sahiwal':
            return l10n.tipSahiwalAgricultureFair;
          case 'sargodha':
            return l10n.tipSargodhaCitrusMaize;
          case 'faisalabad':
            return l10n.tipFaisalabadMandiRates;
          case 'rawalpindi':
            return l10n.tipRawalpindiFarmingSubsidy;
          case 'gujranwala':
            return l10n.tipGujranwalaSoilHealth;
          case 'bahawalpur':
            return l10n.tipBahawalpurDesertFarming;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanFloodRisk;
          case 'dg khan':
            return l10n.tipDGKhanDroughtWarning;
          default:
            return l10n.tipNewPestResistantCorn;
        }
      case _TipType.alert:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanHeatWarning;
          case 'lahore':
            return l10n.tipLahorePestControl;
          case 'sahiwal':
            return l10n.tipSahiwalAgricultureFair;
          case 'sargodha':
            return l10n.tipSargodhaFertilizerShortage;
          case 'faisalabad':
            return l10n.tipFaisalabadFertilizerTips;
          case 'rawalpindi':
            return l10n.tipRawalpindiWeatherAlert;
          case 'gujranwala':
            return l10n.tipGujranwalaPestAlert;
          case 'bahawalpur':
            return l10n.tipBahawalpurWaterCrisis;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanFloodRisk;
          case 'dg khan':
            return l10n.tipDGKhanDroughtWarning;
          default:
            return l10n.tipHarvestSeasonComing;
        }
    }
  }

  String _getLocalizedTipDescription(AppLocalizations l10n, _TipType type, String? location) {
    switch (type) {
      case _TipType.tip:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanYieldTrialsDesc;
          case 'lahore':
            return l10n.tipSahiwalWaterManagementDesc;
          case 'sahiwal':
            return l10n.tipSahiwalHybridVarietiesDesc;
          case 'sargodha':
            return l10n.tipSargodhaIrrigationScheduleDesc;
          case 'faisalabad':
            return l10n.tipFaisalabadFertilizerTipsDesc;
          case 'rawalpindi':
            return l10n.tipRawalpindiSowingTimeDesc;
          case 'gujranwala':
            return l10n.tipGujranwalaSoilHealthDesc;
          case 'bahawalpur':
            return l10n.tipBahawalpurDesertFarmingDesc;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanSowingTipsDesc;
          case 'dg khan':
            return l10n.tipDGKhanHillyTerrainDesc;
          default:
            return l10n.tipRotateCropsAnnuallyDesc;
        }
      case _TipType.news:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanCottonMaizeRotationDesc;
          case 'lahore':
            return l10n.tipLahoreAgricultureExpoDesc;
          case 'sahiwal':
            return l10n.tipSahiwalAgricultureFairDesc;
          case 'sargodha':
            return l10n.tipSargodhaCitrusMaizeDesc;
          case 'faisalabad':
            return l10n.tipFaisalabadMandiRatesDesc;
          case 'rawalpindi':
            return l10n.tipRawalpindiFarmingSubsidyDesc;
          case 'gujranwala':
            return l10n.tipGujranwalaPestAlertDesc;
          case 'bahawalpur':
            return l10n.tipBahawalpurWaterCrisisDesc;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanFloodRiskDesc;
          case 'dg khan':
            return l10n.tipDGKhanDroughtWarningDesc;
          default:
            return l10n.tipNewPestResistantCornDesc;
        }
      case _TipType.alert:
        switch (location?.toLowerCase()) {
          case 'multan':
            return l10n.tipMultanHeatWarningDesc;
          case 'lahore':
            return l10n.tipLahorePestControlDesc;
          case 'sahiwal':
            return l10n.tipSahiwalAgricultureFairDesc;
          case 'sargodha':
            return l10n.tipSargodhaFertilizerShortageDesc;
          case 'faisalabad':
            return l10n.tipFaisalabadFertilizerTipsDesc;
          case 'rawalpindi':
            return l10n.tipRawalpindiWeatherAlertDesc;
          case 'gujranwala':
            return l10n.tipGujranwalaPestAlertDesc;
          case 'bahawalpur':
            return l10n.tipBahawalpurWaterCrisisDesc;
          case 'rahim yar khan':
            return l10n.tipRahimYarKhanFloodRiskDesc;
          case 'dg khan':
            return l10n.tipDGKhanDroughtWarningDesc;
          default:
            return l10n.tipHarvestSeasonComingDesc;
        }
    }
  }
}
// ─── Bottom nav ───────────────────────────────────────────────────────────────
class _Nav extends StatelessWidget {
  const _Nav({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;

  static List<(IconData, IconData, String Function(BuildContext))> _items(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (Icons.home_rounded,   Icons.home_outlined,         (context) => l10n.dashboardHome),
      (Icons.history_rounded, Icons.history_rounded,      (context) => l10n.dashboardHistory),
      (Icons.person_rounded, Icons.person_outline_rounded, (context) => l10n.dashboardProfile),
    ];
  }

  static const _iconSize = 26.0; // Increased from 22 to 26

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items(context).length, (i) {
              final (actIco, inactIco, lblFunc) = _items(context)[i];
              final active = selected == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(active ? actIco : inactIco,
                            size: _iconSize, color: active ? Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary : _C.textSub),
                      ),
                      const SizedBox(height: 1),
                      Text(lblFunc(context), style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600, // Always bold
                        color: active ? Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : _C.primary : _C.textSub,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl, required this.size});
  final String name;
  final String? photoUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getValidProfileUrl(),
      builder: (context, snapshot) {
        final validUrl = snapshot.data;
        
        if (validUrl != null && validUrl.isNotEmpty) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: _C.surfaceMid,
            child: ClipOval(
              child: Image.network(
                validUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultAvatar;
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _defaultAvatar;
                },
              ),
            ),
          );
        } else {
          return _defaultAvatar;
        }
      },
    );
  }

  Future<String?> _getValidProfileUrl() async {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return null;
    }
    
    // Check if this is the default placeholder URL that returns 404
    if (photoUrl!.contains('profile.jpg') && photoUrl!.contains('/media/profile_pics/')) {
      // Try to get the valid profile_picture_url from the API
      try {
        final userId = await AuthSession.getBackendUserId();
        if (userId != null) {
          // Try to get the valid profile_picture_url from the API
          await ApiService.getProfileImageBytes(userId);
          // If we get image bytes, it means the API found a valid URL
          // We need to get the actual URL from the raw profile data
          final profileData = await _getRawProfileData(userId);
          if (profileData != null && profileData['profile_picture_url'] != null) {
            return profileData['profile_picture_url'].toString();
          }
        }
      } catch (e) {
        // If anything fails, return null to use default avatar
      }
      return null;
    }
    
    return photoUrl;
  }

  Future<Map<String, dynamic>?> _getRawProfileData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile/$userId/')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          return json;
        } catch (_) {}
      }
    } catch (e) {
      // If raw data fetch fails, return null
    }
    
    return null;
  }

  Widget get _defaultAvatar => CircleAvatar(
    radius: size / 2,
    backgroundColor: _C.surfaceMid,
    child: Text(_initials, style: TextStyle(
      fontSize: size * 0.4,
      fontWeight: FontWeight.bold,
      color: _C.primary,
    )),
  );
}
