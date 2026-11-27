
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../screens/welcome_screen.dart';
import '../screens/admin_dashboard.dart';
import '../widgets/brand/brand_intros.dart';
import '../widgets/brand/tripora_brand.dart';
import '../theme/theme.dart';
import '../widgets/destination_image.dart';
import 'firestore_service.dart';
import 'signup_page.dart';
import 'app_firebase.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Color get primary => context.palette.blue;
  Color get secondary => context.palette.navy;
  Color get dark => context.palette.text;
  Color get muted => context.palette.muted;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHero(),
              _buildLoginCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A verified catalogue photo (Lake Pichola, Udaipur). Falls back to
          // the brand gradient while loading or if the photo is unavailable.
          DestinationImage(url: DestinationCatalog.byId('udaipur')?.imageUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.15),
                  secondary.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Positioned(
            top: 25,
            left: 22,
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const TriporaLogo(height: 32, showWordmark: false),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIPORA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'AI Travel Planner',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            left: 22,
            right: 22,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your next adventure\nstarts here. 🌍',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Plan smarter. Explore more. Travel better.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back 👋',
              style: TextStyle(
                color: dark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Continue planning your next journey.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 22),
            _label('Email address'),
            const SizedBox(height: 7),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _label('Password'),
            const SizedBox(height: 7),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: primary,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.coral,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.palette.coral.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login to Tripora',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 9),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 17),
            Center(
              child: GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignupPage(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontFamily: 'Roboto'),
                    children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: 'Create account',
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: context.palette.surfaceTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF16803A),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your travel planning stays simple and secure.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: dark,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _login() async {
    // Ignore repeated taps / Enter presses while a login is in progress.
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    // Admins sign in with a normal Firebase account. Admin access is decided
    // after sign-in by the admins/{uid} document with role "admin"
    // (see FirestoreService.isAdmin), never by an email or a stored password.

    if (!email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await AppFirebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'unknown');
      }

      // Record the sign-in (lastLoginAt, loginCount) and repair a missing
      // profile document. A failure here never blocks the login.
      // Runs in parallel with the role check below instead of before it.
      final recordLogin = FirestoreService.recordLogin(user)
          .timeout(const Duration(seconds: 10))
          .catchError((Object e) {
        debugPrint('Could not record login activity: $e');
      });

      // Role check by UID. It is awaited before any navigation. If the role
      // cannot be verified, the user is signed out and told why, instead of
      // being sent to the User Panel by mistake.
      final bool isAdmin;
      try {
        isAdmin = await FirestoreService.isAdmin(user.uid)
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('Admin role check failed: $e');
        await _signOutQuietly();
        if (!mounted) return;
        _showMessage(_roleCheckError(e), seconds: 6);
        return;
      }

      await recordLogin;
      if (!mounted) return;

      _showMessage(
        isAdmin
            ? 'Welcome back, admin.'
            : 'Login successful! Welcome to Tripora.',
      );

      // Authentication has succeeded, so the welcome intro may play once.
      PostAuthWelcome.request();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PostAuthWelcomeGate(
            child: isAdmin
                ? const AdminDashboard(roleVerified: true)
                : const WelcomeScreen(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Incorrect email or password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await AppFirebase.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out after failed role check failed: $e');
    }
  }

  String _roleCheckError(Object error) {
    const prefix = 'Signed in, but your account role could not be verified';
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return '$prefix: Firestore security rules denied reading '
              'admins/{uid} (permission-denied). Please contact the admin.';
        case 'unavailable':
          return '$prefix: the database is unreachable. Check your internet '
              'connection and try again.';
        default:
          return '$prefix (${error.code}). Please try again.';
      }
    }
    if (error is TimeoutException) {
      return '$prefix: the check timed out. Check your internet connection '
          'and try again.';
    }
    return '$prefix. Please try again.';
  }

  void _showMessage(String message, {int seconds = 3}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: Duration(seconds: seconds),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
