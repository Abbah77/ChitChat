import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/dashboard.dart';
import 'screens/login_form.dart';

class InternetChecker extends StatefulWidget {
  const InternetChecker({Key? key}) : super(key: key);

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  int _currentDot = 0;
  Timer? _dotTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // Logo scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
    
    _startDotAnimation();
    _startAppInitialization();
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted || _isNavigating) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentDot = (_currentDot + 1) % 5;
      });
    });
  }

  Future<void> _startAppInitialization() async {
    // Start background initialization immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted || _isNavigating) return;

    try {
      // Check for cached user data (instant operation)
      final hasToken = await _storage.read(key: 'token') != null;
      final isLoggedIn = await _storage.read(key: 'isLoggedIn') == 'true';
      final hasCachedUser = hasToken && isLoggedIn;
      
      // Facebook-style timing: show animation for 1.5-2s
      await Future.delayed(const Duration(milliseconds: 1800));
      
      // Navigate based on cache
      if (hasCachedUser) {
        await _navigateToDashboard();
      } else {
        await _navigateToLogin();
      }
    } catch (e) {
      // Silent fallback to login
      await _navigateToLogin();
    }
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted || _isNavigating) return;

    _isNavigating = true;
    _dotTimer?.cancel();

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
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

  Future<void> _navigateToLogin() async {
    if (!mounted || _isNavigating) return;

    _isNavigating = true;
    _dotTimer?.cancel();

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const LoginForm(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _dotTimer?.cancel();
    super.dispose();
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
                _buildAppLogo(),
                const SizedBox(height: 50),
                _buildFacebookStyleDots(),
                const Spacer(),
                _buildAppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
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
            child: const Icon(Icons.chat_bubble, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'ChitChat',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacebookStyleDots() {
    return SizedBox(
      width: 80,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isActive = index == _currentDot;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAppFooter() {
    return const Column(
      children: [
        SizedBox(height: 20),
        Divider(color: Colors.grey, height: 1),
        SizedBox(height: 16),
        Text(
          'ChitChat Messenger',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'v1.0.0',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}