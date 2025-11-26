final class ThreeDS2Configuration {
  final String requestorAppURL;

  ThreeDS2Configuration({
    required this.requestorAppURL,
  });

  @override
  String toString() {
    return 'ThreeDS2Configuration(requestorAppURL: $requestorAppURL)';
  }
}
