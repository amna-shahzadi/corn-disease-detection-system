import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../l10n/app_localizations.dart';
import 'registration_screen.dart';
import 'forget_password_screen.dart';
import 'dashboard_screen.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _saveBackendSession(
      LoginResponse loginResponse, String fallbackEmail) async {
    String? userId = loginResponse.userId;
    String? username = loginResponse.username;
    String email = (loginResponse.email ?? fallbackEmail).trim();
    String? phoneNumber;
    String? location;
    String? profilePicture;

    if (userId != null && userId.isNotEmpty) {
      try {
        final profile = await ApiService.getUserProfile(userId);
        username = profile.username ?? username;
        email = (profile.email ?? email).trim();
        phoneNumber = profile.phoneNumber;
        location = profile.location;
        profilePicture = profile.profilePicture;
      } catch (_) {}
    }

    await AuthSession.setBackendLoggedIn(
      email: email,
      username: username,
      userId: userId,
      phoneNumber: phoneNumber,
      location: location,
      profilePicture: profilePicture,
      accessToken: loginResponse.accessToken,
    );
  }

  void _triggerErrorShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  String? _validateEmail(String email) {
    final l10n = AppLocalizations.of(context)!;
    if (email.isEmpty) return l10n.loginEmail;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return l10n.errorInvalidEmail;
    }
    return null;
  }

  String? _validatePassword(String password) {
    final l10n = AppLocalizations.of(context)!;
    if (password.isEmpty) return l10n.loginPassword;
    if (password.length < 6) return l10n.errorWeakPassword;
    return null;
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = _validateEmail(email);
      _passwordError = _validatePassword(password);
    });

    if (_emailError != null || _passwordError != null) {
      _triggerErrorShake();
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final loginResponse =
          await ApiService.login(email: email, password: password);
      await _saveBackendSession(loginResponse, email);
      
      await HapticFeedback.lightImpact();
      
      if (!mounted) return;
      
      _emailController.clear();
      _passwordController.clear();
      
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
      _triggerErrorShake();
      if (mounted) _showSnack(e.message, Colors.red);
    } catch (error) {
      _triggerErrorShake();
      if (!mounted) return;
      final errStr = error.toString().toLowerCase();
      final isInvalidCredential = errStr.contains('invalid-credential') ||
          errStr.contains('auth credential') ||
          errStr.contains('incorrect, malformed or has expired');
      final l10n = AppLocalizations.of(context)!;
      _showSnack(
        isInvalidCredential
            ? l10n.errorInvalidCredentials
            : l10n.errorSomethingWentWrong,
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    
    try {
      final l10n = AppLocalizations.of(context)!;
      final googleSignIn = GoogleSignIn(
        clientId: ApiConfig.googleWebClientId.isEmpty
            ? null
            : ApiConfig.googleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) {
          _showSnack(l10n.errorSomethingWentWrong, Colors.orange);
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
            'Google sign-in failed. Try email & password.',
            Colors.red,
          );
        }
        return;
      }
      
      final loginResponse = await ApiService.loginWithGoogle(
        idToken: idToken ?? '',
        accessToken: accessToken,
      );
      await _saveBackendSession(loginResponse, account.email);
      
      if (!mounted) return;
      
      await HapticFeedback.lightImpact();
      _showSnack('Signed in successfully', const Color(0xFF2E7D32));
      
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
      if (mounted) _showSnack('Google sign-in failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _goToSignUp() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegistrationScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
                          _buildPasswordField(isDark),
                          if (_passwordError != null) ...[
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
                          const SizedBox(height: 8),
                          _buildForgotPassword(isDark),
                          const SizedBox(height: 20),
                          _buildSignInButton(isDark),
                          const SizedBox(height: 16),
                          _buildDivider(isDark),
                          const SizedBox(height: 16),
                          _buildGoogleButton(isDark),
                          const SizedBox(height: 28),
                          _buildSignUpRow(isDark),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loginTitle,
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
          l10n.loginSubtitle,
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

  Widget _buildEmailField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return _AnimatedField(
      isFocused: _emailFocus.hasFocus,
      isDark: isDark,
      hasError: _emailError != null,
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
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
          hintText: l10n.loginEmailHint,
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

  Widget _buildPasswordField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return _AnimatedField(
      isFocused: _passwordFocus.hasFocus,
      isDark: isDark,
      hasError: _passwordError != null,
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscureText,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _login(),
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
          hintText: l10n.loginPasswordHint,
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
              color: _passwordError != null
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
              key: ValueKey(_obscureText),
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade700,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _obscureText = !_obscureText);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          l10n.loginForgotPassword,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFF4CAF50)
                : const Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1B5E20).withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.loginButton,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
            AppLocalizations.of(context)!.orText,
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.loginGoogleSignIn,
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

  Widget _buildSignUpRow(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.loginDontHaveAccount,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.3,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: _goToSignUp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                l10n.loginSignUp,
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

    // Top accent
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

    // Bottom accent
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