import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:corn_disease_app/config/api_config.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'package:corn_disease_app/l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isGoogleLoading = false;
  bool _isRegisterLoading = false;
  String? _emailError;
  String? _passwordError;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _shakeController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _shakeAnim = Tween<double>(begin: 0, end: 0).animate(_shakeController);

    _fadeController.forward();
    _slideController.forward();

    _emailFocus.addListener(() {
      setState(() {
        if (_emailError != null) _emailError = null;
      });
    });
    _passwordFocus.addListener(() {
      setState(() {
        if (_passwordError != null) _passwordError = null;
      });
    });
    _confirmPasswordFocus.addListener(() {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        if (_passwordError != null && _passwordError == l10n.signUpPasswordsDoNotMatch) {
          _passwordError = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _triggerErrorShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  String? _validateEmail(String email) {
    final l10n = AppLocalizations.of(context)!;
    if (email.isEmpty) return l10n.signUpEmailRequired;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return l10n.signUpValidEmail;
    }
    return null;
  }

  String? _validatePassword(String password) {
    final l10n = AppLocalizations.of(context)!;
    if (password.isEmpty) return l10n.signUpPasswordRequired;
    if (password.length < 8) return l10n.signUpPasswordMinLength;
    if (!password.contains(RegExp(r'[A-Z]'))) return l10n.signUpPasswordUppercase;
    if (!password.contains(RegExp(r'[a-z]'))) return l10n.signUpPasswordLowercase;
    if (!password.contains(RegExp(r'[0-9]'))) return l10n.signUpPasswordNumber;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return l10n.signUpPasswordSpecialChar;
    return null;
  }

  List<String> _getFailedRequirements(String password) {
    List<String> failed = [];
    if (password.isEmpty) return failed;
    if (password.length < 8) failed.add('At least 8 characters');
    if (!password.contains(RegExp(r'[A-Z]'))) failed.add('One uppercase letter');
    if (!password.contains(RegExp(r'[a-z]'))) failed.add('One lowercase letter');
    if (!password.contains(RegExp(r'[0-9]'))) failed.add('One number');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) failed.add('One special character');
    return failed;
  }

  Future<void> _registerWithBackend() async {
    final username = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    setState(() => _isRegisterLoading = true);

    try {
      final registerResponse = await ApiService.register(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      );

      if (!mounted) return;
      await AuthSession.setBackendLoggedIn(
        email: email,
        username: username.isNotEmpty ? username : null,
        userId: registerResponse.userId,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      );

      await HapticFeedback.lightImpact();

      if (!mounted) return;

      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneController.clear();

      final l10n = AppLocalizations.of(context)!;
      _showSnack(l10n.signUpRegistrationSuccess, const Color(0xFF2E7D32));

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } on ApiException catch (e) {
      _triggerErrorShake();
      if (!mounted) return;
      _showSnack(e.message, Colors.red);
    } catch (error) {
      final l10n = AppLocalizations.of(context)!;
      _triggerErrorShake();
      if (!mounted) return;
      final message = error.toString().toLowerCase().contains('failed to fetch')
          ? l10n.signUpServerUnreachable
          : '${l10n.signUpFailed}: $error';
      _showSnack(message, Colors.red);
    } finally {
      if (mounted) setState(() => _isRegisterLoading = false);
    }
  }

  void _register() {
    final l10n = AppLocalizations.of(context)!;
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _emailError = _validateEmail(email);
      _passwordError = _validatePassword(password);
    });

    if (fullName.isEmpty) {
      _triggerErrorShake();
      _showSnack(l10n.signUpPleaseEnterFullName, Colors.red);
      return;
    }

    if (_emailError != null) {
      _triggerErrorShake();
      return;
    }

    if (_passwordError != null) {
      _triggerErrorShake();
      return;
    }

    if (password != confirmPassword) {
      _triggerErrorShake();
      setState(() => _passwordError = l10n.signUpPasswordsDoNotMatch);
      return;
    }

    _registerWithBackend();
  }

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: ApiConfig.googleWebClientId.isEmpty ? null : ApiConfig.googleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) {
          _showSnack(l10n.signUpGoogleCancelled, Colors.orange);
        }
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        if (mounted) {
          _showSnack(
            l10n.signUpGoogleFailed,
            Colors.red,
          );
        }
        return;
      }
      final loginResponse = await ApiService.loginWithGoogle(
        idToken: idToken ?? '',
        accessToken: accessToken,
      );
      await AuthSession.setBackendLoggedIn(
        email: loginResponse.email ?? account.email,
        username: loginResponse.username,
        userId: loginResponse.userId,
      );
      if (!mounted) return;

      await HapticFeedback.lightImpact();
      _showSnack(l10n.signUpSignedIn, const Color(0xFF2E7D32));

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(showLoginSuccess: true),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, Colors.red);
    } catch (e) {
      if (mounted) _showSnack('${l10n.signUpGoogleSignInFailed}: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _goToLogin() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildBackground(isDark, size),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeAnim.value * 8,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isSmallScreen ? 12 : 24,
                        24,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildBrandHeader(isDark),
                          const SizedBox(height: 16),
                          _buildWelcomeText(isDark),
                          const SizedBox(height: 20),
                          _buildFullNameField(isDark),
                          const SizedBox(height: 12),
                          _buildEmailField(isDark),
                          if (_emailError != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _emailError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildPhoneField(isDark),
                          const SizedBox(height: 12),
                          _buildPasswordField(isDark),
                          if (_passwordError != null && _passwordError != 'Passwords do not match') ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _passwordError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                          if (_passwordController.text.isNotEmpty && _getFailedRequirements(_passwordController.text).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _getFailedRequirements(_passwordController.text)
                                    .map((req) => Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            '• $req',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildConfirmPasswordField(isDark),
                          if (_passwordError != null && _passwordError!.contains('do not match')) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _passwordError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _buildSignUpButton(isDark),
                          const SizedBox(height: 16),
                          _buildDivider(isDark),
                          const SizedBox(height: 16),
                          _buildGoogleButton(isDark),
                          const SizedBox(height: 28),
                          _buildSignInRow(isDark),
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark, Size size) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(isDark: isDark),
      ),
    );
  }

  Widget _buildBrandHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco, size: 35, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 3),
                      Text(
                        'CD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppLocalizations.of(context)!.appBrandName.contains('Corn') ? 'Corn' : 'کورن',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1B5E20),
                  ),
                ),
                TextSpan(
                  text: AppLocalizations.of(context)!.appBrandName.contains('Corn') ? 'Care' : 'کیئر',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.appTagline,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.45)
                  : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.signUpTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1B5E20),
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.signUpSubtitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withOpacity(0.45)
                : Colors.grey.shade600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameField(bool isDark) {
    return _AnimatedField(
      isFocused: _nameFocus.hasFocus,
      isDark: isDark,
      child: TextField(
        controller: _fullNameController,
        focusNode: _nameFocus,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _emailFocus.requestFocus(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
          hintText: AppLocalizations.of(context)!.signUpFullNameHint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: _nameFocus.hasFocus
                  ? const Color(0xFF2E7D32)
                  : (isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.grey.shade700),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _buildEmailField(bool isDark) {
    return _AnimatedField(
      isFocused: _emailFocus.hasFocus,
      isDark: isDark,
      hasError: _emailError != null,
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _phoneFocus.requestFocus(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
          hintText: AppLocalizations.of(context)!.signUpEmailHint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 22,
              color: _emailError != null
                  ? Colors.red.shade400
                  : (_emailFocus.hasFocus
                      ? const Color(0xFF2E7D32)
                      : (isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.grey.shade700)),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return _AnimatedField(
      isFocused: _phoneFocus.hasFocus,
      isDark: isDark,
      child: TextField(
        controller: _phoneController,
        focusNode: _phoneFocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _passwordFocus.requestFocus(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
          hintText: AppLocalizations.of(context)!.signUpPhoneHint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.phone_outlined,
              size: 22,
              color: _phoneFocus.hasFocus
                  ? const Color(0xFF2E7D32)
                  : (isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.grey.shade700),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return _AnimatedField(
      isFocused: _passwordFocus.hasFocus,
      isDark: isDark,
      hasError: _passwordError != null && _passwordError != 'Passwords do not match',
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
          hintText: AppLocalizations.of(context)!.signUpPasswordHint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 22,
              color: (_passwordError != null && _passwordError != 'Passwords do not match')
                  ? Colors.red.shade400
                  : (_passwordFocus.hasFocus
                      ? const Color(0xFF2E7D32)
                      : (isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.grey.shade700)),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_isPasswordVisible),
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade700,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool isDark) {
    final hasConfirmError = _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text != _passwordController.text;
    return _AnimatedField(
      isFocused: _confirmPasswordFocus.hasFocus,
      isDark: isDark,
      hasError: hasConfirmError,
      child: TextField(
        controller: _confirmPasswordController,
        focusNode: _confirmPasswordFocus,
        obscureText: !_isConfirmPasswordVisible,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _register(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        onChanged: (value) {
          final l10n = AppLocalizations.of(context)!;
          if (value.isNotEmpty && value != _passwordController.text) {
            setState(() => _passwordError = l10n.signUpPasswordsDoNotMatch);
          } else if (value.isNotEmpty && _validatePassword(value) == null) {
            setState(() {
              if (_passwordError == l10n.signUpPasswordsDoNotMatch) {
                _passwordError = null;
              }
            });
          } else if (value.isEmpty) {
            setState(() {
              if (_passwordError == l10n.signUpPasswordsDoNotMatch) {
                _passwordError = null;
              }
            });
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
          hintText: AppLocalizations.of(context)!.signUpConfirmPasswordHint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 22,
              color: hasConfirmError
                  ? Colors.red.shade400
                  : (_confirmPasswordFocus.hasFocus
                      ? const Color(0xFF2E7D32)
                      : (isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.grey.shade700)),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_isConfirmPasswordVisible),
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade700,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRegisterLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isRegisterLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.signUpButton,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppLocalizations.of(context)!.signUpOrText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          backgroundColor:
              isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isGoogleLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF2E7D32),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.signUpGoogleSignIn,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.85)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSignInRow(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.signUpHaveAccount + " ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.45)
                  : Colors.grey.shade600,
            ),
          ),
          GestureDetector(
            onTap: _goToLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.signUpSignIn,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  final bool isFocused;
  final bool isDark;
  final bool hasError;
  final Widget child;

  const _AnimatedField({
    required this.isFocused,
    required this.isDark,
    this.hasError = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark
            ? (isFocused
                ? const Color(0xFF1E2D1E)
                : const Color(0xFF161F16))
            : (isFocused ? Colors.white : const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.shade400
              : (isFocused
                  ? const Color(0xFF2E7D32)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200)),
          width: hasError ? 1.5 : (isFocused ? 2 : 1.2),
        ),
        boxShadow: isFocused && !hasError
            ? [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final bool isDark;
  _BackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0A150A) : const Color(0xFFF8F9F8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final topPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF2E7D32).withOpacity(0.3),
                const Color(0xFF0A150A).withOpacity(0),
              ]
            : [
                const Color(0xFFE8F5E9).withOpacity(0.8),
                const Color(0xFFF8F9F8).withOpacity(0),
              ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, -size.height * 0.05),
          radius: size.width * 0.75,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.85, -size.height * 0.05),
      size.width * 0.75,
      topPaint,
    );

    final bottomPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF1B5E20).withOpacity(0.2),
                const Color(0xFF0A150A).withOpacity(0),
              ]
            : [
                const Color(0xFFC8E6C9).withOpacity(0.5),
                const Color(0xFFF8F9F8).withOpacity(0),
              ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 1.05),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 1.05),
      size.width * 0.65,
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.isDark != isDark;
}