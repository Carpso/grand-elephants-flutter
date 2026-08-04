class AppConfig {
  static const String appName = 'Sell On App';
  static const String appSlogan = 'Premium Marketplace & Luxury Heritage';
  static const String appDescription =
      'A state-of-the-art retail platform for premium heritage products.';
  static const String tenantDefault = 'grand-elephants-default';
  static const bool mockBackend = bool.fromEnvironment('MOCK_BACKEND', defaultValue: false);

  static const String lencoBaseUrl = 'https://api.lenco.co/access/v2';
  static String get lencoSecretKey =>
      const String.fromEnvironment('LENCO_SECRET_KEY');
  static String get lencoPublicKey =>
      const String.fromEnvironment('LENCO_PUBLIC_KEY');
  static String get lencoMerchantId =>
      const String.fromEnvironment('LENCO_MERCHANT_ID');

  static const String lipilaBaseUrl = 'https://api.lipila.dev';
  static const String lipilaCallbackUrl =
      'https://api.sellonapp.com/webhook/lipila';

  static const bool lipilaUseSandbox = false;
}
