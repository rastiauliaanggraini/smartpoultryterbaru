import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Aktifkan App Check. Ini akan secara otomatis menggunakan provider yang benar
  // untuk platform (web atau Android) tempat aplikasi berjalan.
  await FirebaseAppCheck.instance.activate(
    // Untuk WEB: Anda perlu mengatur reCAPTCHA v3 di konsol Firebase Anda
    // dan memberikan kunci situs di sini.
    web: ReCaptchaV3Provider('your-recaptcha-site-key-goes-here'),
    // Untuk ANDROID: Ini menggunakan Play Integrity. Untuk mode debug, Anda akan menggunakan
    // AndroidProvider.debug.
    android: AndroidProvider.playIntegrity,
  );

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
