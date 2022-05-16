import 'dart:async';

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
import 'package:polka_module/pages/pluginPage.dart';
import 'package:polka_module/pages/profile/aboutPage.dart';
import 'package:polka_module/pages/profile/account/accountManagePage.dart';
import 'package:polka_module/pages/profile/account/changeNamePage.dart';
import 'package:polka_module/pages/profile/account/changePasswordPage.dart';
import 'package:polka_module/pages/profile/account/exportAccountPage.dart';
import 'package:polka_module/pages/profile/account/exportResultPage.dart';
import 'package:polka_module/pages/profile/account/signPage.dart';
import 'package:polka_module/pages/profile/communityPage.dart';
import 'package:polka_module/pages/profile/contacts/contactPage.dart';
import 'package:polka_module/pages/profile/contacts/contactsPage.dart';
import 'package:polka_module/pages/profile/message/messagePage.dart';
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
import 'package:polka_module/pages/public/DAppsTestPage.dart';
import 'package:polka_module/pages/public/acalaBridgePage.dart';
import 'package:polka_module/pages/public/guidePage.dart';
import 'package:polka_module/pages/public/stakingKSMGuide.dart';
import 'package:polka_module/pages/walletConnect/walletConnectSignPage.dart';
import 'package:polka_module/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:polka_module/pages/walletConnect/wcSessionsPage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/startPage.dart';
import 'package:polka_module/store/index.dart';
import 'package:polka_module/utils/UI.dart';
import 'package:polka_module/utils/i18n/index.dart';
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
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/v3/accountListPage.dart';
import 'package:polkawallet_ui/pages/v3/plugin/pluginAccountListPage.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/pages/walletExtensionSignPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pages/account/import/importAccountCreatePage.dart';
import 'pages/account/import/importAccountFormKeyStore.dart';
import 'pages/account/import/importAccountFormMnemonic.dart';
import 'pages/account/import/importAccountFromRawSeed.dart';
import 'pages/account/import/selectImportTypePage.dart';

const get_storage_container = 'configuration';

bool _isInitialUriHandled = false;

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins, this.disabledPlugins, BuildTargets buildTarget) {
    WalletApp.buildTarget = buildTarget;
  }
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  static BuildTargets buildTarget;
  static int isInitial = 0;

  static Future<void> checkUpdate(BuildContext context) async {
    final versions = await WalletApi.getLatestVersion();
    AppUI.checkUpdate(context, versions, WalletApp.buildTarget,
        autoCheck: true);
  }

  @override
  _WalletAppState createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> with WidgetsBindingObserver {
  Keyring _keyring;

  AppStore _store;
  AppService _service;

  ThemeData _theme;

  Locale _locale;

  NetworkParams _connectedNode;

  BuildContext _homePageContext;
  PageRouteParams _autoRoutingParams;

  bool apiInit = false;

  String setttingName = "";

  ThemeData _getAppTheme(MaterialColor color, {Color secondaryColor}) {
    return ThemeData(
      // backgroundColor: Color(0xFFF0ECE6),
      scaffoldBackgroundColor: Color(0xFFF5F3F0),
      dividerColor: Color(0xFFD4D4D4),
      cardColor: Colors.white,
      toggleableActiveColor: Color(0xFF768FE1),
      errorColor: Color(0xFFE46B41),
      unselectedWidgetColor: Color(0xFF858380),
      textSelectionTheme:
          TextSelectionThemeData(selectionColor: Color(0xFF565554)),
      appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F3F0),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF565554),
              fontSize: 18,
              fontFamily: 'TitilliumWeb',
              fontWeight: FontWeight.w600)),
      primarySwatch: color,
      hoverColor: secondaryColor,
      colorScheme: ColorScheme.fromSwatch().copyWith(),
      textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Color(0xFF565554),
              fontFamily: "TitilliumWeb"),
          headline2: TextStyle(
            fontSize: 22,
          ),
          headline3: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF565554),
              fontFamily: "TitilliumWeb"),
          headline4: TextStyle(
            color: Color(0xFF565554),
            fontSize: 16,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w400,
          ),
          headline5: TextStyle(
            color: Color(0xFF565554),
            fontSize: 14,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w400,
          ),
          headline6: TextStyle(
            color: Color(0xFF565554),
            fontSize: 12,
            fontFamily: 'SF_Pro',
            fontWeight: FontWeight.w400,
          ),
          bodyText1: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          bodyText2: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          caption: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: "TitilliumWeb"),
          button: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: "TitilliumWeb")),
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
      if (_locale != null) {
        _service.store.settings.initMessage((_locale).languageCode);
      }
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

  Future<void> _startPlugin(AppService service, {NetworkParams node}) async {
    // _initWalletConnect();

    setState(() {
      _connectedNode = null;
    });

    final connected = await service.plugin.start(_keyring,
        nodes: node != null ? [node] : service.plugin.nodeList);
    setState(() {
      _connectedNode = connected;
    });

    _dropsService(service, node: node);
  }

  Future<void> _restartWebConnect(AppService service,
      {NetworkParams node}) async {
    setState(() {
      _connectedNode = null;
    });

    // Offline JS interaction will be affected (import and export accounts)
    // final useLocalJS = WalletApi.getPolkadotJSVersion(
    //       _store.storage,
    //       service.plugin.basic.name,
    //       service.plugin.basic.jsCodeVersion,
    //     ) >
    //     service.plugin.basic.jsCodeVersion;

    // await service.plugin.beforeStart(
    //   _keyring,
    //   webView: _service?.plugin?.sdk?.webView,
    //   jsCode: useLocalJS
    //       ? WalletApi.getPolkadotJSCode(
    //           _store.storage, service.plugin.basic.name)
    //       : null,
    // );

    final connected = await service.plugin.start(_keyring,
        nodes: node != null ? [node] : service.plugin.nodeList);
    setState(() {
      _connectedNode = connected;
    });

    _dropsService(service, node: node);
  }

  Timer _webViewDropsTimer;
  Timer _dropsServiceTimer;
  Timer _chainTimer;
  _dropsService(AppService service, {NetworkParams node}) {
    _dropsServiceCancel();
    _dropsServiceTimer = Timer(Duration(seconds: 24), () async {
      _chainTimer = Timer(Duration(seconds: 18), () async {
        _restartWebConnect(service, node: node);
        _webViewDropsTimer = Timer(Duration(seconds: 60), () {
          _dropsService(service, node: node);
        });
      });
      _service.plugin.sdk.webView
          .evalJavascript('api.rpc.system.chain()')
          .then((value) => _dropsService(service, node: node));
    });
  }

  _dropsServiceCancel() {
    _dropsServiceTimer?.cancel();
    _chainTimer?.cancel();
    _webViewDropsTimer?.cancel();
  }

  Future<void> _changeNetwork(PolkawalletPlugin network,
      {NetworkParams node}) async {
    _dropsServiceCancel();
    setState(() {
      _connectedNode = null;
    });

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

    _service.plugin.dispose();

    final service = AppService(
        widget.plugins, network, _keyring, _store, WalletApp.buildTarget);
    service.init();

    // we reuse the existing webView instance when we start a new plugin.
    await network.beforeStart(_keyring,
        webView: _service?.plugin?.sdk?.webView,
        jsCode: useLocalJS
            ? WalletApi.getPolkadotJSCode(_store.storage, network.basic.name)
            : null, socketDisconnectedAction: () {
      UI.throttle(() {
        _dropsServiceCancel();
        _restartWebConnect(service, node: node);
      });
    });

    setState(() {
      _service = service;
    });

    _startPlugin(service, node: node);
  }

  Future<void> _switchNetwork(String networkName,
      {NetworkParams node, PageRouteParams pageRoute}) async {
    final isNetworkChanged = networkName != _service.plugin.basic.name;

    if (isNetworkChanged) {
      // display a dialog while changing network
      showCupertinoDialog(
          context: _homePageContext,
          builder: (_) {
            final dic =
                I18n.of(_homePageContext).getDic(i18n_full_dic_app, 'assets');
            return CupertinoAlertDialog(
              title: Text(dic['v3.changeNetwork']),
              content: Container(
                margin: EdgeInsets.only(top: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      child: CupertinoActivityIndicator(),
                    ),
                    Text(
                        '${dic['v3.changeNetwork.ing']} ${networkName.toUpperCase()}...')
                  ],
                ),
              ),
            );
          });
    }

    await _changeNetwork(
        widget.plugins.firstWhere((e) => e.basic.name == networkName),
        node: node);
    await _service.store.assets.loadCache(_keyring.current, networkName);

    if (isNetworkChanged) {
      Navigator.of(_homePageContext).pop();
    }

    // set auto routing path so we can route to the page after network changed
    _autoRoutingParams = pageRoute;
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

  Future<void> _checkBadAddressAndWarn(BuildContext context) async {
    if (_keyring != null &&
        _keyring.current != null &&
        _keyring.current.pubKey ==
            '0xda99a528d2cbe6b908408c4f887d2d0336394414a9edb474c33a690a4202341a') {
      final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              title: Text(dic['bad.warn']),
              content: Text(
                  '${Fmt.address(_keyring.current.address)} ${dic['bad.warn.info']}'),
              actions: [
                CupertinoButton(
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['ok']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    }
  }

  Future<void> _checkJSCodeUpdate(
      BuildContext context, PolkawalletPlugin plugin,
      {bool needReload = true}) async {
    _checkBadAddressAndWarn(context);
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

  Future<int> _startApp(BuildContext context) async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring
          .init(widget.plugins.map((e) => e.basic.ss58).toSet().toList());

      final storage = GetStorage(get_storage_container);
      final store = AppStore(storage);
      await store.init();

      // await _showGuide(context, storage);

      final pluginIndex = widget.plugins
          .indexWhere((e) => e.basic.name == store.settings.network);
      final service = AppService(
          widget.plugins,
          widget.plugins[pluginIndex > -1 ? pluginIndex : 0],
          _keyring,
          store,
          WalletApp.buildTarget);
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
    }

    if (!apiInit) {
      final useLocalJS = WalletApi.getPolkadotJSVersion(
            _store.storage,
            _service.plugin.basic.name,
            _service.plugin.basic.jsCodeVersion,
          ) >
          _service.plugin.basic.jsCodeVersion;

      await _service.plugin.beforeStart(_keyring,
          jsCode: useLocalJS
              ? WalletApi.getPolkadotJSCode(
                  _store.storage, _service.plugin.basic.name)
              : null, socketDisconnectedAction: () {
        UI.throttle(() {
          _dropsServiceCancel();
          _restartWebConnect(_service);
        });
      });

      if (_keyring.keyPairs.length > 0) {
        _store.assets.loadCache(_keyring.current, _service.plugin.basic.name);
      }

      _startPlugin(_service);

      setState(() {
        apiInit = true;
      });
    }

    return _keyring.allAccounts.length;
  }

  Map<String, FlutterBoostRouteFactory> _getRoutes() {
    final pluginPages = _service != null && _service.plugin != null
        ? _service.plugin.getRoutes(_keyring)
        : {};

    return {
      /// pages of plugin
      ...pluginPages,
      HomePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (BuildContext context) => Observer(
            builder: (BuildContext context) {
              _homePageContext = context;

              return FutureBuilder<int>(
                future: _startApp(context),
                builder: (_, AsyncSnapshot<int> snapshot) {
                  if (snapshot.hasData && _service != null) {
                    if (WalletApp.isInitial == 1) {
                      WalletApp.isInitial++;
                      _checkJSCodeUpdate(context, _service.plugin,
                          needReload: false);
                      WalletApp.checkUpdate(context);
                      _queryPluginsConfig();
                    }
                    return snapshot.data > 0
                        ? HomePage(_service, widget.plugins, _connectedNode,
                            _checkJSCodeUpdate, _switchNetwork, _changeNode)
                        : CreateAccountEntryPage(
                            widget.plugins, WalletApp.buildTarget);
                  } else {
                    return Container(color: Theme.of(context).hoverColor);
                  }
                },
              );
            },
          ),
        );
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
      PluginAccountListPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => PluginAccountListPage(_service.plugin, _keyring),
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
      AcalaBridgePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => AcalaBridgePage(),
        );
      },
      StakingKSMGuide.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => StakingKSMGuide(_service),
        );
      },

      /// account
      CreateAccountEntryPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
            settings: settings,
            builder: (BuildContext context) =>
                CreateAccountEntryPage(widget.plugins, WalletApp.buildTarget));
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
          builder: (_) => TransferPage(_service),
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
      CommunityPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => CommunityPage(_service),
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
      PluginPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => PluginPage(_service),
        );
      },
      DAppsTestPage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => DAppsTestPage(),
        );
      },
      MessagePage.route: (settings, uniqueId) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => MessagePage(_service),
        );
      },
    };
  }

  void _toPageByUri(Uri uri) {
    final paths = uri.toString().split("polkawallet.io");
    Map<dynamic, dynamic> args = Map<dynamic, dynamic>();
    if (paths.length > 1) {
      var network = "karura";
      final pathDatas = paths[1].split("?");
      if (pathDatas.length > 1) {
        final datas = pathDatas[1].split("&");
        datas.forEach((element) {
          if (element.split("=")[0] == "network") {
            network = Uri.decodeComponent(element.split("=")[1]);
          } else {
            args[element.split("=")[0]] =
                Uri.decodeComponent(element.split("=")[1]);
          }
        });
      }

      if (network != _service.plugin.basic.name) {
        _switchNetwork(network,
            pageRoute: PageRouteParams(pathDatas[0], args: args));
      } else {
        _autoRoutingParams = PageRouteParams(pathDatas[0], args: args);
        WidgetsBinding.instance.addPostFrameCallback((_) => _doAutoRouting());
      }
    }
  }

  void _handleIncomingAppLinks() {
    uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      closeWebView();
      _toPageByUri(uri);
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
          Timer.periodic(Duration(milliseconds: 1000), (timer) {
            if (WalletApp.isInitial > 0) {
              timer.cancel();
              _toPageByUri(uri);
            }
          });
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

  void _setupPluginsNetworkSwitch() {
    widget.plugins.forEach((e) {
      if (e.appUtils.switchNetwork == null) {
        e.appUtils.switchNetwork =
            (String network, {PageRouteParams pageRoute}) async {
          _switchNetwork(network, pageRoute: pageRoute);
        };
      }
    });
  }

  void _doAutoRouting() {
    if (_autoRoutingParams != null) {
      print('page auto routing...');
      Navigator.of(_homePageContext).pushNamed(_autoRoutingParams.path,
          arguments: _autoRoutingParams.args);
      _autoRoutingParams = null;
    }
  }

  void _queryPluginsConfig() {
    WalletApi.getPluginsConfig(WalletApp.buildTarget).then((value) {
      _store.settings.setPluginsConfig(value);
    });
  }

  @override
  void initState() {
    super.initState();

    _handleIncomingAppLinks();
    _handleInitialAppLinks();
    WidgetsBinding.instance.addObserver(this);

    _setupPluginsNetworkSwitch();
  }

  @override
  void dispose() {
    _dropsServiceCancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _dropsService(_service);
        break;
      case AppLifecycleState.paused:
        _dropsServiceCancel();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Route<dynamic> routeFactory(RouteSettings settings, String uniqueId) {
    final routes = _getRoutes();
    setttingName = settings.name;
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
      debugShowCheckedModeBanner: false,
      builder: (context, widget) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: widget);
      },
    );
  }

  @override
  Widget build(_) {
    /// we will do auto routing after plugin changed & app rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _doAutoRouting());

    return GestureDetector(
        onTapUp: (_) {
          FocusScope.of(context).focusedChild?.unfocus();
        },
        child: ScreenUtilInit(
            designSize: Size(390, 844),
            builder: (_) => FutureBuilder<int>(
                  future: _startApp(context),
                  builder: (_, AsyncSnapshot<int> snapshot) {
                    if (setttingName == "/") {
                      return FlutterBoostApp(routeFactory,
                          appBuilder: appBuilder, initialRoute: '/');
                    } else {
                      if (snapshot.hasData && _service != null && apiInit) {
                        return FlutterBoostApp(routeFactory,
                            appBuilder: appBuilder, initialRoute: '/');
                      } else {
                        return Container(color: Theme.of(context).canvasColor);
                      }
                    }
                  },
                )));
  }
}
