import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'providers/history_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'widgets/splash_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent with light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(AppConstants.backgroundBlack),
          primaryColor: const Color(AppConstants.primaryGreen),
          colorScheme: const ColorScheme.dark(
            primary: Color(AppConstants.primaryGreen),
            secondary: Color(AppConstants.primaryGreen),
            surface: Color(AppConstants.cardDark),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(AppConstants.cardDark),
            selectedItemColor: Color(AppConstants.primaryGreen),
            unselectedItemColor: Color(AppConstants.textDarkGray),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppConstants.primaryGreen),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        home: const SplashWrapper(),
      ),
    );
  }
}

// Wrapper to show splash screen then navigate to main
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkLoginStatus(); // Check saved session
      context.read<ContentProvider>().loadContents();
      context.read<HistoryProvider>().loadHistory();
    });
  }

  List<Widget> _getScreens() {
    final authProvider = context.watch<AuthProvider>();

    return [
      const HomeScreen(),
      const HistoryScreen(),
      authProvider.isAdmin ? const AdminDashboardScreen() : const LoginScreen(),
    ];
  }

  String _getBottomNavLabel(int index) {
    final authProvider = context.watch<AuthProvider>();

    if (index == 2) {
      return authProvider.isAdmin ? 'Admin' : 'Login';
    }
    return ['Início', 'Histórico'][index];
  }

  IconData _getBottomNavIcon(int index) {
    final authProvider = context.watch<AuthProvider>();

    if (index == 2) {
      return authProvider.isAdmin ? Icons.admin_panel_settings : Icons.login;
    }
    return [Icons.home, Icons.history][index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(AppConstants.cardMedium), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: List.generate(
            3,
            (index) => BottomNavigationBarItem(
              icon: Icon(_getBottomNavIcon(index)),
              label: _getBottomNavLabel(index),
            ),
          ),
        ),
      ),
    );
  }
}
