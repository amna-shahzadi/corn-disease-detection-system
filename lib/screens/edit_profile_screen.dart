import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'package:corn_disease_app/l10n/app_localizations.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _T {
  // Brand palette — matching profile screen green theme
  static const Color brand      = Color(0xFF1B5E20);  // primary green
  static const Color brandMid   = Color(0xFF1B5E20);  // deeper green
  static const Color brandLight = Color(0xFF388E3C);  // lighter green
  static const Color accent     = Color(0xFF4CAF50);  // accent green
  static const Color surface    = Color(0xFFF6F4F0);  // warm white
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE2DDD6);  // warm gray
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint      = Color(0xFF999999);
  static const Color danger     = Color(0xFFD32F2F);

  // Spacing
  static const double pagePadding = 20.0;
  static const double cardRadius  = 16.0;
  static const double gap         = 14.0;

  // Typography — matching profile screen
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.1,
  );
  static const TextStyle inputLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.1,
  );
  static const TextStyle inputValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  static const TextStyle fieldHint = TextStyle(
    fontSize: 15,
    color: textHint,
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String? userId;
  final String? farmLocation;
  final String? userPhone;

  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.userId,
    this.farmLocation = 'Multan, Punjab',
    this.userPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;

  Uint8List? _selectedImageBytes;
  Uint8List? _currentProfileImageBytes;
  bool _isLoadingProfileImage = true;
  bool _removePhoto = false;
  bool _isSaving = false;
  String _selectedDistrict = 'Multan';

  late AnimationController _saveAnim;
  late AnimationController _avatarAnim;
  late Animation<double> _saveScale;
  late Animation<double> _avatarPulse;

  final _picker = ImagePicker();

  final List<String> _districts = [
    'Multan', 'Lahore', 'Faisalabad', 'Rawalpindi', 'Gujranwala',
    'Sahiwal', 'Sargodha', 'Bahawalpur', 'Rahim Yar Khan',
    'Dera Ghazi Khan', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.userName);
    _emailCtrl    = TextEditingController(text: widget.userEmail);
    _phoneCtrl    = TextEditingController(text: widget.userPhone ?? '');
    _locationCtrl = TextEditingController(text: widget.farmLocation);

    _saveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _avatarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _saveScale   = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _saveAnim, curve: Curves.easeOut),
    );
    _avatarPulse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarAnim, curve: Curves.easeInOut),
    );

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadProfileImage();
    } else {
      _isLoadingProfileImage = false;
    }
  }

  Future<void> _loadProfileImage() async {
    if (widget.userPhotoUrl == null || widget.userPhotoUrl!.isEmpty) {
      if (mounted) setState(() => _isLoadingProfileImage = false);
      return;
    }
    try {
      final bytes = await ApiService.getProfileImageBytes(widget.userId!);
      if (mounted) setState(() {
        _currentProfileImageBytes = bytes;
        _isLoadingProfileImage = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfileImage = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _saveAnim.dispose();
    _avatarAnim.dispose();
    super.dispose();
  }

  // ─── Image handling ────────────────────────────────────────────────────────
  Future<void> _showImagePicker() async {
    final bool hasPhoto = _selectedImageBytes != null ||
        (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty && !_removePhoto);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoPickerSheet(
        hasExistingPhoto: hasPhoto,
        onCamera:  () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
        onRemove:  hasPhoto ? () => setState(() {
          _selectedImageBytes = null;
          _removePhoto = true;
        }) : null,
      ),
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final file = await _picker.pickImage(
        source: src,
        imageQuality: 85,
        maxWidth: 900,
        maxHeight: 900,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) setState(() {
          _selectedImageBytes = bytes;
          _removePhoto = false;
        });
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) _snack('${l10n.editProfileCouldNotLoadImage}: $e');
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (name.isEmpty) { _snack(l10n.editProfileFullNameRequired); return; }
    if (location.isEmpty) { _snack(l10n.editProfileFarmLocationRequired); return; }
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) {
      _snack(l10n.editProfileUserNotIdentified);
      return;
    }

    await _saveAnim.forward();
    await _saveAnim.reverse();
    setState(() => _isSaving = true);

    try {
      final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      await ApiService.updateUser(
        userId: userId,
        username: name,
        phoneNumber: phone,
        location: location,
        profilePictureBytes: _selectedImageBytes,
        removeProfilePicture: _removePhoto,
      );
      await AuthSession.setBackendLoggedIn(
        email: widget.userEmail,
        username: name,
        userId: userId,
        phoneNumber: phone,
        location: location,
        profilePicture: _removePhoto ? null : widget.userPhotoUrl,
        accessToken: await AuthSession.getBackendAccessToken(),
      );
      if (!mounted) return;
      _snack(l10n.editProfileProfileUpdated, success: true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, {
        'name': name,
        'location': location,
        'imageBytes': _selectedImageBytes,
      });
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('${l10n.editProfileUpdateFailed}: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
      ]),
      backgroundColor: success ? _T.brandMid : _T.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── District picker ───────────────────────────────────────────────────────
  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DistrictSheet(
        districts: _districts,
        selected: _selectedDistrict,
        onSelect: (d) => setState(() {
          _selectedDistrict = d;
          _locationCtrl.text = '$d, Punjab';
        }),
      ),
    );
  }

  // ─── Avatar widget ─────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    Widget imageChild;

    if (_isLoadingProfileImage && widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      imageChild = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: _T.brandMid),
      );
    } else if (_selectedImageBytes != null) {
      imageChild = ClipOval(child: Image.memory(
        _selectedImageBytes!,
        width: 104, height: 104, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar,
      ));
    } else if (_removePhoto) {
      imageChild = _defaultAvatar;
    } else if (_currentProfileImageBytes != null) {
      imageChild = ClipOval(child: Image.memory(
        _currentProfileImageBytes!,
        width: 104, height: 104, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar,
      ));
    } else if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      String url = widget.userPhotoUrl!;
      if (url.startsWith('/app/media/')) url = url.replaceFirst('/app/media/', '/media/');
      imageChild = ClipOval(child: Image.network(
        url, width: 104, height: 104, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Edit profile image load error: $error');
          return _defaultAvatar;
        },
      ));
    } else {
      imageChild = _defaultAvatar;
    }

    return GestureDetector(
      onTap: _showImagePicker,
      child: AnimatedBuilder(
        animation: _avatarPulse,
        builder: (_, child) {
          final glow = _selectedImageBytes != null
              ? _T.accent.withOpacity(0.15 + _avatarPulse.value * 0.15)
              : Colors.transparent;
          return Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.brandLight.withOpacity(0.4),
              boxShadow: [
                BoxShadow(color: glow, blurRadius: 20, spreadRadius: 4),
              ],
              border: Border.all(
                color: _selectedImageBytes != null
                    ? _T.accent.withOpacity(0.6 + _avatarPulse.value * 0.3)
                    : _T.brandLight,
                width: 2.5,
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            imageChild,
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _T.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _defaultAvatar => Container(
    width: 104,
    height: 104,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: _T.brandLight,
    ),
    child: const Icon(Icons.person_rounded, size: 52, color: _T.brandMid),
  );

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: _T.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        _buildAvatarSection(),
                        const SizedBox(height: 28),
                        _buildCard(children: [
                          _sectionLabel(AppLocalizations.of(context)!.editProfilePersonalInfo),
                          const SizedBox(height: 14),
                          _buildField(
                            label: AppLocalizations.of(context)!.editProfileFullNameLabel,
                            icon: Icons.person_outline_rounded,
                            controller: _nameCtrl,
                            hint: AppLocalizations.of(context)!.editProfileFullNameHint,
                            textCapitalization: TextCapitalization.words,
                          ),
                          _divider(),
                          _buildField(
                            label: AppLocalizations.of(context)!.editProfileEmailLabel,
                            icon: Icons.mail_outline_rounded,
                            controller: _emailCtrl,
                            hint: AppLocalizations.of(context)!.editProfileEmailHint,
                            readOnly: true,
                          ),
                          _divider(),
                          _buildField(
                            label: AppLocalizations.of(context)!.editProfilePhoneLabel,
                            icon: Icons.phone_outlined,
                            controller: _phoneCtrl,
                            hint: AppLocalizations.of(context)!.editProfilePhoneHint,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _buildCard(children: [
                          _sectionLabel(AppLocalizations.of(context)!.editProfileFarmInfo),
                          const SizedBox(height: 14),
                          _buildLocationTile(),
                        ]),
                        const SizedBox(height: 28),
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        _buildCancelButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _T.brand,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.editProfileTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _T.brand,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (_isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _T.brandMid,
              ),
            )
          else
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                foregroundColor: _T.brand,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLocalizations.of(context)!.editProfileSave,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.editProfileTapToChangePhoto,
            style: TextStyle(
              fontSize: 13,
              color: _T.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B1A) : _T.card,
        borderRadius: BorderRadius.circular(_T.cardRadius),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: _T.sectionLabel);
  }

  Widget _divider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Divider(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.shade100,
        height: 1,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: readOnly ? _T.brandLight.withOpacity(0.08) : _T.brandLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: readOnly ? _T.textHint : _T.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _T.inputLabel),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  inputFormatters: inputFormatters,
                  style: readOnly
                      ? _T.inputValue.copyWith(color: _T.textSecondary)
                      : _T.inputValue,
                  cursorColor: _T.brandMid,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: _T.fieldHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: readOnly
                        ? const Icon(Icons.lock_outline_rounded, size: 14, color: _T.textHint)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile() {
    return GestureDetector(
      onTap: _showDistrictPicker,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 17, color: _T.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.editProfileFarmLocationLabel, style: _T.inputLabel),
                  const SizedBox(height: 3),
                  Text(_locationCtrl.text, style: _T.inputValue),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _T.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ScaleTransition(
      scale: _saveScale,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _T.brand.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.editProfileSaveChanges,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: _T.danger,
          side: BorderSide(color: _T.danger.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(AppLocalizations.of(context)!.editProfileCancel,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Photo Picker Sheet ────────────────────────────────────────────────────────
class _PhotoPickerSheet extends StatelessWidget {
  final bool hasExistingPhoto;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _PhotoPickerSheet({
    required this.hasExistingPhoto,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: const BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _T.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.editProfileUpdatePhotoTitle,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _T.brand,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sheetTile(
            context,
            icon: Icons.camera_alt_outlined,
            label: AppLocalizations.of(context)!.editProfileTakePhoto,
            onTap: () { Navigator.pop(context); onCamera(); },
          ),
          _sheetTile(
            context,
            icon: Icons.photo_library_outlined,
            label: AppLocalizations.of(context)!.editProfileChooseFromGallery,
            onTap: () { Navigator.pop(context); onGallery(); },
          ),
          if (onRemove != null) ...[
            Divider(color: _T.border.withOpacity(0.5), height: 1, indent: 16, endIndent: 16),
            _sheetTile(
              context,
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context)!.editProfileRemovePhoto,
              color: _T.danger,
              onTap: () { Navigator.pop(context); onRemove!(); },
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sheetTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _T.brand,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color == _T.danger
              ? _T.danger.withOpacity(0.1)
              : _T.brandLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

// ─── District Picker Sheet ─────────────────────────────────────────────────────
class _DistrictSheet extends StatelessWidget {
  final List<String> districts;
  final String selected;
  final ValueChanged<String> onSelect;

  const _DistrictSheet({
    required this.districts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_outlined, color: _T.brand, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.editProfileSelectDistrict,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _T.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: _T.border.withOpacity(0.5), height: 1),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: districts.length,
                  separatorBuilder: (_, __) => Divider(
                    color: _T.border.withOpacity(0.4),
                    height: 1,
                    indent: 56,
                  ),
                  itemBuilder: (_, i) {
                    final d = districts[i];
                    final isSelected = d == selected;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isSelected ?Color(0xFF1B5E20): _T.textHint,
                      ),
                      title: Text(
                        d,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? _T.brand : _T.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: _T.accent, size: 20)
                          : null,
                      onTap: () {
                        onSelect(d);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
