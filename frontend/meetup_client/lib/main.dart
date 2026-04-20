import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/profile_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Requires google-services.json to be present)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e. Ensure config files are added.');
  }

  final authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider(create: (_) => ApiService()),
        Provider.value(value: authService),
        ProxyProvider<ApiService, ProfileService>(
          update: (_, api, __) => ProfileService(api),
        ),
      ],
      child: const DeluluApp(),
    ),
  );
}

class DeluluApp extends StatelessWidget {
  const DeluluApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Delulu : Social Connections',
      debugShowCheckedModeBanner: false,
      theme: themeService.themeData,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
        
        // Handle auth-based routing logic elsewhere or here
        // For simplicity, we use explicit routes
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const ProfileSetupScreen(),
        '/home': (context) => const Scaffold(body: Center(child: Text('Home Screen'))),
      },
    );
  }
}
