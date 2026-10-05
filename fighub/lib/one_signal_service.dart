import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String appId =
      'e8996f31-dd11-4713-ae16-5e8e8635e737';

  Future<void> initialize({
    required String userId,
  }) async {
    OneSignal.Debug.setLogLevel(
      OSLogLevel.verbose,
    );

    OneSignal.initialize(appId);

    await OneSignal.Notifications.requestPermission(
      true,
    );

    await OneSignal.login(userId);
  }

  Future<void> logout() async {
    await OneSignal.logout();
  }
}
