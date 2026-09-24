class AppConfig {
  static const String appName = 'Grand Elephants';
  static const String appSlogan = 'Move With Conviction';
  static const String appDescription =
      'Premium bags marketplace — handcrafted heritage bags, carried with conviction.';
  static const String tenantDefault = 'grand-elephants-default';

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://grand-elephants-api.godfreymoseskalambo.workers.dev');
}
