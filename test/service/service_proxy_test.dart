import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:humansgate/client/client_forward.dart';
import 'package:humansgate/service/service_pow.dart';
import 'package:humansgate/service/service_forward.dart';
import 'package:humansgate/service/service_templating.dart';
import 'package:shelf/shelf.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'service_proxy_test.mocks.dart';

class MockRequest extends Request {
  MockRequest(String url): super('GET', Uri.parse('http://localhost/$url'));
}


@GenerateMocks([ClientForward, ServiceTemplating, ServicePow])
void main() {
  final forward = MockClientForward();
  final templating = MockServiceTemplating();
  final pow = MockServicePow();
  late ServiceForward service;

  void expectRedirect(Response res) {
    expect(res.statusCode == HttpStatus.found, true);
    verifyZeroInteractions(forward);
  }

  void expectForward(Response res) {
    expect(res.statusCode == HttpStatus.found, false);
    verify(forward.forward(any));
  }

  setUp(() {
    reset(forward);
    reset(templating);
    reset(pow);

    service = ServiceForward(forward, templating, pow, ['robot.txt']);
    when(forward.forward(any)).thenAnswer((_) => Future.value(Response(200)));
    when(pow.computeChallenge(any, any)).thenReturn('challenge');
  });



  test('forward whitelist', () async {
    final res = await service.forward(MockRequest('robot.txt'), []);
    expectForward(res);
  });

  test('forward nonces empty', () async {
    final res = await service.forward(MockRequest(''), []);
    expectRedirect(res);
  });

  test('forward nonces validated', () async {
    when(pow.verifyPow(challenge: anyNamed('challenge'), nonce: anyNamed('nonce'))).thenAnswer((_) => true);
    final res = await service.forward(MockRequest(''), ['good']);
    expectForward(res);
  });

  test('forward nonces invalidated', () async {
    when(pow.verifyPow(challenge: anyNamed('challenge'), nonce: anyNamed('nonce'))).thenAnswer((_) => false);
    final res = await service.forward(MockRequest(''), ['wrong']);
    expectRedirect(res);
  });
}