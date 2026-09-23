class AppConfig {
  static const String appName = 'Sell On App';
  static const String appSlogan = 'Premium Marketplace & Luxury Heritage';
  static const String appDescription =
      'A state-of-the-art retail platform for premium heritage products.';
  static const String tenantDefault = 'grand-elephants-default';

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://grand-elephants-api.godfreymoseskalambo.workers.dev');
}
