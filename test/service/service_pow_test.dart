import 'package:humansgate/dto/source.dart';
import 'package:humansgate/service/service_pow.dart';
import 'package:test/test.dart';

void main() {
  test('verify Pow', () {
    final challenge = '4kYylQ9JZfeSk4+hJTq/6g==';
    final nonce = '0DquAwAAAAAAAAH9AAAACw==';

    final service = ServicePow(16);
    expect(service.verifyPow(challenge: challenge, nonce: nonce), true);
    expect(service.verifyPow(challenge: challenge, nonce: 'none'), false);
  });

  test('compute challenge', () {
    final service = ServicePow(16);
    final t1 = DateTime.now();
    final s1 = Source(ip: '1.1.1.1', agent: 'Mozilla');
    final s2 = Source(ip: '2.2.2.2', agent: 'Mozilla');
    final s3 = Source(ip: '1.1.1.1', agent: 'Chrome');
    final t2 = DateTime.now();


    final s1t1 = service.computeChallenge(s1, t1);
    final s2t1 = service.computeChallenge(s2, t1);
    final s3t1 = service.computeChallenge(s3, t1);
    final s1t2 = service.computeChallenge(s1, t2);

    expect(s1t1 == s2t1, false);
    expect(s1t1 == s3t1, false);
    expect(s1t1 == s1t2, false);
  });
}