import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'widgets/brand/brand_intros.dart';
import 'services/appearance_settings.dart';
import 'theme/theme.dart';

/// Run with --dart-define=USE_FIREBASE_EMULATORS=true to use the local
/// Firebase emulators (firebase emulators:start --only auth,firestore)
/// instead of the live project. Off by default.
const bool useFirebaseEmulators =
    bool.fromEnvironment('USE_FIREBASE_EMULATORS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await AppearanceSettings.load();
  runApp(const TriporaApp());
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (useFirebaseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
}

class TriporaApp extends StatelessWidget {
  const TriporaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the Appearance setting changes.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppearanceSettings.themeMode,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: useFirebaseEmulators ? 'Tripora (emulator)' : 'Tripora',
        theme: TriporaTheme.lightTheme,
        darkTheme: TriporaTheme.darkTheme,
        themeMode: mode,
        home: const LaunchIntroGate(child: AuthGate()),
      ),
    );
  }
}
