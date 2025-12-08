
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:imgwebsite/core/constants/colour_constants.dart';

import 'features/login/presentation/login_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CalistoParkApp());
}

class CalistoParkApp extends StatelessWidget {
  const CalistoParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thottathil Silks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor:WebColours.primaryColor ,
        scaffoldBackgroundColor: WebColours.scaffoldBackgroundColor ,
        fontFamily: 'Sans-serif',
      ),
      home: const LoginPage(),
    );
  }
}


