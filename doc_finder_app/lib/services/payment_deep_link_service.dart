import 'dart:async';

class PaymentDeepLinkService {
  static final PaymentDeepLinkService _instance =
      PaymentDeepLinkService._internal();
  factory PaymentDeepLinkService() => _instance;
  PaymentDeepLinkService._internal();

  final _controller = StreamController<Uri>.broadcast();
  Stream<Uri> get stream => _controller.stream;

  void handle(Uri uri) => _controller.add(uri);
}
