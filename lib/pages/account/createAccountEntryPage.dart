import 'dart:convert';
import 'package:polka_module/global.dart';
import 'package:polka_module/store/types/coinDetail.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_ui/components/importCoinItem.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polka_module/service/index.dart';
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';

class CreateAccountEntryPage extends StatefulWidget {
  CreateAccountEntryPage(this.service, this.plugins, this.initNetwork);

  static final String route = '/account/entry';
  final List<PolkawalletPlugin> plugins;
  final AppService service;
  final Future<void> Function(String,
      {NetworkParams node, PageRouteParams pageRoute}) initNetwork;

  @override
  _CreateAccountEntryPage createState() => _CreateAccountEntryPage();
}

class _CreateAccountEntryPage extends State<CreateAccountEntryPage> {
  BasicMessageChannel<String> channel =
      BasicMessageChannel("BasicMessageChannelPlugin", StringCodec());
  CoinDetail _coinDetail;

  @override
  void initState() {
    channel.setMessageHandler((message) => Future<String>(() {
          print("message======$message");
          setState(() {
            _coinDetail = CoinDetail.fromJson(jsonDecode(message));
          });
          return message;
        }));
    super.initState();
  }

  String getCoinCode(String coinCode) {
    if (coinCode != null) {
      if (coinCode.toUpperCase().startsWith(polkaPrefix)) {
        var strArr = coinCode.split("_");
        return strArr[strArr.length - 1].toUpperCase();
      }
      return coinCode;
    }

    return "";
  }

  void _changeLang(String code, AppService service) {
    service.store.settings.setLocalCode(code);

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
      if (res != null) {
        service.store.settings.initMessage((res).languageCode);
      }
    });
  }

  String getBgIcon(int position) {
    if (position == 2) {
      return 'assets/images/icon_import_coin_bg3.png';
    } else if (position == 3) {
      return 'assets/images/icon_import_coin_bg4.png';
    }

    return 'assets/images/icon_import_coin_bg0.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(getBgIcon(_coinDetail.position)),
                  fit: BoxFit.fill),
            ),
            child: _coinDetail != null
                ? ImportCoinItem(
                    getCoinCode(_coinDetail.coinCode),
                    _coinDetail.coinName,
                    "",
                    false,
                    _coinDetail.position, () async {
                    if (_coinDetail.mnemonic != null &&
                        _coinDetail.mnemonic.isNotEmpty) {
                      try {
                        channel.send("Loading");

                        await widget.initNetwork(_coinDetail.coinName);

                        _changeLang(_coinDetail.language, widget.service);

                        if (widget.service.keyring.current == null ||
                            widget.service.keyring.current.address == null) {
                          print("new account");
                          widget.service.store.account
                              .setNewAccountKey(_coinDetail.mnemonic);
                          widget.service.store.account
                              .setNewAccount(_coinDetail.name, password);

                          /// import account
                          // var acc;
                          // while (acc == null || acc['error'] != null) {
                          //   try {
                          //     acc = await widget.service.account.importAccount(
                          //       keyType: KeyType.mnemonic,
                          //       cryptoType: CryptoType.sr25519,
                          //       derivePath: '',
                          //     );
                          //   } catch (e) {
                          //     print("e====${e}");
                          //     continue;
                          //   }
                          // }

                          final acc = await widget.service.account.importAccount(
                            keyType: KeyType.mnemonic,
                            cryptoType: CryptoType.sr25519,
                            derivePath: '',
                          );

                          await widget.service.account.addAccount(
                            json: acc,
                            keyType: KeyType.mnemonic,
                            cryptoType: CryptoType.sr25519,
                            derivePath: '',
                          );

                          widget.service.account
                              .closeBiometricDisabled(acc['pubKey']);
                        }

                        print("new sign....");
                        final params = SignAsExtensionParam();
                        params.msgType = "pub(bytes.sign)";
                        params.request = {
                          "address": widget.service.keyring.current.address,
                          "data": widget.service.keyring.current.address,
                        };
                        final res = await widget.service.plugin.sdk.api.keyring
                            .signAsExtension(password, params);
                        _coinDetail.signature = res.signature;
                        _coinDetail.address =
                            widget.service.keyring.current.address;
                        _coinDetail.addressIndex = pathClient;
                        Map<String, dynamic> map =
                            widget.service.keyring.current.toJson();
                        map["icon"] = null;
                        _coinDetail.polkaInfo = json.encode(map);

                        channel
                            .send(json.encode(CoinDetail.toJson(_coinDetail)));
                      } catch (e) {
                        print("e=====${e}");
                        channel.send("Not Spuurot");
                      }
                    } else {
                      channel.send("Not Spuurot");
                    }
                  })
                : Container(),
          ),
        ));
  }
}
