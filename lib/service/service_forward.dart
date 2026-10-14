import 'dart:async';

import 'package:humansgate/client/client_forward.dart';
import 'package:humansgate/dto/source.dart';
import 'package:humansgate/service/service_templating.dart';
import 'package:humansgate/service/service_pow.dart';
import 'package:shelf/shelf.dart';

class ServiceForward {
  static const powPage = 'humansgatepow.html';

  final ClientForward _clientForward;
  final ServiceTemplating _templating;
  final ServicePow _toll;
  final List<String> whitelist;

  DateTime _nextExpirationDate = DateTime.now();

  DateTime get nextExpirationDate {
   return _nextExpirationDate;
 }

  ServiceForward(this._clientForward, this._templating, this._toll, this.whitelist);

  void startCron(Duration validityPeriod) {
    Timer.periodic(validityPeriod, (timer) {
      _nextExpirationDate = DateTime.now().add(validityPeriod);
    });

    _nextExpirationDate = DateTime.now().add(validityPeriod);
  }

  Future<Response> forward(Request request, List<String> nonces) async {
    final url = request.url.toString();

    if (whitelist.contains(url)) {
      return _clientForward.forward(request);
    }

    final redirect = Response.found('${request.url.host}/$powPage?url=$url');
    if (nonces.isEmpty) {
      return redirect;
    }

    final List<bool> validated = await nonces.map((nonce) => verifyPow(Source.fromRequest(request), nonce)).wait;
    if (validated.contains(true)) {
      return _clientForward.forward(request);
    }

    return redirect;
  }

  Future<String> getWebPage(String url, Source source) async {
    return _templating.render(url, _toll.computeChallenge(source, _nextExpirationDate), _toll.difficulty);
  }

  Future<bool> verifyPow(Source source, String nonce) async {
    return _toll.verifyPow(challenge: _toll.computeChallenge(source, _nextExpirationDate), nonce: nonce);
  }
}