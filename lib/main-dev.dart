import 'package:polka_module/app.dart';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/common/types/pluginDisabled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_chainx/polkawallet_plugin_chainx.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';

void main() async {
  // FlutterBugly.postCatchedException(() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await GetStorage.init(get_storage_container);

  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginChainX(),
  ];

  runApp(WalletApp(
      plugins,
      [
        PluginDisabled(
            'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.dev));
  //   FlutterBugly.init(
  //     androidAppId: "64c2d01918",
  //     iOSAppId: "3803dd717e",
  //   );
  // });
}
