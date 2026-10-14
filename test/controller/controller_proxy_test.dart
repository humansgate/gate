import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:humansgate/client/client_forward.dart';
import 'package:humansgate/controller/controller_forward.dart';
import 'package:humansgate/dto/source.dart';
import 'package:humansgate/service/service_pow.dart';
import 'package:humansgate/service/service_forward.dart';
import 'package:humansgate/service/service_templating.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';


class MockServicePow extends ServicePow {
  final String challenge;

  MockServicePow(this.challenge): super(16);

  @override
  String computeChallenge(Source source, DateTime expiration) {
    return challenge;
  }
}

void main() {
  const fixedChallenge = '4kYylQ9JZfeSk4+hJTq/6g==';
  const validNonce = '0DquAwAAAAAAAAH9AAAACw==';

  late ControllerForward controller;
  Uri? lastForwardedUri;

  setUp(() {
    lastForwardedUri = null;

    final mockClient = MockClient((request) async {
      lastForwardedUri = request.url;
      return http.Response('Hello from origin', 200, headers: {
        'content-type': 'text/plain',
      });
    });

    final clientForward = ClientForward('http://origin.local', mockClient);
    final templating = ServiceTemplating();
    final pow = MockServicePow(fixedChallenge);
    final serviceForward = ServiceForward(clientForward, templating, pow, const []);
    serviceForward.startCron(const Duration(minutes: 5));

    controller = ControllerForward(serviceForward);
  });

  Request buildRequest(String path, {Map<String, String>? headers}) {
    return Request('GET', Uri.parse('http://localhost/$path'), headers: headers);
  }

  test('mypage -> challenge redirect -> valid nonce -> forwarded to origin', () async {
    // 1. First hit on a protected page with no cookie -> redirected to the
    //    humansgate challenge page, nothing forwarded upstream yet.
    final firstResponse = await controller.handle(buildRequest('mypage'));

    expect(firstResponse.statusCode, 302);
    final challengeLocation = firstResponse.headers['location'];
    expect(challengeLocation, isNotNull);
    expect(challengeLocation, contains('humansgatepow.html'));
    expect(challengeLocation, contains('url=mypage'));
    expect(lastForwardedUri, isNull);

    // 2. Submit the (fake) valid nonce to the challenge endpoint -> redirected
    //    back to the originally requested page, with a session cookie set.
    final verifyResponse = await controller.handle(
      buildRequest('humansgatepow.html?nonce=$validNonce&url=mypage'),
    );

    expect(verifyResponse.statusCode, 302);
    expect(verifyResponse.headers['location'], '/mypage');

    final setCookie = verifyResponse.headers['set-cookie'];
    expect(setCookie, isNotNull);
    expect(setCookie, contains('HUMANSGATE=$validNonce'));
    expect(lastForwardedUri, isNull);

    final cookieValue = RegExp('HUMANSGATE=([^;]+)').firstMatch(setCookie!)!.group(1)!;
    expect(cookieValue, validNonce);

    // 3. Retry the original page with the cookie -> request is forwarded
    //    straight through to the origin server.
    final forwardedResponse = await controller.handle(
      buildRequest('mypage', headers: {'Cookie': 'HUMANSGATE=$cookieValue'}),
    );

    expect(forwardedResponse.statusCode, 200);
    expect(await forwardedResponse.readAsString(), 'Hello from origin');
    expect(lastForwardedUri, isNotNull);
    expect(lastForwardedUri!.path, '/mypage');
  });

  test('invalid nonce is rejected and does not forward to origin', () async {
    final response = await controller.handle(
      buildRequest('humansgatepow.html?nonce=4ECFAgAAAAEACip5AAABeA==&url=mypage'),
    );

    expect(response.statusCode, 400);
    expect(lastForwardedUri, isNull);
  });
}