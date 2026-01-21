import 'package:flutter/material.dart';
import 'package:chitchat/internet_checker.dart';
import 'package:chitchat/screens/sign_up_form.dart';
import 'package:chitchat/screens/login_form.dart';
import 'package:chitchat/screens/forgot_password_form.dart';
import 'package:chitchat/screens/dashboard.dart';
import 'package:chitchat/screens/profile.dart';
import 'package:chitchat/screens/chat_page.dart';
import 'package:chitchat/screens/videos.dart';
import 'package:chitchat/screens/notifications_page.dart';
import 'package:chitchat/screens/chat_room_screen.dart';
import 'package:chitchat/screens/full_screen_story.dart';
import 'package:chitchat/widgets/app_shell.dart';

// Import the missing pages - adjust paths as needed
import 'package:chitchat/screens/home_page.dart';
import 'package:chitchat/screens/friends_page.dart';
import 'package:chitchat/screens/explore_page.dart';
import 'package:chitchat/screens/profile_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Initialize API service
void initializeAPIService() {
  // TODO: Initialize your API services here
  // Example:
  // ApiService.init();
  // Firebase.initializeApp();
  print('API Service Initialized');
}

void main() {
  // Add error handling for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Send to crash reporting service
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  initializeAPIService(); // Initialize API services
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChitChat',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      theme: _buildTheme(),
      home: const InternetChecker(), // Only splash screen
      routes: _buildRoutes(),
      onGenerateRoute: _onGenerateRoute,
      builder: (BuildContext context, Widget? child) {
        // Global error handling
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorDetails.exception.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Try to recover by going to dashboard
                        navigatorKey.currentState?.pushNamedAndRemoveUntil(
                          '/app-shell',
                          (route) => false,
                        );
                      },
                      child: const Text('Restart App'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
    );
  }

  /// Builds the global theme for the app.
  static ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Defines all the available routes in the app.
  static Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/sign-up': (context) => const SignUpForm(),
      '/login': (context) => const LoginForm(),
      '/forgot-password': (context) => const ForgotPasswordForm(),
      '/dashboard': (context) => const Dashboard(),
      '/profile': (context) => Profile(userProfile: null),
      '/chat': (context) => const ChatPage(),
      '/videos': (context) => const VideoPage(),
      '/friends': (context) => const PlaceholderScreen(title: 'Friends'),
      '/explore': (context) => const PlaceholderScreen(title: 'Explore'),
      '/home': (context) => const PlaceholderScreen(title: 'Home'),
      '/location': (context) => const PlaceholderScreen(title: 'Location'),
      '/challenges': (context) => const PlaceholderScreen(title: 'Challenges'),
      '/settings': (context) => const PlaceholderScreen(title: 'Settings'),
      '/app-shell': (context) => _buildAppShell(),
    };
  }

  /// Builds the AppShell with all required pages
  static Widget _buildAppShell() {
    return AppShell(
      pages: [
        // Home page
        _buildHomePage(),
        // Friends page
        _buildFriendsPage(),
        // Chats page
        const ChatPage(),
        // Explore page
        _buildExplorePage(),
        // Videos page
        const VideoPage(),
        // Profile page
        _buildProfilePage(),
      ],
    );
  }

  /// Helper method to build Home page
  static Widget _buildHomePage() {
    try {
      return const HomePage();
    } catch (e) {
      return const PlaceholderScreen(title: 'Home');
    }
  }

  /// Helper method to build Friends page
  static Widget _buildFriendsPage() {
    try {
      return const FriendsPage();
    } catch (e) {
      return const PlaceholderScreen(title: 'Friends');
    }
  }

  /// Helper method to build Explore page
  static Widget _buildExplorePage() {
    try {
      return const ExplorePage();
    } catch (e) {
      return const PlaceholderScreen(title: 'Explore');
    }
  }

  /// Helper method to build Profile page
  static Widget _buildProfilePage() {
    try {
      return const ProfilePage();
    } catch (e) {
      return Profile(userProfile: null);
    }
  }

  /// Handle dynamic routes with arguments
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // Handle chat room with chat argument
    if (settings.name == '/chat-room') {
      final chat = settings.arguments;
      if (chat == null) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Chat data is required')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (context) => ChatRoom(chat: chat),
      );
    }
    
    // Handle profile with user data
    if (settings.name == '/profile-detail') {
      final userData = settings.arguments;
      if (userData is! Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Invalid user data format')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (context) => Profile(userProfile: userData),
      );
    }
    
    // Handle full screen story
    if (settings.name == '/full-screen-story') {
      final storyData = settings.arguments;
      if (storyData is! Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Invalid story data format')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (context) => FullScreenStory(
          storyImage: storyData['storyImage'] ?? '',
          storyName: storyData['storyName'] ?? '',
          profileImage: storyData['profileImage'] ?? '',
        ),
      );
    }
    
    // Handle app shell route
    if (settings.name == '/app-shell') {
      return MaterialPageRoute(
        builder: (context) => _buildAppShell(),
      );
    }
    
    // Handle unknown routes (404)
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                '404',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/app-shell'),
                child: const Text('Go to Dashboard'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder screens for unimplemented features
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 20),
            Text(
              '$title Coming Soon',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This feature is under development',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
