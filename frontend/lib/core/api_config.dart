class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration aiTimeout = Duration(seconds: 25);
  static const Duration networkTimeout = Duration(seconds: 10);
}
