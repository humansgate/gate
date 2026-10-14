import 'package:humansgate/template/index.dart';

class ServiceTemplating {
  String render(String url, String challenge, int difficulty) {
    return index
        .substring(0) // copy
        .replaceAll('{{{challenge}}}', challenge)
        .replaceAll('{{{difficulty}}}', difficulty.toString())
        .replaceAll('{{{url}}}', url);
  }
}