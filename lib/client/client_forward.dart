import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

class ClientForward {
  final Uri _targetUri;
  final http.Client _client;



  // Reuse a single client across all requests for keep-alive / pooling.
  ClientForward(String target, http.Client client)
      : _targetUri = Uri.parse(target), _client = client;

  static const _excludedHeaders = {
    'host',
    'content-length',
    'transfer-encoding',
    'connection',
    'content-encoding'
  };

  Future<Response> forward(Request request) async {
    final targetUrl = _targetUri.resolveUri(
      Uri(
        path: _targetUri.path + request.requestedUri.path,
        query: request.requestedUri.hasQuery ? request.requestedUri.query : null,
      ),
    );
    print(targetUrl);

    // Stream the incoming body instead of buffering it as a String.
    final forward = http.StreamedRequest(request.method, targetUrl);

    // pass headers from request to forward, remove header set by http client
    request.headers.forEach((key, value) {
      if (!_excludedHeaders.contains(key.toLowerCase())) {
        forward.headers[key] = value;
      }
    });
    forward.headers['host'] = _targetUri.host;

    // Pipe the request body through without collecting it in memory.
    request.read().listen(
          (chunk) => forward.sink.add(
        chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
      ),
      onError: forward.sink.addError,
      onDone: forward.sink.close,
      cancelOnError: true,
    );

    try {
      final response = await _client.send(forward);

      // pass headers from response to forward, remove header set by http client
      final responseHeaders = <String, String>{};
      response.headers.forEach((key, value) {
        if (!_excludedHeaders.contains(key.toLowerCase())) {
          responseHeaders[key] = value;
        }
      });

      // Stream the response body straight back to the caller.
      return Response(
        response.statusCode,
        headers: responseHeaders,
        body: response.stream,
      );
    } catch (e) {
      return Response.internalServerError(body: 'Proxy error: $e\n');
    }
  }

  void close() => _client.close();
}