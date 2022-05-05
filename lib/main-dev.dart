import 'package:polka_module/app.dart';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/common/types/pluginDisabled.dart';
import 'package:polka_module/service/walletApi.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_bifrost/polkawallet_plugin_bifrost.dart';
import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_plugin_laminar/polkawallet_plugin_laminar.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(get_storage_container);
  // await Firebase.initializeApp();

  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginKarura(),
    PluginStatemine(),
    PluginAcala(),
    PluginBifrost(),
    // PluginChainX(),
    PluginEdgeware(),
    PluginLaminar(),
  ];

  final pluginsConfig = await WalletApi.getPluginsConfig();
  if (pluginsConfig != null) {
    plugins.removeWhere((i) {
      final List disabled = pluginsConfig[i.basic.name]['disabled'];
      if (disabled != null) {
        return disabled.contains(app_beta_version_code);
      }
      return false;
    });
  }

  runApp(WalletApp(
      plugins,
      [
        PluginDisabled(
            'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.dev));
}
