import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner ad unit ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // You can add interstitial or rewarded ad unit IDs here later if needed
}
