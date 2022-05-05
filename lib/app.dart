import 'package:polka_module/common/consts.dart';
import 'package:polka_module/common/types/pluginDisabled.dart';
import 'package:polka_module/pages/account/create/backupAccountPage.dart';
import 'package:polka_module/pages/account/create/createAccountPage.dart';
import 'package:polka_module/pages/account/createAccountEntryPage.dart';
import 'package:polka_module/pages/assets/announcementPage.dart';
import 'package:polka_module/pages/assets/asset/assetPage.dart';
import 'package:polka_module/pages/assets/asset/locksDetailPage.dart';
import 'package:polka_module/pages/assets/manage/manageAssetsPage.dart';
import 'package:polka_module/pages/assets/transfer/detailPage.dart';
import 'package:polka_module/pages/assets/transfer/transferPage.dart';
import 'package:polka_module/pages/homePage.dart';
import 'package:polka_module/pages/networkSelectPage.dart';
import 'package:polka_module/pages/profile/aboutPage.dart';
import 'package:polka_module/pages/profile/acalaCrowdLoan/acaCrowdLoanFormPage.dart';
import 'package:polka_module/pages/profile/acalaCrowdLoan/acaCrowdLoanPage.dart';
import 'package:polka_module/pages/profile/account/accountManagePage.dart';
import 'package:polka_module/pages/profile/account/changeNamePage.dart';
import 'package:polka_module/pages/profile/account/changePasswordPage.dart';
import 'package:polka_module/pages/profile/account/exportAccountPage.dart';
import 'package:polka_module/pages/profile/account/exportResultPage.dart';
import 'package:polka_module/pages/profile/account/signPage.dart';
import 'package:polka_module/pages/profile/contacts/contactPage.dart';
import 'package:polka_module/pages/profile/contacts/contactsPage.dart';
import 'package:polka_module/pages/profile/crowdLoan/contributePage.dart';
import 'package:polka_module/pages/profile/crowdLoan/crowdLoanPage.dart';
import 'package:polka_module/pages/profile/recovery/createRecoveryPage.dart';
import 'package:polka_module/pages/profile/recovery/friendListPage.dart';
import 'package:polka_module/pages/profile/recovery/initiateRecoveryPage.dart';
import 'package:polka_module/pages/profile/recovery/recoveryProofPage.dart';
import 'package:polka_module/pages/profile/recovery/recoverySettingPage.dart';
import 'package:polka_module/pages/profile/recovery/recoveryStatePage.dart';
import 'package:polka_module/pages/profile/recovery/txDetailPage.dart';
import 'package:polka_module/pages/profile/recovery/vouchRecoveryPage.dart';
import 'package:polka_module/pages/profile/settings/remoteNodeListPage.dart';
import 'package:polka_module/pages/profile/settings/settingsPage.dart';
import 'package:polka_module/pages/public/adPage.dart';
import 'package:polka_module/pages/public/guidePage.dart';
import 'package:polka_module/pages/public/karCrowdLoanFormPage.dart';
import 'package:polka_module/pages/public/karCrowdLoanPage.dart';
import 'package:polka_module/pages/public/karCrowdLoanWaitPage.dart';
import 'package:polka_module/pages/walletConnect/walletConnectSignPage.dart';
import 'package:polka_module/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:polka_module/pages/walletConnect/wcSessionsPage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/store/index.dart';
import 'package:polka_module/utils/UI.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_analytics/observer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/pages/walletExtensionSignPage.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:flutter/cupertino.dart';

import 'pages/account/import/importAccountCreatePage.dart';
import 'pages/account/import/importAccountFormKeyStore.dart';
import 'pages/account/import/importAccountFormMnemonic.dart';
import 'pages/account/import/importAccountFromRawSeed.dart';
import 'pages/account/import/selectImportTypePage.dart';

const get_storage_container = 'configuration';

bool _isInitialUriHandled = false;

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins, this.disabledPlugins, this.buildTarget);
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final BuildTargets buildTarget;
  @override
  _WalletAppState createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  // final _analytics = FirebaseAnalytics();

  Keyring _keyring;

  AppStore _store;
  AppService _service;

  ThemeData _theme;

  Locale _locale;

  NetworkParams _connectedNode;

  ThemeData _getAppTheme(MaterialColor color, {Color secondaryColor}) {
    return ThemeData(
      primarySwatch: color,
      accentColor: secondaryColor,
      textTheme: TextTheme(
          headline1: TextStyle(
            fontSize: 24,
          ),
          headline2: TextStyle(
            fontSize: 22,
          ),
          headline3: TextStyle(
            fontSize: 20,
          ),
          headline4: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          button: TextStyle(
            color: Colors.white,
            fontSize: 18,
          )),
    );
  }

  void _changeLang(String code) {
    _service.store.settings.setLocalCode(code);

    Locale res;
    switch (code) {
      case 'zh':
        res = const Locale('zh', '');
        break;
      case 'en':
        res = const Locale('en', '');
        break;
      default:
        res = null;
    }
    setState(() {
      _locale = res;
    });
  }

  void _initWalletConnect() {
    _service.plugin.sdk.api.walletConnect.initClient((WCPairingData proposal) {
      print('get wc pairing');
      _handleWCPairing(proposal);
    }, (WCPairedData session) {
      print('get wc session');
      _service.store.account.createWCSession(session);
      _service.store.account.setWCPairing(false);
    }, (WCPayloadData payload) {
      print('get wc payload');
      _handleWCPayload(payload);
    });
  }

  Future<void> _handleWCPairing(WCPairingData pairingReq) async {
    final approved = await Navigator.of(context)
        .pushNamed(WCPairingConfirmPage.route, arguments: pairingReq);
    final address = _service.keyring.current.address;
    if (approved ?? false) {
      _service.store.account.setWCPairing(true);
      await _service.plugin.sdk.api.walletConnect
          .approvePairing(pairingReq, '$address@polkadot:acalatc5');
      print('wallet connect alive');
    } else {
      _service.plugin.sdk.api.walletConnect.rejectPairing(pairingReq);
    }
  }

  Future<void> _handleWCPayload(WCPayloadData payload) async {
    final res = await Navigator.of(context)
        .pushNamed(WalletConnectSignPage.route, arguments: payload);
    if (res == null) {
      print('user rejected signing');
      await _service.plugin.sdk.api.walletConnect
          .payloadRespond(payload, error: {
        'code': -32000,
        'message': "User rejected JSON-RPC request",
      });
    } else {
      print('user signed payload:');
      print(res);
      // await _service.plugin.sdk.api.walletConnect
      //     .payloadRespond(payload, response: );
    }
  }

  Future<void> _getAcalaModulesConfig() async {
    final karModulesConfig = await WalletApi.getKarModulesConfig();
    if (karModulesConfig != null) {
      _store.settings.setLiveModules(karModulesConfig);
    } else {
      _store.settings.setLiveModules({
        'assets': {'enabled': true}
      });
    }
  }

  Future<void> _startPlugin(AppService service) async {
    _initWalletConnect();

    _service.assets.fetchMarketPriceFromSubScan();
    _store.settings.getXcmEnabledChains(service.plugin.basic.name);

    setState(() {
      _connectedNode = null;
    });

    List<NetworkParams> list = new List();
    list.add(NetworkParams.fromJson(
        {"name": "bitpie", "endpoint": "https://pnode.getcai.com:2573/"}));
    final connected = await service.plugin.start(_keyring, nodes: list);
    setState(() {
      _connectedNode = connected;
    });

    if (_service.plugin.basic.name == 'karura' ||
        _service.plugin.basic.name == 'acala') {
      _getAcalaModulesConfig();
    }
  }

  Future<void> _changeNetwork(PolkawalletPlugin network) async {
    _keyring.setSS58(network.basic.ss58);

    setState(() {
      _theme = _getAppTheme(
        network.basic.primaryColor,
        secondaryColor: network.basic.gradientColor,
      );
    });
    _store.settings.setNetwork(network.basic.name);

    final useLocalJS = WalletApi.getPolkadotJSVersion(
          _store.storage,
          network.basic.name,
          network.basic.jsCodeVersion,
        ) >
        network.basic.jsCodeVersion;

    final service = AppService(
        widget.plugins, network, _keyring, _store, widget.buildTarget);
    service.init();

    // we reuse the existing webView instance when we start a new plugin.
    await network.beforeStart(
      _keyring,
      webView: _service?.plugin?.sdk?.webView,
      jsCode: useLocalJS
          ? WalletApi.getPolkadotJSCode(_store.storage, network.basic.name)
          : null,
    );

    setState(() {
      _service = service;
    });

    _startPlugin(service);
  }

  Future<void> _switchNetwork(String networkName) async {
    await _changeNetwork(
        widget.plugins.firstWhere((e) => e.basic.name == networkName));
    _service.store.assets.loadCache(_keyring.current, networkName);
  }

  Future<void> _changeNode(NetworkParams node) async {
    if (_connectedNode != null) {
      setState(() {
        _connectedNode = null;
      });
    }
    _service.plugin.sdk.api.account.unsubscribeBalance();
    final connected = await _service.plugin.start(_keyring, nodes: [node]);
    setState(() {
      _connectedNode = connected;
    });
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final versions = await WalletApi.getLatestVersion();
    AppUI.checkUpdate(context, versions, widget.buildTarget, autoCheck: true);
  }

  Future<void> _checkJSCodeUpdate(
      BuildContext context, PolkawalletPlugin plugin,
      {bool needReload = true}) async {
    // check js code update
    final jsVersions = await WalletApi.fetchPolkadotJSVersion();
    if (jsVersions == null) return;

    final network = plugin.basic.name;
    final version = jsVersions[network];
    final versionMin = jsVersions['$network-min'];
    final currentVersion = WalletApi.getPolkadotJSVersion(
      _store.storage,
      network,
      plugin.basic.jsCodeVersion,
    );
    print('js update: $network $currentVersion $version $versionMin');
    final bool needUpdate = await AppUI.checkJSCodeUpdate(
        context, _store.storage, currentVersion, version, versionMin, network);
    if (needUpdate) {
      final res =
          await AppUI.updateJSCode(context, _store.storage, network, version);
      if (needReload && res) {
        _changeNetwork(plugin);
      }
    }
  }

  // Future<void> _showGuide(BuildContext context, GetStorage storage) async {
  //   // todo: remove this after crowd loan
  //   // final karStarted = await WalletApi.getKarCrowdLoanStarted();
  //   // if (karStarted != null && karStarted['started']) {
  //   //   Navigator.of(context).pushNamed(AdPage.route);
  //   //   return;
  //   // }

  //   final storeKey = '${show_guide_status_key}_$app_beta_version';
  //   final showGuideStatus = storage.read(storeKey);
  //   if (showGuideStatus == null) {
  //     final res = await Navigator.of(context).pushNamed(GuidePage.route);
  //     if (res != null) {
  //       storage.write(storeKey, true);
  //     }
  //   }
  // }

  Future<int> _startApp(BuildContext context) async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring
          .init(widget.plugins.map((e) => e.basic.ss58).toSet().toList());

      final storage = GetStorage(get_storage_container);
      final store = AppStore(storage);
      await store.init();

      // _showGuide(context, storage);

      final pluginIndex = widget.plugins
          .indexWhere((e) => e.basic.name == store.settings.network);
      final service = AppService(
          widget.plugins,
          widget.plugins[pluginIndex > -1 ? pluginIndex : 0],
          _keyring,
          store,
          widget.buildTarget);

      service.init();
      setState(() {
        _store = store;
        _service = service;
        _theme = _getAppTheme(
          service.plugin.basic.primaryColor,
          secondaryColor: service.plugin.basic.gradientColor,
        );
      });

      if (store.settings.localeCode.isNotEmpty) {
        _changeLang(store.settings.localeCode);
      } else {
        _changeLang(Localizations.localeOf(context).toString());
      }

      // _checkUpdate(context);
      // await _checkJSCodeUpdate(context, service.plugin, needReload: false);

      final useLocalJS = WalletApi.getPolkadotJSVersion(
            _store.storage,
            service.plugin.basic.name,
            service.plugin.basic.jsCodeVersion,
          ) >
          service.plugin.basic.jsCodeVersion;

      await service.plugin.beforeStart(
        _keyring,
        jsCode: useLocalJS
            ? WalletApi.getPolkadotJSCode(
                _store.storage, service.plugin.basic.name)
            : null,
      );
      if (_keyring.keyPairs.length > 0) {
        _store.assets.loadCache(_keyring.current, _service.plugin.basic.name);
      }

      _startPlugin(service);
    }
    return _keyring.allAccounts.length;
  }

  void _handleIncomingAppLinks() {
    uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      print('got uri: $uri');
    }, onError: (Object err) {
      if (!mounted) return;
      print('got err: $err');
    });
  }

  Future<void> _handleInitialAppLinks() async {
    if (!_isInitialUriHandled) {
      _isInitialUriHandled = true;
      print('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          print('got initial uri: $uri');
        }
        if (!mounted) return;
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException {
        if (!mounted) return;
        print('malformed initial uri');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _handleIncomingAppLinks();
    _handleInitialAppLinks();
  }

  Map<String, FlutterBoostRouteFactory> _getRoutes() {
    // final pluginPages = _service != null && _service.plugin != null
    //     ? _service.plugin.getRoutes(_keyring)
    //     : {};
    return {
      /// pages of plugin
      // ...pluginPages,
      HomePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (BuildContext context) => FutureBuilder<int>(
                  future: _startApp(context),
                  builder: (_, AsyncSnapshot<int> snapshot) {
                    if (snapshot.hasData && _service != null) {
                      return snapshot.data > 0
                          ? HomePage(_service, _connectedNode,
                              _checkJSCodeUpdate, _switchNetwork)
                          : CreateAccountEntryPage(
                              widget.plugins, widget.buildTarget);
                    } else {
                      return Container(color: Theme.of(context).canvasColor);
                    }
                  },
                ));
      },
      TxConfirmPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => TxConfirmPage(
                _service.plugin, _keyring, _service.account.getPassword));
      },
      WalletExtensionSignPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => WalletExtensionSignPage(
              _service.plugin, _keyring, _service.account.getPassword),
        );
      },
      QrSenderPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => QrSenderPage(_service.plugin, _keyring));
      },
      QrSignerPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => QrSignerPage(_service.plugin, _keyring));
      },
      ScanPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => ScanPage(_service.plugin, _keyring));
      },
      AccountListPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AccountListPage(_service.plugin, _keyring),
        );
      },
      AccountQrCodePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AccountQrCodePage(_service.plugin, _keyring),
        );
      },
      NetworkSelectPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => NetworkSelectPage(_service, widget.plugins,
                widget.disabledPlugins, _changeNetwork));
      },
      WCPairingConfirmPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => WCPairingConfirmPage(_service),
        );
      },
      WCSessionsPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => WCSessionsPage(_service),
        );
      },
      WalletConnectSignPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) =>
              WalletConnectSignPage(_service, _service.account.getPassword),
        );
      },
      GuidePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => GuidePage(),
        );
      },
      AdPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AdPage(),
        );
      },
      KarCrowdLoanPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => KarCrowdLoanPage(_service, _connectedNode),
        );
      },
      KarCrowdLoanWaitPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => KarCrowdLoanWaitPage(),
        );
      },
      KarCrowdLoanFormPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => KarCrowdLoanFormPage(_service, _connectedNode),
        );
      },

      /// account
      CreateAccountEntryPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (BuildContext context) =>
                CreateAccountEntryPage(widget.plugins, widget.buildTarget));
      },
      CreateAccountPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings, builder: (_) => CreateAccountPage(_service));
      },
      BackupAccountPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings, builder: (_) => BackupAccountPage(_service));
      },
      DAppWrapperPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => DAppWrapperPage(_service.plugin, _keyring));
      },
      SelectImportTypePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings, builder: (_) => SelectImportTypePage(_service));
      },
      ImportAccountFormMnemonic.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => ImportAccountFormMnemonic(_service));
      },
      ImportAccountFromRawSeed.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => ImportAccountFromRawSeed(_service));
      },
      ImportAccountFormKeyStore.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => ImportAccountFormKeyStore(_service));
      },
      ImportAccountCreatePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (_) => ImportAccountCreatePage(_service));
      },

      /// assets
      AssetPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AssetPage(_service),
        );
      },
      TransferDetailPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => TransferDetailPage(_service),
        );
      },
      TransferPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => TransferPage(widget.plugins, widget.buildTarget),
        );
      },
      LocksDetailPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (BuildContext context) => FutureBuilder<int>(
                  future: _startApp(context),
                  builder: (_, AsyncSnapshot<int> snapshot) {
                    if (snapshot.hasData && _service != null) {
                      return LocksDetailPage(_service);
                    } else {
                      return Container(color: Theme.of(context).canvasColor);
                    }
                  },
                ));
      },
      ManageAssetsPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ManageAssetsPage(_service),
        );
      },
      AnnouncementPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AnnouncementPage(),
        );
      },

      /// profile
      SignMessagePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => SignMessagePage(_service),
        );
      },
      ContactsPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ContactsPage(_service),
        );
      },
      ContactPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ContactPage(_service),
        );
      },
      AboutPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AboutPage(_service),
        );
      },
      AccountManagePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AccountManagePage(_service),
        );
      },
      ChangeNamePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ChangeNamePage(_service),
        );
      },
      ChangePasswordPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ChangePasswordPage(_service),
        );
      },
      ExportAccountPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ExportAccountPage(_service),
        );
      },
      ExportResultPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ExportResultPage(),
        );
      },
      SettingsPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => SettingsPage(_service, _changeLang, _changeNode),
        );
      },
      RemoteNodeListPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => RemoteNodeListPage(_service, _changeNode),
        );
      },
      CreateRecoveryPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => CreateRecoveryPage(_service),
        );
      },
      FriendListPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => FriendListPage(_service),
        );
      },
      RecoverySettingPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => RecoverySettingPage(_service),
        );
      },
      RecoveryStatePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => RecoveryStatePage(_service),
        );
      },
      RecoveryProofPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => RecoveryProofPage(_service),
        );
      },
      InitiateRecoveryPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => InitiateRecoveryPage(_service),
        );
      },
      VouchRecoveryPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => VouchRecoveryPage(_service),
        );
      },
      TxDetailPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => TxDetailPage(_service),
        );
      },

      /// crowd loan
      CrowdLoanPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => CrowdLoanPage(_service, _connectedNode),
        );
      },
      ContributePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ContributePage(_service),
        );
      },
      AcaCrowdLoanPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AcaCrowdLoanPage(_service, _connectedNode),
        );
      },
      AcaCrowdLoanFormPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AcaCrowdLoanFormPage(_service, _connectedNode),
        );
      },
    };
  }

  Route<dynamic> routeFactory(RouteSettings settings, String uniqueId) {
    final routes = _getRoutes();
    FlutterBoostRouteFactory func = routes[settings.name];
    if (func == null) {
      return null;
    }
    return func(settings, uniqueId);
  }

  Widget appBuilder(Widget home) {
    return MaterialApp(
      title: 'Polkawallet',
      theme: _theme ??
          _getAppTheme(
            widget.plugins[0].basic.primaryColor,
            secondaryColor: widget.plugins[0].basic.gradientColor,
          ),
      localizationsDelegates: [
        AppLocalizationsDelegate(_locale ?? Locale('en', '')),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('zh', ''),
      ],
      home: home,
      debugShowCheckedModeBanner: true,

      ///必须加上builder参数，否则showDialog等会出问题
      builder: (_, __) {
        return home;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // return FlutterBoostApp(routeFactory,
    //     appBuilder: appBuilder, initialRoute: '/');
    return GestureDetector(
      onTapUp: (_) {
        FocusScope.of(context).focusedChild?.unfocus();
      },
      child: ScreenUtilInit(
          designSize: Size(1170, 2532),
          builder: () => FlutterBoostApp(routeFactory,
              appBuilder: appBuilder, initialRoute: '/')),
    );
  }

  // @override
  // Widget build(_) {
  //   final routes = _getRoutes();
  //   return GestureDetector(
  //     onTapUp: (_) {
  //       FocusScope.of(context).focusedChild?.unfocus();
  //     },
  //     child: MaterialApp(
  //       title: 'Polkawallet',
  //       theme: _theme ??
  //           _getAppTheme(
  //             widget.plugins[0].basic.primaryColor,
  //             secondaryColor: widget.plugins[0].basic.gradientColor,
  //           ),
  //       debugShowCheckedModeBanner: false,
  //       localizationsDelegates: [
  //         AppLocalizationsDelegate(_locale ?? Locale('en', '')),
  //         GlobalMaterialLocalizations.delegate,
  //         GlobalCupertinoLocalizations.delegate,
  //         GlobalWidgetsLocalizations.delegate,
  //       ],
  //       supportedLocales: [
  //         const Locale('en', ''),
  //         const Locale('zh', ''),
  //       ],
  //       initialRoute: HomePage.route,
  //       onGenerateRoute: (settings) => CupertinoPageRoute(
  //           builder: routes[settings.name], settings: settings),
  //       // navigatorObservers: [FirebaseAnalyticsObserver(analytics: _analytics)],
  //     ),
  //   );
  // }
}
