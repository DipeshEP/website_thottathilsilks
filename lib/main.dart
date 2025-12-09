
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:imgwebsite/core/constants/colour_constants.dart';

import 'features/login/presentation/login_page.dart';
import 'features/home/presentation/pagess/home_page.dart';
import 'features/home/presentation/pagess/product_detail_page.dart';
import 'features/home/data/model/product_model.dart';
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
        primaryColor: WebColours.primaryColor,
        scaffoldBackgroundColor: WebColours.scaffoldBackgroundColor,
        fontFamily: 'Sans-serif',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/product':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args['product'] != null) {
              return MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: args['product'] as Product),
              );
            }
            // Fallback to home if product is missing
            return MaterialPageRoute(builder: (_) => const HomePage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}


