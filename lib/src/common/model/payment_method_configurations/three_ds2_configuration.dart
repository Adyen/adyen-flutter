/// Configuration for 3DS2 authentication.
///
/// This configuration is used to provide the requestorAppURL for 3DS2 authentication.
/// The requestorAppURL is used by the 3DS2 SDK to redirect the user back to the app
/// after completing the authentication flow.
final class ThreeDS2Configuration {
  /// The URL that will be used by the 3DS2 SDK to redirect back to the app.
  ///
  /// This URL should be registered as a custom URL scheme in your app.
  final String requestorAppURL;
  
  /// Creates a new instance of [ThreeDS2Configuration].
  ///
  /// [requestorAppURL] is required and should be a valid URL that your app can handle.
  ThreeDS2Configuration({
    required this.requestorAppURL,
  });
  
  @override
  String toString() {
    return 'ThreeDS2Configuration(requestorAppURL: $requestorAppURL)';
  }
}
