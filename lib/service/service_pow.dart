import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:humansgate/dto/source.dart';

class ServicePow {
  final int difficulty;

  ServicePow(this.difficulty);


  String computeChallenge(Source source, DateTime expiration) {
    final challenge = sha256.convert([expiration.microsecondsSinceEpoch, source.hashCode]).bytes;
    return base64Encode(challenge.sublist(0, 16));
  }

  bool verifyPow({
    required String challenge,
    required String nonce,
  }) {
    final total = base64Decode(challenge) + base64Decode(nonce);

    final digest = sha256.convert(total);
    final hashBytes = digest.bytes;

    // Count leading zero bits
    int leadingZeros = 0;
    for (final byte in hashBytes) {
      if (byte == 0) {
        leadingZeros += 8;
        continue;
      }
      int b = byte;
      while ((b & 0x80) == 0) {
        leadingZeros++;
        b <<= 1;
      }
      break;
    }

    return leadingZeros >= difficulty;
  }

}