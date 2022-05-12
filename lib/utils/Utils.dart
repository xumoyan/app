import 'package:polka_module/app.dart';
import 'package:polka_module/common/consts.dart';
import 'package:package_info/package_info.dart';

class Utils {
  static Future<int> getBuildNumber() async {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  }

  static Future<String> getAppVersion() async {
    return "${(await PackageInfo.fromPlatform()).version}-${WalletApp.buildTarget == BuildTargets.dev ? "dev" : "beta"}.${(await PackageInfo.fromPlatform()).buildNumber.substring((await PackageInfo.fromPlatform()).buildNumber.length - 1)}";
  }

  static String currencySymbol(String priceCurrency) {
    switch (priceCurrency) {
      case "USD":
        return "\$";
      case "CNY":
        return "￥";
      default:
        return "\$";
    }
  }

  static dynamic getParams(Map<String, dynamic> map) {
    if (map != null) {
      final Map<String, dynamic> arguments = Map<String, dynamic>.from(map);
      return arguments["params"];
    }
    return null;
  }
}
