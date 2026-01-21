import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'login_form.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  bool _codeVerified = false;
  bool _passwordReset = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _resendCooldown = 0;
  Timer? _resendTimer;
  Timer? _redirectTimer;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    _redirectTimer?.cancel();
    super.dispose();
    debugPrint('ForgotPasswordForm disposed');
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showMessage(String message, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleSendResetLink() async {
    if (!mounted) return;
    
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please enter a valid email address.', color: Colors.orange);
      return;
    }

    final email = _emailController.text.trim();
    
    setState(() => _isLoading = true);

    try {
      final response = await APIService.forgotPassword(email)
          .timeout(const Duration(seconds: 15));

      setState(() {
        _isLoading = false;
        _emailSent = response['error'] == null;
      });

      if (_emailSent) {
        _showMessage('✅ Password reset link sent to $email', color: Colors.green);
        
        // Start resend cooldown
        _startResendTimer();
      } else {
        final error = response['error'] ?? 'Failed to send reset link.';
        final statusCode = response['statusCode'];
        
        if (statusCode == 404) {
          _showMessage('No account found with this email address.');
        } else if (statusCode == 429) {
          _showMessage('Too many attempts. Please try again later.', color: Colors.orange);
        } else {
          _showMessage(error);
        }
      }
    } on TimeoutException {
      setState(() => _isLoading = false);
      _showMessage('Connection timeout. Please check your internet.');
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('Forgot password error: $e\n$stackTrace');
      _showMessage('An error occurred. Please try again.');
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!mounted) return;
    
    final code = _verificationCodeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      _showMessage('Please enter a valid 6-digit code.', color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // This would typically call an API endpoint to verify the code
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _isLoading = false;
        _codeVerified = true;
        _resetToken = 'simulated_token_${DateTime.now().millisecondsSinceEpoch}';
      });
      
      _showMessage('✅ Code verified successfully!', color: Colors.green);
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('Code verification error: $e\n$stackTrace');
      _showMessage('Invalid verification code. Please try again.');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!mounted) return;
    
    if (!_validatePasswords()) return;

    setState(() => _isLoading = true);

    try {
      // This would typically call an API endpoint to reset password
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _isLoading = false;
        _passwordReset = true;
      });
      
      _showMessage('✅ Password reset successfully!', color: Colors.green);
      
      // Auto-redirect to login after 3 seconds
      _redirectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginForm(),
              settings: const RouteSettings(name: '/login'),
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('Password reset error: $e\n$stackTrace');
      _showMessage('Failed to reset password. Please try again.');
    }
  }

  bool _validatePasswords() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please enter both password fields.', color: Colors.orange);
      return false;
    }
    
    if (newPassword.length < 8) {
      _showMessage('Password must be at least 8 characters.', color: Colors.orange);
      return false;
    }
    
    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match.', color: Colors.orange);
      return false;
    }
    
    return true;
  }

  void _resendResetLink() {
    if (_resendCooldown > 0) {
      _showMessage('Please wait $_resendCooldown seconds before resending.', color: Colors.orange);
      return;
    }
    
    _handleSendResetLink();
  }

  void _goBack() {
    if (_passwordReset) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginForm(),
          settings: const RouteSettings(name: '/login'),
        ),
      );
    } else if (_codeVerified) {
      setState(() => _codeVerified = false);
    } else if (_emailSent) {
      setState(() => _emailSent = false);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBack,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 30),
                    _buildFormContainer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 50,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _passwordReset ? 'Password Reset Successfully!' :
          _codeVerified ? 'Create New Password' :
          _emailSent ? 'Enter Verification Code' :
          'Enter your email to receive a reset link',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_passwordReset) _buildSuccessMessage(),
            if (_codeVerified && !_passwordReset) _buildPasswordResetForm(),
            if (_emailSent && !_codeVerified) _buildVerificationForm(),
            if (!_emailSent && !_passwordReset) _buildEmailForm(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildLoginPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        const Text(
          'Password Reset Successfully!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password has been updated successfully.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Redirecting to login in 3 seconds...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
            hintText: 'your.email@example.com',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a verification code to your email.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _verificationCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 16, color: Colors.black87, letterSpacing: 4),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.sms, color: Colors.blueAccent),
            hintText: '123456',
            hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 4),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.trim().length != 6) {
              return 'Code must be 6 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Enter the 6-digit code sent to your email.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _resendCooldown == 0 ? _resendResetLink : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                _resendCooldown > 0 ? 'Resend in $_resendCooldown' : 'Resend Code',
                style: TextStyle(
                  color: _resendCooldown > 0 ? Colors.grey : Colors.blueAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
            hintText: 'Enter new password',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a new password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
            hintText: 'Confirm new password',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a strong password with at least 8 characters.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_passwordReset) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginForm(),
                settings: const RouteSettings(name: '/login'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: const Text(
            'Back to Login',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    
    if (_codeVerified) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: Colors.blueAccent.withOpacity(0.3),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }
    
    if (_emailSent) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: Colors.blueAccent.withOpacity(0.3),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Verify Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendResetLink,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Colors.blueAccent.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Column(
      children: [
        const Divider(
          color: Colors.grey,
          thickness: 0.5,
          height: 1,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Remembered your password?',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginForm(),
                    settings: const RouteSettings(name: '/login'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}