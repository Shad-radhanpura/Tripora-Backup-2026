import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_firebase.dart';
import '../services/firestore_service.dart';
import '../services/login_page.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'admin_dashboard.dart';
import 'welcome_screen.dart';

/// First screen. Waits for Firebase Auth to restore any saved session, then
/// opens the Login page, or goes straight to the User Panel / Admin Panel
/// for someone who is still signed in.
///
/// The Admin Panel performs its own admins/{uid} role check, so an account
/// is never shown admin data just because it was routed there.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _start = _decide();

  Future<Widget> _decide() async {
    User? user;
    try {
      // On the web the saved session is restored asynchronously.
      user = await AppFirebase.auth
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      user = AppFirebase.auth.currentUser;
    }
    if (user == null) return const LoginPage();

    try {
      final isAdmin = await FirestoreService.isAdmin(user.uid)
          .timeout(const Duration(seconds: 12));
      return isAdmin ? const AdminDashboard() : const WelcomeScreen();
    } catch (e) {
      // Role unknown (offline, rules): ask for a fresh login, which shows
      // the exact reason, rather than guessing the panel.
      debugPrint('Startup role check failed: $e');
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _start,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        if (snapshot.hasError) return const LoginPage();
        return Scaffold(
          backgroundColor: context.palette.background,
          body: LoadingState(message: 'Opening Tripora…'),
        );
      },
    );
  }
}
