import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 1; // 1 = email, 2 = code, 3 = new password
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password validation functions
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

  String _getPasswordError(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!_isPasswordValid(password)) return 'Password does not meet requirements';
    return '';
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
    if (value.isNotEmpty && value != _newPasswordController.text) {
      setState(() {
        _passwordError = 'Passwords do not match';
      });
    } else if (value.isNotEmpty && _isPasswordValid(value)) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_step == 1) {
      await _sendResetCode();
    } else if (_step == 2) {
      _goToPasswordStep();
    } else {
      await _submitNewPassword();
    }
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    // Basic email format check
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A 6-digit code has been sent to your email'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      setState(() {
        _step = 2;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send code: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToPasswordStep() {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the verification code sent to your email'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }
    setState(() {
      _step = 3;
    });
  }

  Future<void> _submitNewPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter and confirm your new password'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    // Validate password requirements
    if (!_isPasswordValid(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getPasswordError(newPassword)),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password has been reset successfully'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      // After success, navigate back to login.
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _title {
    switch (_step) {
      case 2:
        return 'Enter Verification Code';
      case 3:
        return 'Reset Password';
      default:
        return 'Forgot Password';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 2:
        return 'Enter the 6-digit code sent to your email.';
      case 3:
        return 'Create a new password for your account.';
      default:
        return 'Enter your email to reset your password.';
    }
  }

  String get _primaryButtonText {
    switch (_step) {
      case 2:
        return 'Continue';
      case 3:
        return 'Save New Password';
      default:
        return 'Send Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                onPressed: () {
                  if (_step > 1) {
                    setState(() {
                      _step--;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 40),

              // Lock Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Center(
                child: Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 97, 97, 97),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (_step == 1) ...[
                // Email field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Enter your email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ] else if (_step == 2) ...[
                // Code field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Enter 6-digit code',
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
              ] else ...[
                // New Password field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _passwordError != null ? Colors.red.shade400 : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    onChanged: _onPasswordChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'New password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                // Professional Progressive Requirements
                if (_newPasswordController.text.isNotEmpty && _getFailedRequirements(_newPasswordController.text).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ..._getFailedRequirements(_newPasswordController.text)
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
                const SizedBox(height: 16),
                // Confirm Password field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _passwordError != null && _confirmPasswordController.text.isNotEmpty
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    onChanged: _onConfirmPasswordChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Confirm new password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // Primary Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _primaryButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Back to Login - Black color as shown in the image
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 33, 33, 33), // Black color as in the image
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}