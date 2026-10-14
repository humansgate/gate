import 'dart:io';

import 'package:humansgate/dto/source.dart';
import 'package:humansgate/service/service_forward.dart';
import 'package:shelf/shelf.dart';

class ControllerForward {
  final ServiceForward _service;
  static const cookieId = 'HUMANSGATE';

  ControllerForward(this._service);

  Future<Response> handle(Request request) {
    if (request.url.path.startsWith(ServiceForward.powPage) &&
        request.url.queryParameters.containsKey('nonce')) {
      return handlePowVerify(request);
    }

    if (request.url.path.startsWith(ServiceForward.powPage)) {
      return handleWebPage(request);
    }

    final cookies = request.headers['Cookie'];
    final regex = RegExp('(?:^|;)\\s*$cookieId=([^;]*)');
    final Iterable<RegExpMatch> matches = regex.allMatches(cookies ?? '');
    final List<String> nonces = matches
        .map((match) => match.group(1)?.trim())
        .whereType<String>()
        .toList();

    return _service.forward(request, nonces);
  }

  Future<Response> handleWebPage(Request request) async {
    final String url = request.url.queryParameters['url']!;
    final String page = await _service.getWebPage(url, Source.fromRequest(request));
    return Response.ok(page, headers: {'Content-Type': 'text/html'});
  }

  Future<Response> handlePowVerify(Request request) async {
    final String nonce = request.url.queryParameters['nonce']!;
    final String url = request.url.queryParameters['url'] ?? '';
    if (await _service.verifyPow(Source.fromRequest(request), nonce)) {
      return Response.found('/$url', headers: {
        'Set-Cookie': '$cookieId=$nonce; Expires=${HttpDate.format(_service.nextExpirationDate)}'
      });
    }

    return Response.badRequest();
  }
}
