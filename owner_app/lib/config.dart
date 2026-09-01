import 'services/remote_config.dart';

class AppConfig {
  /// Local computer / device IP address for local development
  static const String serverIp = '10.21.170.176';
  
  static const String port = '8000';
  static const String apiVersion = 'v1';

  /// Default static Base URL before remote config resolves
  static String get defaultBaseUrl {
    if (serverIp.startsWith('http')) {
      return serverIp;
    }
    return 'http://$serverIp:$port/api/$apiVersion';
  }

  /// Dynamic Base URL updated automatically from RemoteConfig server response (or fallback to local IP)
  static String get baseUrl {
    if (RemoteConfig.apiBaseUrl != null && RemoteConfig.apiBaseUrl!.startsWith('http')) {
      return RemoteConfig.apiBaseUrl!;
    }
    return defaultBaseUrl;
  }

  /// Dynamic API Secret Key fetched automatically from server
  static String? get apiSecret => RemoteConfig.apiSecret;
}
