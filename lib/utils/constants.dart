// App-wide constants for Terra Vista
class AppConstants {
  // App Info
  static const String appName = 'Terra Vista';
  static const String appVersion = '1.0.0';

  // Colors - Terra Vista Theme (Cocoa/Earth tones)
  static const int primaryGreen = 0xFF5C8D5C;
  static const int darkGreen = 0xFF4A7C4A;
  static const int brownCocoa = 0xFFA67C52;
  static const int brownTag = 0xFF8B6F47;
  static const int lightGreen = 0xFF6B9B6B;

  static const int backgroundBlack = 0xFF000000;
  static const int cardDark = 0xFF1A1A1A;
  static const int cardMedium = 0xFF2A2A2A;

  static const int textWhite = 0xFFFFFFFF;
  static const int textGray = 0xFFB0B0B0;
  static const int textDarkGray = 0xFF808080;

  static const int deleteRed = 0xFFD32F2F;

  // Categories
  static const List<String> categories = [
    'INFRAESTRUTURAS',
    'PRODUÇÃO',
    'HISTÓRIA',
    'MEIO AMBIENTE',
    'CULTURA',
  ];

  // Default Admin Credentials
  static const String defaultAdminUsername = 'admin@terravista.org';
  static const String defaultAdminPassword = 'terravista2024';

  // QR Code Prefix
  static const String qrCodePrefix = 'QR: TV';

  // Database
  static const String databaseName = 'terra_vista.db';
  static const int databaseVersion = 2;
}
