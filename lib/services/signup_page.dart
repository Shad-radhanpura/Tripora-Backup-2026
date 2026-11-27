
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../screens/welcome_screen.dart';
import '../theme/theme.dart';
import '../widgets/brand/brand_intros.dart';
import '../widgets/destination_image.dart';
import 'app_firebase.dart';

class SignupPage extends StatefulWidget {
const SignupPage({super.key});

@override
State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  Color get primary => context.palette.blue;
  Color get secondary => context.palette.navy;
  Color get dark => context.palette.text;
  Color get muted => context.palette.muted;

final nameController = TextEditingController();
final emailController = TextEditingController();
final passwordController = TextEditingController();
final confirmController = TextEditingController();

bool obscurePassword = true;
bool obscureConfirm = true;
bool isLoading = false;

@override
void dispose() {
nameController.dispose();
emailController.dispose();
passwordController.dispose();
confirmController.dispose();
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
_buildForm(),
const SizedBox(height: 25),
],
),
),
),
);
}

Widget _buildHero() {
return SizedBox(
height: 265,
child: Stack(
fit: StackFit.expand,
children: [
// A verified catalogue photo (Goa). Falls back to the brand gradient while
// loading or if the photo is unavailable.
DestinationImage(url: DestinationCatalog.byId('goa')?.imageUrl),
Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
primary.withValues(alpha: 0.20),
secondary.withValues(alpha: 0.92),
],
),
),
),
Positioned(
top: 18,
left: 18,
child: GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(
width: 43,
height: 43,
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.92),
shape: BoxShape.circle,
),
child: Icon(
Icons.arrow_back_rounded,
color: dark,
size: 21,
),
),
),
),
const Positioned(
left: 22,
bottom: 25,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Join TRIPORA 🌍',
style: TextStyle(
color: Colors.white,
fontSize: 30,
fontWeight: FontWeight.w900,
),
),
SizedBox(height: 7),
Text(
'Your personalized travel journey starts here.',
style: TextStyle(
color: Colors.white70,
fontSize: 11,
),
),
],
),
),
],
),
);
}

Widget _buildForm() {
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
'Start your journey ✨',
style: TextStyle(
color: dark,
fontSize: 23,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 5),
Text(
'Create your Tripora account.',
style: TextStyle(
color: muted,
fontSize: 12,
),
),
const SizedBox(height: 21),

_label('Full name'),
const SizedBox(height: 7),
TextField(
controller: nameController,
textInputAction: TextInputAction.next,
decoration: InputDecoration(
hintText: 'Your name',
prefixIcon: Icon(
Icons.person_outline_rounded,
color: primary,
),
),
),

const SizedBox(height: 14),
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

const SizedBox(height: 14),
_label('Password'),
const SizedBox(height: 7),
TextField(
controller: passwordController,
obscureText: obscurePassword,
textInputAction: TextInputAction.next,
decoration: InputDecoration(
hintText: 'Create a password',
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

const SizedBox(height: 14),
_label('Confirm password'),
const SizedBox(height: 7),
TextField(
controller: confirmController,
obscureText: obscureConfirm,
textInputAction: TextInputAction.done,
onSubmitted: (_) => _createAccount(),
decoration: InputDecoration(
hintText: 'Enter password again',
prefixIcon: Icon(
Icons.lock_reset_rounded,
color: primary,
),
suffixIcon: IconButton(
onPressed: () {
setState(() {
obscureConfirm = !obscureConfirm;
});
},
icon: Icon(
obscureConfirm
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
onPressed: isLoading ? null : _createAccount,
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
'Create My Account',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w900,
),
),
SizedBox(width: 9),
Text(
'✨',
style: TextStyle(fontSize: 17),
),
],
),
),
),

const SizedBox(height: 18),
Center(
child: GestureDetector(
onTap: isLoading ? null : () => Navigator.pop(context),
child: RichText(
text: TextSpan(
style: TextStyle(fontFamily: 'Roboto'),
children: [
TextSpan(
text: 'Already have an account? ',
style: TextStyle(
color: muted,
fontSize: 12,
),
),
TextSpan(
text: 'Login',
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

const SizedBox(height: 16),
Container(
padding: const EdgeInsets.all(11),
decoration: BoxDecoration(
color: context.palette.surfaceTint,
borderRadius: BorderRadius.circular(14),
),
child: Row(
children: [
Icon(
Icons.shield_outlined,
color: Color(0xFF16803A),
size: 18,
),
SizedBox(width: 8),
Expanded(
child: Text(
'Your account is protected by Firebase Authentication.',
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

// CREATE ACCOUNT AND SAVE USER DETAILS
Future<void> _createAccount() async {
final name = nameController.text.trim();
final email = emailController.text.trim();
final password = passwordController.text;
final confirm = confirmController.text;

if (name.isEmpty ||
email.isEmpty ||
password.isEmpty ||
confirm.isEmpty) {
_showMessage('Please complete all fields.');
return;
}

if (name.length < 2) {
_showMessage('Please enter your full name.');
return;
}

if (!email.contains('@')) {
_showMessage('Please enter a valid email address.');
return;
}

if (password.length < 6) {
_showMessage('Password must be at least 6 characters.');
return;
}

if (password != confirm) {
_showMessage('Passwords do not match.');
return;
}

setState(() {
isLoading = true;
});

try {
// 1. Create the Firebase Authentication account.
final UserCredential userCredential =
await AppFirebase.auth.createUserWithEmailAndPassword(
email: email,
password: password,
);

final User? user = userCredential.user;

if (user == null) {
throw Exception('User account was not created.');
}

// 2. Save the name in the Firebase Authentication profile.
await user.updateDisplayName(name);

// 3. Save the user's details in the existing Firestore collection.
await AppFirebase.db
    .collection('users')
    .doc(user.uid)
    .set({
'uid': user.uid,
'name': name,
'email': email,
'createdAt': FieldValue.serverTimestamp(),
// Signing up also signs the user in, so it counts as the first login.
'lastLoginAt': FieldValue.serverTimestamp(),
'loginCount': 1,
});

if (!mounted) return;

_showMessage('Account created successfully! Welcome to Tripora.');

await Future.delayed(const Duration(milliseconds: 700));

if (!mounted) return;

// 4. Open the user welcome screen.
PostAuthWelcome.request();
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => PostAuthWelcomeGate(child: const WelcomeScreen()),
),
(route) => false,
);
} on FirebaseAuthException catch (e) {
if (!mounted) return;

String message;

switch (e.code) {
case 'email-already-in-use':
message = 'An account already exists with this email.';
break;
case 'invalid-email':
message = 'Please enter a valid email address.';
break;
case 'weak-password':
message = 'Password is too weak. Use at least 6 characters.';
break;
case 'operation-not-allowed':
message =
'Email/password authentication is not enabled in Firebase.';
break;
case 'too-many-requests':
message = 'Too many attempts. Please try again later.';
break;
case 'network-request-failed':
message =
'Network error. Please check your internet connection.';
break;
default:
message = 'Account creation failed. Please try again.';
}

_showMessage(message);
} on FirebaseException catch (e) {
if (!mounted) return;

// Authentication succeeded but the Firestore profile write failed.
// The profile is repaired automatically on the next login, so continue
// into the app instead of leaving the user stuck on this page.
debugPrint('Profile write failed after signup: ${e.code}');
_showMessage(
'Account created, but profile details could not be saved yet '
'(${e.code}). They will be saved on your next login.',
);

await Future.delayed(const Duration(milliseconds: 1500));

if (!mounted) return;

PostAuthWelcome.request();
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => PostAuthWelcomeGate(child: const WelcomeScreen()),
),
(route) => false,
);
} catch (e) {
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

void _showMessage(String message) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
margin: const EdgeInsets.all(16),
duration: const Duration(seconds: 3),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
);
}
}
