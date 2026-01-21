import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'screens/login_form.dart';
import 'screens/dashboard.dart';
import 'services/api_service.dart';

class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});

  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  
  bool _isChecking = true;
  bool _hasError = false;
  String _statusMessage = 'Checking your session...';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _logger.i('🔐 Starting authentication check');
    _startAuthCheck();
  }

  void _startAuthCheck() {
    // Use post frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    // Set timeout for entire auth check
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isChecking) {
        _handleError('Connection timeout');
      }
    });

    try {
      // CRITICAL: Check if storage is available first
      await _testSecureStorage();
      
      setState(() {
        _statusMessage = 'Checking login status...';
      });

      // Read credentials from secure storage
      final credentials = await _readCredentials();
      
      if (credentials.isLoggedIn && credentials.hasCredentialAndPassword) {
        await _validateCredentials(credentials);
      } else {
        await _redirectToLogin();
      }
    } catch (e, stackTrace) {
      _logger.e('Auth check failed', error: e, stackTrace: stackTrace);
      _handleError('Authentication error');
    } finally {
      _timeoutTimer?.cancel();
    }
  }

  Future<void> _testSecureStorage() async {
    try {
      await _storage.write(key: '_test', value: 'test');
      await _storage.read(key: '_test');
      await _storage.delete(key: '_test');
    } catch (e) {
      _logger.e('Secure storage test failed', error: e);
      throw Exception('Secure storage unavailable');
    }
  }

  Future<AuthCredentials> _readCredentials() async {
    final isLoggedIn = await _storage.read(key: 'isLoggedIn');
    final credential = await _storage.read(key: 'credential');
    final password = await _storage.read(key: 'password');
    final token = await _storage.read(key: 'token');

    return AuthCredentials(
      isLoggedIn: isLoggedIn == 'true',
      credential: credential,
      password: password,
      token: token,
    );
  }

  Future<void> _validateCredentials(AuthCredentials credentials) async {
    if (!mounted) return;

    setState(() {
      _statusMessage = 'Validating credentials...';
    });

    try {
      final response = await APIService.loginUser(
        credentials.credential!,
        credentials.password!,
      ).timeout(const Duration(seconds: 8));

      if (response != null && response['token'] != null) {
        await _handleSuccessfulLogin(response);
      } else {
        await _handleInvalidCredentials();
      }
    } on TimeoutException {
      _logger.w('Login validation timeout');
      await _handleInvalidCredentials();
    } catch (e, stackTrace) {
      _logger.e('Login validation failed', error: e, stackTrace: stackTrace);
      await _handleInvalidCredentials();
    }
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> response) async {
    if (!mounted) return;

    // Save new token
    await _storage.write(key: 'token', value: response['token']);
    
    // Save user data if available
    if (response['user'] != null) {
      await _storage.write(key: 'user_data', value: response['user'].toString());
    }

    _logger.i('✅ Login successful, token saved');

    setState(() {
      _statusMessage = 'Login successful!';
    });

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const Dashboard(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        ),
      );
    }
  }

  Future<void> _handleInvalidCredentials() async {
    _logger.w('Invalid credentials or session expired');
    
    // Clear all stored credentials
    await _clearStoredCredentials();
    
    if (mounted) {
      setState(() {
        _statusMessage = 'Session expired';
        _hasError = false; // This is expected flow, not an error
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      await _redirectToLogin();
    }
  }

  Future<void> _handleError(String message) async {
    if (!mounted) return;

    await _clearStoredCredentials();
    
    setState(() {
      _isChecking = false;
      _hasError = true;
      _statusMessage = message;
    });

    _logger.w('Auth check error: $message');
  }

  Future<void> _clearStoredCredentials() async {
    try {
      await _storage.delete(key: 'isLoggedIn');
      await _storage.delete(key: 'credential');
      await _storage.delete(key: 'password');
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'user_data');
    } catch (e) {
      _logger.e('Failed to clear credentials', error: e);
    }
  }

  Future<void> _redirectToLogin() async {
    if (!mounted) return;

    setState(() {
      _statusMessage = 'Redirecting to login...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const LoginForm(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    }
  }

  void _retryAuthCheck() {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
      _hasError = false;
      _statusMessage = 'Retrying...';
    });

    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _isChecking 
                    ? _buildLoadingIndicator()
                    : _buildErrorState(),
                const SizedBox(height: 20),
                _buildDebugInfo(),
              ],
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.lock, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'ChitChat',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Secure Authentication',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasError ? Colors.red : Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _statusMessage,
          style: TextStyle(
            color: _hasError ? Colors.red : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasError ? Colors.red : Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 40, color: Colors.red),
        ),
        const SizedBox(height: 20),
        Text(
          _statusMessage,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Please check your connection and try again',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 180,
          child: ElevatedButton(
            onPressed: _retryAuthCheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginForm()),
            );
          },
          child: const Text(
            'Go to Login',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Text(
        'v1.0.0 • Secure Connection',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _logger.i('🔒 Authentication check disposed');
    super.dispose();
  }
}

// Helper class for credentials
class AuthCredentials {
  final bool isLoggedIn;
  final String? credential;
  final String? password;
  final String? token;

  AuthCredentials({
    required this.isLoggedIn,
    this.credential,
    this.password,
    this.token,
  });

  bool get hasCredentialAndPassword => credential != null && password != null;
  bool get hasToken => token != null && token!.isNotEmpty;
}