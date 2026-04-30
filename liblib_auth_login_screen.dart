import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  String phoneNumber = '';
  String verificationId = '';
  String smsCode = '';
  bool isBiometricEnabled = false;

  Future<void> _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _postLoginSetup();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro')));
      },
      codeSent: (String vid, int? token) {
        setState(() => verificationId = vid);
      },
      codeAutoRetrievalTimeout: (String vid) {},
    );
  }

  Future<void> _signInWithOtp() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    _postLoginSetup();
  }

  Future<void> _postLoginSetup() async {
    if (isBiometricEnabled) {
      await _localAuth.authenticate(
        localizedReason: 'Ative biometria para login rápido',
        options: AuthenticationOptions(biometricOnly: true),
      );
      await _secureStorage.write(key: 'biometric_enabled', value: 'true');
    }
    Navigator.pushReplacementNamed(context, '/overlay');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nº Telefone (+351...)'),
              onChanged: (v) => phoneNumber = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: isBiometricEnabled,
                  onChanged: (v) => setState(() => isBiometricEnabled = v ?? false),
                ),
                const Text('Ativar biometria após login'),
              ],
            ),
            ElevatedButton(onPressed: _verifyPhoneNumber, child: const Text('Enviar OTP')),
            if (verificationId.isNotEmpty) ...[
              TextField(
                decoration: const InputDecoration(labelText: 'Código OTP'),
                onChanged: (v) => smsCode = v,
              ),
              ElevatedButton(onPressed: _signInWithOtp, child: const Text('Verificar')),
            ]
          ],
        ),
      ),
    );
  }
}