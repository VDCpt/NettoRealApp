import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'lib_auth_login_screen.dart';
import 'lib_ui_main_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey = 'pk_live_example_substituir'; // trocar pela chave real
  runApp(NettoRealApp());
}

class NettoRealApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NettoReal',
      theme: ThemeData.dark(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/overlay': (context) => MainOverlay(),
      },
    );
  }
}