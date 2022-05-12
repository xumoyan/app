import 'dart:convert';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/global.dart';
import 'package:polka_module/store/types/coinDetail.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_ui/components/importCoinItem.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/store/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polkawallet_ui/utils/index.dart';

class CreateAccountEntryPage extends StatefulWidget {
  CreateAccountEntryPage(this.plugins, this.buildTarget);
  static final String route = '/account/entry';
  final List<PolkawalletPlugin> plugins;
  final BuildTargets buildTarget;

  @override
  _CreateAccountEntryPage createState() => _CreateAccountEntryPage();
}

class _CreateAccountEntryPage extends State<CreateAccountEntryPage> {
  BasicMessageChannel<String> channel =
      BasicMessageChannel("BasicMessageChannelPlugin", StringCodec());
  CoinDetail _coinDetail;

  @override
  void initState() {
    // channel.setMessageHandler((message) => Future<String>(() {
    //       print("message======$message");
    //       setState(() {
    //         _coinDetail = CoinDetail.fromJson(jsonDecode(message));
    //       });
    //       return message;
    //     }));
    super.initState();
    _coinDetail = CoinDetail.fromJson(jsonDecode(
        "{\"balance\":\"0\",\"chainId\":0,\"coinCode\":\"polka_polkadot_dot\",\"coinEvmTokenId\":0,\"coinName\":\"polkdot\",\"customrpc\":false,\"decimals\":0,\"isFirst\":false,\"isFixed\":false,\"isOpen\":0,\"isSelect\":false,\"isSubLast\":false,\"level\":0,\"mnemonic\":\"coach dress fade spray suggest purse obey special spot own cabin match\",\"name\":\"noname-510471780374\",\"password\":\"248743\",\"pricePrecision\":2,\"reputation\":0,\"sortNum\":2099087,\"unitDecimal\":10}"));
  }

  String getCoinCode(String coinCode) {
    if (coinCode.toUpperCase().startsWith(polkaPrefix)) {
      var strArr = coinCode.split("_");
      return strArr[strArr.length - 1].toUpperCase();
    }
    return coinCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: new BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: ImportCoinItem(getCoinCode(_coinDetail.coinCode),
                _coinDetail.coinName, "", false, () async {
              Keyring _keyring = Keyring();
              await _keyring.init(
                  widget.plugins.map((e) => e.basic.ss58).toSet().toList());

              final storage = GetStorage(get_storage_container);
              final store = AppStore(storage);
              await store.init();

              final pluginIndex = widget.plugins
                  .indexWhere((e) => e.basic.name == store.settings.network);
              final service = AppService(
                  widget.plugins,
                  widget.plugins[pluginIndex > -1 ? pluginIndex : 0],
                  _keyring,
                  store,
                  widget.buildTarget);
              service.init();

              final useLocalJS = WalletApi.getPolkadotJSVersion(
                    store.storage,
                    service.plugin.basic.name,
                    service.plugin.basic.jsCodeVersion,
                  ) >
                  service.plugin.basic.jsCodeVersion;

              await service.plugin.beforeStart(_keyring,
                  jsCode: useLocalJS
                      ? WalletApi.getPolkadotJSCode(
                          store.storage, service.plugin.basic.name)
                      : null,
                  socketDisconnectedAction: () {});

              if (_keyring.keyPairs.length > 0) {
                store.assets
                    .loadCache(_keyring.current, service.plugin.basic.name);
              }

              final connected = await service.plugin
                  .start(_keyring, nodes: service.plugin.nodeList);

              if (service.keyring.current == null ||
                  service.keyring.current.address == null) {
                print("new account");
                service.store.account
                    .setNewAccount(_coinDetail.name, _coinDetail.password);
                service.store.account.setNewAccountKey(_coinDetail.mnemonic);

                /// import account
                var acc = await service.account.importAccount(
                  keyType: KeyType.mnemonic,
                  cryptoType: CryptoType.sr25519,
                  derivePath: '',
                );

                await service.account.addAccount(
                  json: acc,
                  keyType: KeyType.mnemonic,
                  cryptoType: CryptoType.sr25519,
                  derivePath: '',
                );
                service.account.closeBiometricDisabled(acc['pubKey']);
              }

              print("new sign....");
              final params = SignAsExtensionParam();
              params.msgType = "pub(bytes.sign)";
              print(
                  "widget.service.keyring.current.address ===== ${service.keyring.current.address}");
              params.request = {
                "address": service.keyring.current.address,
                "data": service.keyring.current.address,
              };
              print(params.request);
              final res = await service.plugin.sdk.api.keyring
                  .signAsExtension(_coinDetail.password, params);

              _coinDetail.signature = res.signature;
              _coinDetail.address = service.keyring.current.address;
              _coinDetail.addressIndex = pathClient;
              Map<String, dynamic> map = service.keyring.current.toJson();
              map["icon"] = null;
              _coinDetail.polkaInfo = json.encode(map);

              channel.send(json.encode(CoinDetail.toJson(_coinDetail)));
            })),
      ),
    );
  }
}
