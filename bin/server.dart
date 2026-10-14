import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:humansgate/client/client_forward.dart';
import 'package:humansgate/controller/controller_forward.dart';
import 'package:humansgate/service/service_pow.dart';
import 'package:humansgate/service/service_forward.dart';
import 'package:humansgate/service/service_templating.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';


void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final String target = Platform.environment['TARGET'] ?? '';
  final String difficulty = Platform.environment['DIFFICULTY'] ?? '16';
  final String expiration = Platform.environment['SESSION_EXPIRATION_MIN'] ?? '1';
  final String whitelist = Platform.environment['WHITELIST'] ?? '.well-know,robots.txt,favicon.ico';

  final httpClient = HttpClient()
    ..maxConnectionsPerHost = 32
    ..idleTimeout = const Duration(seconds: 30)
    ..connectionTimeout = const Duration(seconds: 10);

  final http.Client client = IOClient(httpClient);
  final ClientForward clientForward = ClientForward(target, client);
  final ServiceTemplating templating = ServiceTemplating();
  final ServicePow toll = ServicePow(int.parse(difficulty));
  final ServiceForward serviceProxy = ServiceForward(clientForward, templating, toll, whitelist.split(','));

  final ControllerForward controller = ControllerForward(serviceProxy);

  serviceProxy.startCron(Duration(minutes: int.parse(expiration)));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(controller.handle);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
