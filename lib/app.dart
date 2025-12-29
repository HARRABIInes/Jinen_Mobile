import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
// ...existing code...
import 'screens/auth_screen.dart';
import 'screens/parent_dashboard.dart';
import 'screens/nursery_dashboard.dart';
import 'screens/nursery_setup_screen.dart';
import 'screens/nursery_search.dart';
import 'screens/nursery_details.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JINEN - Gestion de Garderie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Mobile container wrapper
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 448),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildCurrentScreen(appState),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(AppState appState) {
    switch (appState.currentScreen) {
      case ScreenType.auth:
        return const AuthScreen();
      case ScreenType.parentDashboard:
        return const ParentDashboard();
      case ScreenType.nurseryDashboard:
        return const NurseryDashboard();
      case ScreenType.nurserySetup:
        return const NurserySetupScreen();
      case ScreenType.search:
        return const NurserySearch();
      case ScreenType.nurseryDetails:
        return const NurseryDetails();
      default:
        return const AuthScreen();
    }
  }
}
