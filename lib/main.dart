import 'package:polka_module/app.dart';
import 'package:polka_module/common/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_plugin_chainx/polkawallet_plugin_chainx.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:polka_module/life-cycle.dart';

void main() async {
  PageVisibilityBinding.instance.addGlobalObserver(AppLifecycleObserver());
  CustomFlutterBinding();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemUiOverlayStyle systemUiOverlayStyle =
      SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  await GetStorage.init(get_storage_container);
  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginChainX(),
  ];

  runApp(WalletApp(
      plugins,
      [
        // PluginDisabled(
        //     'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.apk));
  //   FlutterBugly.init(
  //     androidAppId: "64c2d01918",
  //     iOSAppId: "3803dd717e",
  //   );
  // });
}

class CustomFlutterBinding extends WidgetsFlutterBinding
    with BoostFlutterBinding {}
