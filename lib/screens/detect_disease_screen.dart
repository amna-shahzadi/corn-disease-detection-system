import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'camera_screen.dart';
import 'dashboard_screen.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const forestGreen = Color(0xFF1B5E20);
  static const forestMid = Color(0xFF2E7D32);
  static const forestLight = Color(0xFF43A047);
  static const mintSurface = Color(0xFFF1F8F1);
  static const mintBorder = Color(0xFFBEDDBE);
  static const cardBg = Color(0xFFFFFFFF);
  static const pageBg = Color(0xFFF6FAF6);
  static const labelGrey = Color(0xFF6B7280);
  static const bodyText = Color(0xFF1F2937);
  static const divider = Color(0xFFE5EDE5);
  static const danger = Color(0xFFB91C1C);
  static const warning = Color(0xFFD97706);
  static const success = Color(0xFF15803D);
  static const tagSurface = Color(0xFFECFDF5);
  static const tagText = Color(0xFF065F46);
}

class _Radius {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(100));
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DetectDiseaseScreen extends StatefulWidget {
  const DetectDiseaseScreen({
    super.key,
    this.capturedImagePath,
    this.initialResponse,
  });
  final String? capturedImagePath;
  final DetectDiseaseResponse? initialResponse;

  @override
  State<DetectDiseaseScreen> createState() => _DetectDiseaseScreenState();
}

class _DetectDiseaseScreenState extends State<DetectDiseaseScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _selectedImageBytes;
  String? _diseaseResult;
  String? _confidenceLevel;
  DetectDiseaseResponse? _detectionResponse;
  double? _originalImageWidth;
  double? _originalImageHeight;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final ImagePicker _picker = ImagePicker();

  bool get _hasImage =>
      _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
  bool get _hasResults => _detectionResponse != null;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    if (widget.capturedImagePath != null) {
      _loadImageFromPath(widget.capturedImagePath!);
    }
    if (widget.initialResponse != null) {
      _applyResponse(widget.initialResponse!);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _applyResponse(DetectDiseaseResponse r) {
    _detectionResponse = r;
    _diseaseResult = r.diseaseName ?? r.message ?? 'Unknown';
    _confidenceLevel = r.confidence != null
        ? (r.confidence!.endsWith('%') ? r.confidence : '${r.confidence}%')
        : null;
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _loadImageFromPath(String path) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      if (mounted) setState(() => _selectedImageBytes = bytes);
    } catch (e) {
      debugPrint('Image load error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _diseaseResult = _confidenceLevel = null;
      _detectionResponse = null;
      _originalImageWidth = _originalImageHeight = null;
    });
  }

  Future<void> _pickFromCamera() async {
    final f = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _diseaseResult = _confidenceLevel = null;
      _detectionResponse = null;
      _originalImageWidth = _originalImageHeight = null;
    });
  }

  void _clearImage() => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
        (_) => false,
      );

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _AppColors.danger : _AppColors.forestGreen,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: _Radius.md),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.pageBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _buildImageSection(),
                  if (_hasResults) ...[
                    const SizedBox(height: 28),
                    FadeTransition(opacity: _fadeAnim, child: _buildResults()),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() => SliverAppBar(
        backgroundColor: _AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        pinned: true,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          ),
          icon: const Icon(Icons.arrow_back, color: _AppColors.forestGreen),
          iconSize: 24,
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.detectDiseaseAppBarTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.forestGreen,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.detectDiseaseAppBarSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: _AppColors.labelGrey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _AppColors.divider),
        ),
      );

  // ── Image Section ──────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    if (_hasImage) return _buildImageCard();
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() => GestureDetector(
        onTap: _pickFromGallery,
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: _AppColors.cardBg,
            borderRadius: _Radius.lg,
            border: Border.all(
                color: _AppColors.mintBorder,
                width: 1.5,
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _AppColors.mintSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _AppColors.mintBorder),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined,
                    size: 32, color: _AppColors.forestGreen),
              ),
              const SizedBox(height: 14),
              Text(AppLocalizations.of(context)!.detectDiseaseTapToSelect,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.bodyText)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.detectDiseaseOrUseButtons,
                  style: TextStyle(fontSize: 13, color: _AppColors.labelGrey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallButton(
                    icon: Icons.photo_library_outlined,
                    label: AppLocalizations.of(context)!.detectDiseaseGallery,
                    onTap: _pickFromGallery,
                  ),
                  const SizedBox(width: 10),
                  _SmallButton(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(context)!.detectDiseaseCamera,
                    onTap: _pickFromCamera,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildImageCard() => Column(children: [
        // Image + bounding boxes
        LayoutBuilder(builder: (ctx, constraints) {
          final size = constraints.maxWidth.clamp(0.0, 420.0);
          return ClipRRect(
            borderRadius: _Radius.lg,
            child: Container(
              width: size,
              height: size,
              color: _AppColors.mintSurface,
              child: Stack(
                children: [
                  Image.memory(
                    _selectedImageBytes!,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    frameBuilder: (_, child, frame, __) {
                      if (frame != null && _originalImageWidth == null) {
                        ui
                            .instantiateImageCodec(_selectedImageBytes!)
                            .then((c) => c.getNextFrame())
                            .then((f) {
                          if (mounted) {
                            setState(() {
                              _originalImageWidth = f.image.width.toDouble();
                              _originalImageHeight = f.image.height.toDouble();
                            });
                          }
                        });
                      }
                      return child;
                    },
                  ),
                  if (_detectionResponse?.detections != null &&
                      _originalImageWidth != null)
                    ..._detectionResponse!.detections!
                        .map((d) => _buildBBox(d, size, size)),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 2),
      ]);

  // ── Bounding Box ──────────────────────────────────────────────────────────
  Widget _buildBBox(DiseaseDetection d, double w, double h) {
    if (d.bbox == null || d.bbox!.length < 4) return const SizedBox.shrink();

    final imgAR = _originalImageWidth! / _originalImageHeight!;
    final boxAR = w / h;
    double dispW, dispH, ox, oy;

    if (imgAR > boxAR) {
      dispW = w;
      dispH = w / imgAR;
      ox = 0;
      oy = (h - dispH) / 2;
    } else {
      dispW = h * imgAR;
      dispH = h;
      ox = (w - dispW) / 2;
      oy = 0;
    }

    final sx = dispW / _originalImageWidth!;
    final sy = dispH / _originalImageHeight!;
    final bx = d.bbox![0] * sx + ox;
    final by = d.bbox![1] * sy + oy;
    final bw = (d.bbox![2] - d.bbox![0]) * sx;
    final bh = (d.bbox![3] - d.bbox![1]) * sy;

    Color boxColor = const Color(0xFFEF4444);
    if (d.color != null && d.color!.length >= 3) {
      boxColor = Color.fromARGB(255, d.color![0], d.color![1], d.color![2]);
    }

    final abbrev = _abbrev(d.disease ?? 'Unknown');
    final conf = d.confidence != null
        ? ' ${(d.confidence! * 100).toStringAsFixed(1)}%'
        : '';

    return Positioned(
      top: by,
      left: bx,
      child: SizedBox(
        width: bw,
        height: bh,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: boxColor, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(
                '$abbrev$conf',
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────
  Widget _buildResults() {
    final r = _detectionResponse!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary ──
        _SectionLabel(label: AppLocalizations.of(context)!.detectDiseaseSummary),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.search_rounded,
                color: _AppColors.forestGreen,
                label: AppLocalizations.of(context)!.detectDiseaseDetections,
                value: '${r.totalDetections ?? 0}',
              ),
            ),
            const SizedBox(width: 6), // ← REDUCED
            Expanded(
              child: _MetricTile(
                icon: Icons.coronavirus_outlined,
                color: _AppColors.warning,
                label: AppLocalizations.of(context)!.detectDiseasePrimary,
                value: _diseaseResult ?? '—',
                compact: true,
              ),
            ),
            const SizedBox(width: 6), // ← REDUCED
            Expanded(
              child: _MetricTile(
                icon: Icons.percent_rounded,
                color: _AppColors.forestLight,
                label: AppLocalizations.of(context)!.detectDiseaseConfidenceLabel,
                value: _confidenceLevel ?? '—',
              ),
            ),
          ],
        ),
        // ── Detections ──
        if (r.detections != null && r.detections!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _SectionLabel(label: AppLocalizations.of(context)!.detectDiseaseDetections),
          const SizedBox(height: 2),
          ...r.detections!.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DetectionCard(detection: e.value, index: e.key + 1),
                ),
              ),
        ],

        // ── Recommendations ──
        if (_diseaseResult != null) ...[
          const SizedBox(height: 4),
          _SectionLabel(label: AppLocalizations.of(context)!.detectDiseaseRecommendations),
          const SizedBox(height: 8),
          _AdviceCard(response: _detectionResponse!),

        ],

        // ── Actions ──
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _PrimaryButton(
            icon: Icons.save_alt_rounded,
            label: AppLocalizations.of(context)!.detectDiseaseSaveResults,
            onTap: () => _toast(AppLocalizations.of(context)!.detectDiseaseSaveComingSoon),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _OutlineButton(
            icon: Icons.add_photo_alternate_outlined,
            label: AppLocalizations.of(context)!.detectDiseaseAnalyzeAnother,
            onTap: _clearImage,
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _abbrev(String name) {
    const map = {
      'fusarium ear rot': 'FER',
      'grey leaf spot': 'GLS',
      'gray leaf spot': 'GLS',
      'northern leaf blight': 'NLB',
      'common rust': 'RUST',
      'healthy corn': 'OK',
    };
    return map[name.toLowerCase()] ??
        (name.length >= 3
            ? name.substring(0, 3).toUpperCase()
            : name.toUpperCase());
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize:16,
          fontWeight: FontWeight.w700,
          color: _AppColors.forestGreen,
          letterSpacing: 0.8,
        ),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.compact = false,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _AppColors.cardBg,
          borderRadius: _Radius.md,
          border: Border.all(color: _AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _AppColors.labelGrey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 16 : 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class _DetectionCard extends StatelessWidget {
  const _DetectionCard({required this.detection, required this.index});
  final DiseaseDetection detection;
  final int index;

  @override
  Widget build(BuildContext context) {
    final conf = detection.confidence;
    final confPct = conf != null ? (conf * 100).toStringAsFixed(1) : null;
    final confColor = conf != null && conf > 0.7
        ? _AppColors.danger
        : conf != null && conf > 0.4
            ? _AppColors.warning
            : _AppColors.labelGrey;

    Color dotColor = _AppColors.forestGreen;
    if (detection.color != null && detection.color!.length >= 3) {
      dotColor = Color.fromARGB(
          255, detection.color![0], detection.color![1], detection.color![2]);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: _Radius.md,
        border: Border.all(color: _AppColors.divider),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _AppColors.mintSurface,
              borderRadius: _Radius.sm,
              border: Border.all(color: _AppColors.mintBorder),
            ),
            alignment: Alignment.center,
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.forestGreen)),
          ),
          const SizedBox(width: 10),
          // Color dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.disease ?? 'Unknown disease',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.bodyText,
                  ),
                ),
                if (detection.bbox != null && detection.bbox!.length >= 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'x: ${detection.bbox![0].toStringAsFixed(0)}  y: ${detection.bbox![1].toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11, color: _AppColors.labelGrey),
                    ),
                  ),
              ],
            ),
          ),
          if (confPct != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: confColor.withOpacity(0.08),
                borderRadius: _Radius.full,
                border: Border.all(color: confColor.withOpacity(0.25)),
              ),
              child: Text(
                '$confPct%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: confColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.response});
  final DetectDiseaseResponse response;

  bool get _isHealthy => response.isHealthy;

  @override
  Widget build(BuildContext context) {
    // Use API advice if available, otherwise fallback to default message
    final adviceList = response.advice ?? [];
    final displayAdvice = adviceList.isNotEmpty 
        ? adviceList 
        : [
            _isHealthy 
                ? 'Your crop appears healthy! Continue regular monitoring and maintain good agricultural practices.'
                : 'Consult with an agricultural extension officer or specialist for tailored treatment recommendations.'
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isHealthy ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 20,
                color: _isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  response.diseaseName ?? 'Detection Result',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayAdvice.map((advice) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 16,
                  color: _isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _AppColors.mintSurface,
            borderRadius: _Radius.full,
            border: Border.all(color: _AppColors.mintBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _AppColors.forestGreen),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.forestGreen)),
            ],
          ),
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: _AppColors.cardBg,
            borderRadius: _Radius.md,
            border: Border.all(color: _AppColors.mintBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: _AppColors.forestGreen),
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.forestGreen)),
            ],
          ),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: const BoxDecoration(
            color: _AppColors.forestGreen,
            borderRadius: _Radius.md,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}
