import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dashboard.dart';
import 'sign_up_form.dart';
import 'forget_password_form.dart';
import 'services/api_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _loginAttempts = 0;
  DateTime? _lastFailedAttempt;
  Timer? _loginTimer;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    _loginTimer?.cancel();
    super.dispose();
    debugPrint('LoginForm disposed');
  }

  /// Load remembered credentials if available
  Future<void> _loadRememberedCredentials() async {
    try {
      final rememberedEmail = await _storage.read(key: 'remembered_email');
      final rememberedUsername = await _storage.read(key: 'remembered_username');
      
      if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
        _credentialController.text = rememberedEmail;
        setState(() => _rememberMe = true);
      } else if (rememberedUsername != null && rememberedUsername.isNotEmpty) {
        _credentialController.text = rememberedUsername;
        setState(() => _rememberMe = true);
      }
    } catch (e) {
      debugPrint('Failed to load remembered credentials: $e');
    }
  }

  /// Save credentials for "Remember Me"
  Future<void> _saveRememberedCredentials() async {
    if (!_rememberMe) {
      await _storage.delete(key: 'remembered_email');
      await _storage.delete(key: 'remembered_username');
      return;
    }

    final credential = _credentialController.text.trim();
    if (credential.contains('@')) {
      await _storage.write(key: 'remembered_email', value: credential);
    } else {
      await _storage.write(key: 'remembered_username', value: credential);
    }
  }

  /// Show user feedback message
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

  /// Check if login is rate limited
  bool _isRateLimited() {
    if (_lastFailedAttempt == null) return false;
    
    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(_lastFailedAttempt!);
    
    // Lock for 5 minutes after 5 failed attempts
    if (_loginAttempts >= 5 && timeSinceLastAttempt.inMinutes < 5) {
      return true;
    }
    
    // Reset attempts after 5 minutes
    if (timeSinceLastAttempt.inMinutes >= 5) {
      _loginAttempts = 0;
    }
    
    return false;
  }

  /// Handle login process
  Future<void> _handleLogin() async {
    if (!mounted) return;
    
    if (_isRateLimited()) {
      _showMessage('Too many attempts. Please try again in 5 minutes.', color: Colors.orange);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showMessage('Please fill in all fields correctly.', color: Colors.orange);
      return;
    }

    _formKey.currentState!.save();
    
    final credential = _credentialController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email/username and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await APIService.loginUser(credential, password)
          .timeout(const Duration(seconds: 15));

      setState(() => _isLoading = false);

      if (response['token'] != null && response['error'] == null) {
        // Login successful
        debugPrint('✅ Login successful for: $credential');
        _loginAttempts = 0;
        
        // Save remembered credentials
        await _saveRememberedCredentials();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Dashboard(),
              settings: const RouteSettings(name: '/dashboard'),
            ),
          );
        }
      } else {
        _loginAttempts++;
        _lastFailedAttempt = DateTime.now();
        
        final error = response['error'] ?? 'Login failed. Please try again.';
        final requiresLogin = response['requiresLogin'] ?? false;
        
        if (requiresLogin) {
          _showMessage('Session expired. Please login again.', color: Colors.orange);
        } else if (response['statusCode'] == 429) {
          _showMessage('Too many attempts. Please wait.', color: Colors.orange);
        } else if (response['networkError'] == true) {
          _showMessage('No internet connection. Please check your network.', color: Colors.orange);
        } else if (response['timeout'] == true) {
          _showMessage('Connection timeout. Please try again.', color: Colors.orange);
        } else {
          _showMessage(error);
        }
      }
    } on TimeoutException {
      setState(() => _isLoading = false);
      _loginAttempts++;
      _lastFailedAttempt = DateTime.now();
      _showMessage('Connection timeout. Please check your internet.');
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      _loginAttempts++;
      _lastFailedAttempt = DateTime.now();
      debugPrint('Login error: $e\n$stackTrace');
      _showMessage('An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purpleAccent, Colors.blueAccent],
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
                    const SizedBox(height: 40),
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
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            Icons.chat_bubble,
            size: 50,
            color: Colors.purpleAccent,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome to ChitChat',
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
        const Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
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
          children: [
            _buildInputField(
              controller: _credentialController,
              icon: Icons.alternate_email,
              hint: 'Email or Username',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email or username';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRememberMe(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 20),
            _buildForgotPassword(),
            const SizedBox(height: 24),
            _buildSignUpPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
        hintText: 'Password',
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
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() => _rememberMe = value ?? false);
          },
          activeColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Text(
          'Remember me',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ForgotPasswordForm(),
            settings: const RouteSettings(name: '/forgot-password'),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text(
        'Forgot Password?',
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
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
              "Don't have an account?",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpForm(),
                    settings: const RouteSettings(name: '/sign-up'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text(
                'Sign Up',
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