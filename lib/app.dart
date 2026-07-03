import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/setup_screen.dart';
import 'screens/main/main_shell.dart';
import 'core/theme.dart';

class BudgetlyApp extends StatelessWidget {
  const BudgetlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Budgetly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          }
          if (auth.needsGoogleSetup) {
            return const SetupScreen();
          }
          return auth.isLoggedIn ? const MainShell() : const AuthScreen();
        },
      ),
    );
  }
}
