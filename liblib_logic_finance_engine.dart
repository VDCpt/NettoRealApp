import 'dart:convert';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceEngine {
  static const double IVA_RATE = 0.06;
  static const double APP_FEE_RATE = 0.25;
  static const double GPL_OFFSET_PER_100KM = 0.05;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyKey = 'aes_key';

  Future<Uint8List> _getOrCreateKey() async {
    String? keyBase64 = await _secureStorage.read(key: _encryptionKeyKey);
    if (keyBase64 != null) {
      return base64.decode(keyBase64);
    }
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          DateTime.now().millisecondsSinceEpoch.toRadixString(16).codeUnits)));
    final key = Uint8List(32);
    secureRandom.nextBytes(key);
    await _secureStorage.write(key: _encryptionKeyKey, value: base64.encode(key));
    return key;
  }

  Future<String> encryptProfit(double lucroNetto) async {
    final key = await _getOrCreateKey();
    final iv = Uint8List(16);
    final secureRandom = SecureRandom('Fortuna')..seed(KeyParameter(key));
    secureRandom.nextBytes(iv);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv));
    final plaintext = utf8.encode(lucroNetto.toString());
    final padded = _padPlaintext(plaintext, cipher.blockSize);
    final encrypted = Uint8List(padded.length);
    cipher.processBytes(padded, 0, padded.length, encrypted, 0);
    final finalBlock = cipher.doFinal();
    final encryptedBytes = Uint8List(encrypted.length + finalBlock.length)
      ..setAll(0, encrypted)
      ..setAll(encrypted.length, finalBlock);
    final result = Uint8List(iv.length + encryptedBytes.length)
      ..setAll(0, iv)
      ..setAll(iv.length, encryptedBytes);
    return base64.encode(result);
  }

  List<int> _padPlaintext(List<int> input, int blockSize) {
    final padLen = blockSize - (input.length % blockSize);
    final padded = List<int>.from(input)..addAll(List.filled(padLen, padLen));
    return padded;
  }

  // NOVA FUNÇÃO com cpkReal (custo por km real do motorista)
  double calcularLucroNetto({
    required double bruto,
    required double taxaFrotista,
    required double distanciaKm,
    required double cpkReal,
    bool isGPL = false,
  }) {
    final iva = bruto * IVA_RATE;
    final taxaApp = bruto * APP_FEE_RATE;
    final base = bruto - iva - taxaApp;

    double gplOffset = 0.0;
    if (isGPL) {
      gplOffset = (distanciaKm / 100) * GPL_OFFSET_PER_100KM;
    }

    double lucro = (base * (1 - taxaFrotista)) - (distanciaKm * cpkReal);
    lucro = lucro + gplOffset;

    return double.parse(lucro.toStringAsFixed(2));
  }
}