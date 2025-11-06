import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Import to check for web platform

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Platform-aware App Check initialization
  if (kIsWeb) {
    // For WEB: You need to set up reCAPTCHA v3 in your Firebase console 
    // and provide the site key here.
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key-goes-here'),
    );
  } else {
    // For ANDROID
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Poultry',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
            ),
            home: const LoginPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
