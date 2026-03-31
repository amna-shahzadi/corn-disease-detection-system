import 'package:flutter/material.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _isGoogleLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Persist backend session details (including location) to [AuthSession].
  /// This fetches the latest user profile from the backend using [userId]
  /// so that the dashboard can immediately show location-based tips after login.
  Future<void> _saveBackendSession(LoginResponse loginResponse, String fallbackEmail) async {
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
      } catch (_) {
        // If profile fetch fails, we still save the basic login info.
      }
    }

    await AuthSession.setBackendLoggedIn(
      email: email,
      username: username,
      userId: userId,
      phoneNumber: phoneNumber,
      location: location,
      profilePicture: profilePicture,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // App Logo
                Center(
                  child: SizedBox(
                    height: 120,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.eco, size: 50, color: Colors.green[800]),
                              const SizedBox(height: 5),
                              Text(
                                'CD',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // App Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        'CORN DISEASE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'DETECTOR',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                
                // Subtitle
                Center(
                  child: Text(
                    'Identify corn diseases in seconds.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),

                const SizedBox(height: 20),

                // Email/Phone Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      hintText: 'Enter your email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),

                const SizedBox(height: 10),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 10),

                // Continue with Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/images/google_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, size: 24, color: Colors.grey[700]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[400],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Sign up section
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      GestureDetector(
                        onTap: _goToSignUp,
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[400],
                          ),
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
    );
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: ApiConfig.googleWebClientId.isEmpty ? null : ApiConfig.googleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in was cancelled'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in on this browser did not return a usable token. Please try again or use email & password.'),
              backgroundColor: Colors.red,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen(showLoginSuccess: true)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging in...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final loginResponse = await ApiService.login(email: email, password: password);
      await _saveBackendSession(loginResponse, email);

      _emailController.clear();
      _passwordController.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(showLoginSuccess: true),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final errStr = error.toString().toLowerCase();
      final isInvalidCredential = errStr.contains('invalid-credential') ||
          errStr.contains('auth credential') ||
          errStr.contains('incorrect, malformed or has expired');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInvalidCredential
                ? 'Invalid email or password. Use the email and password you used to register (not Google).'
                : 'An error occurred: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}