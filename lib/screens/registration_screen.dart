import 'package:flutter/material.dart';
import 'package:corn_disease_app/config/api_config.dart';
import 'package:corn_disease_app/services/api_service.dart';
import 'package:corn_disease_app/services/auth_session.dart';
import 'dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
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

  /// Register via backend API — user is stored in database, not Firebase.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registration successful! Account created.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneController.clear();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().toLowerCase().contains('failed to fetch')
          ? 'Cannot reach the server. If you\'re on web, the backend may need to allow this origin (CORS). See BACKEND_CORS.md.'
          : 'Registration failed: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegisterLoading = false);
    }
  }

  void _register() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    // Validation
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!_isEmailValid(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getEmailError(email)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!_isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getPasswordError(password)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _registerWithBackend();
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
      await AuthSession.setBackendLoggedIn(
        email: loginResponse.email ?? account.email,
        username: loginResponse.username,
        userId: loginResponse.userId,
      );
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

  void _showTermsAndPolicies() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Policies'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'By creating an account, you agree to our:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('• Terms of Service'),
              const Text('• Privacy Policy'),
              const Text('• Cookie Policy'),
              const SizedBox(height: 10),
              Text(
                'We will send a verification code to your email to confirm your account.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.green[900]),
                ),
                
                const SizedBox(height: 10),

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
                            border: Border.all(color: Colors.green[200]!, width: 2),
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
                
                const SizedBox(height: 10),
                
                Center(
                  child: Column(
                    children: [
                      Text(
                        'FARMER REGISTRATION',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Full Name Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Full Name',
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _emailError != null ? Colors.red.shade400 : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _emailController,
                    onChanged: _onEmailChanged,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                
                // Email validation error
                if (_emailError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _emailError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 10),
                
                // Phone Number (optional)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Phone number (optional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),

                const SizedBox(height: 10),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _passwordError != null ? Colors.red.shade400 : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    onChanged: _onPasswordChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                        },
                      ),
                    ),
                  ),
                ),
                
                // Professional Progressive Password Requirements
                if (_passwordController.text.isNotEmpty && _getFailedRequirements(_passwordController.text).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ..._getFailedRequirements(_passwordController.text)
                      .map((requirement) => Padding(
                            padding: const EdgeInsets.only(left: 4, top: 1),
                            child: Text(
                              '• $requirement',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.1,
                              ),
                            ),
                          ))
                      .toList(),
                ],
                
                // Password validation error
                if (_passwordError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _passwordError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 10),

                // Confirm Password Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _passwordError != null && _confirmPasswordController.text.isNotEmpty
                          ? Colors.red.shade400
                          : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    onChanged: _onConfirmPasswordChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRegisterLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isRegisterLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                
                const SizedBox(height: 10),
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
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
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
                const SizedBox(height: 15),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(color: Colors.grey[700])),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Sign in', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[400])),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isEmailValid(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false; // At least one uppercase
    if (!password.contains(RegExp(r'[a-z]'))) return false; // At least one lowercase
    if (!password.contains(RegExp(r'[0-9]'))) return false; // At least one digit
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false; // At least one special char
    return true;
  }

  List<String> _getFailedRequirements(String password) {
    List<String> failed = [];
    
    if (password.length < 8) failed.add('At least 8 characters');
    if (!password.contains(RegExp(r'[A-Z]'))) failed.add('One uppercase letter');
    if (!password.contains(RegExp(r'[a-z]'))) failed.add('One lowercase letter');
    if (!password.contains(RegExp(r'[0-9]'))) failed.add('One number');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) failed.add('One special character');
    
    return failed;
  }

  String _getEmailError(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!_isEmailValid(email)) return 'Please enter a valid email address';
    return '';
  }

  String _getPasswordError(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!_isPasswordValid(password)) return 'Password does not meet requirements';
    return '';
  }

  void _onEmailChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = null;
      } else if (_isEmailValid(value)) {
        _emailError = null;
      } else {
        _emailError = _getEmailError(value);
      }
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = null;
      } else if (_isPasswordValid(value)) {
        _passwordError = null;
      } else {
        _passwordError = _getPasswordError(value);
      }
    });
  }

  void _onConfirmPasswordChanged(String value) {
    if (value.isNotEmpty && value != _passwordController.text) {
      setState(() {
        _passwordError = 'Passwords do not match';
      });
    } else if (value.isNotEmpty && _isPasswordValid(value)) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}