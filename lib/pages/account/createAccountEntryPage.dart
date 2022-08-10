import 'dart:convert';

import 'package:polka_module/global.dart';
import 'package:polka_module/store/types/coinData.dart';
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
import 'package:polkawallet_sdk/api/types/verifyResult.dart';
import 'dart:async';

class CreateAccountEntryPage extends StatefulWidget {
  CreateAccountEntryPage(this.service, this.plugins, this.initNetwork);

  static final String route = '/account/entry';
  final List<PolkawalletPlugin> plugins;
  final AppService service;
  final Future<AppService> Function(String,
      {NetworkParams node, PageRouteParams pageRoute}) initNetwork;

  @override
  _CreateAccountEntryPage createState() => _CreateAccountEntryPage();
}

class _CreateAccountEntryPage extends State<CreateAccountEntryPage> {
  BasicMessageChannel<String> channel =
      BasicMessageChannel("BasicMessageChannelPlugin", StringCodec());
  CoinData _coinData = null;
  bool isClicked = false;
  String oldNetwork;
  bool isTimeout = false;
  AppService mService;

  @override
  void initState() {
    super.initState();
    setState(() {
      mService = widget.service;
    });
    channel.setMessageHandler((message) => Future<String>(() {
          setState(() {
            _coinData = CoinData.fromJson(jsonDecode(message));
          });
          return message;
        }));

    // _coinData = CoinData.fromJson(jsonDecode(
    //     "{\"name\":\"noname-652799191467\",\"selectCoin\":\"polka_polkadot_dot\",\"mnemonic\":\"coach dress fade spray suggest purse obey special spot own cabin match\",\"currency\":\"CNY\",\"language\":\"zh\",\"position\":2,\"coinDetails\":[{\"balance\":\"0\",\"chainId\":0,\"coinCode\":\"polka_kusama_ksm\",\"coinEvmTokenId\":0,\"coinName\":\"kusama\",\"customrpc\":false,\"decimals\":0,\"isFirst\":false,\"isPressed\":false,\"isFixed\":false,\"isOpen\":0,\"isSubLast\":false,\"level\":0,\"position\":2,\"pricePrecision\":2,\"reputation\":0,\"sortNum\":2110281,\"unitDecimal\":10},{\"balance\":\"0\",\"chainId\":0,\"coinCode\":\"polka_polkadot_dot\",\"coinEvmTokenId\":0,\"coinName\":\"polkadot\",\"customrpc\":false,\"decimals\":0,\"isFirst\":false,\"isPressed\":false,\"isFixed\":false,\"isOpen\":0,\"isSubLast\":false,\"level\":0,\"position\":3,\"pricePrecision\":2,\"reputation\":0,\"sortNum\":2099087,\"unitDecimal\":10}]}"));
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

  String getBgIcon(int position, bool pressed) {
    if (position == 2) {
      return pressed
          ? 'assets/images/icon_import_coin_bg3_pressed.png'
          : 'assets/images/icon_import_coin_bg3.png';
    } else if (position == 3) {
      return pressed
          ? 'assets/images/icon_import_coin_bg4_pressed.png'
          : 'assets/images/icon_import_coin_bg4.png';
    }

    return pressed
        ? 'assets/images/icon_import_coin_bg0_pressed.png'
        : 'assets/images/icon_import_coin_bg0.png';
  }

  void _selectCoin(CoinDetail coinDetail) async {
    if (mService.plugin.basic.name != coinDetail.coinName) {
      if (_coinData.mnemonic != null &&
          _coinData.mnemonic.isNotEmpty &&
          isClicked == false) {
        oldNetwork = widget.service.plugin.basic.name;
        setState(() {
          isClicked = true;
          isTimeout = false;
        });
        Future.any([timeout(), getSignature(coinDetail)]).then((d) async {
          setState(() {
            isClicked = false;
            isTimeout = true;
          });
          if (d == 'timeout') {
            final service = await widget.initNetwork(oldNetwork);
            service.keyring.setCurrent(service.keyring.current);
            service.plugin.changeAccount(service.keyring.current);
          }
          channel.send(d);
        });
      } else {
        setState(() {
          isClicked = false;
        });
        channel.send("Not Spuurot");
      }
    }
  }

  Future timeout() {
    final com = Completer();
    final future = com.future;
    Timer(Duration(milliseconds: 45000), () {
      com.complete('timeout');
    });
    return future;
  }

  Future<String> getSignature(CoinDetail coinDetail) async {
    channel.send("Loading");
    final service = await widget.initNetwork(coinDetail.coinName);
    service.keyring.setCurrent(service.keyring.current);
    service.plugin.changeAccount(service.keyring.current);
    _changeLang(_coinData.language, service);

    VerifyResult verifyResult = null;
    String signature = null;
    final params = SignAsExtensionParam();
    params.msgType = "pub(bytes.sign)";
    while ((service.keyring.current.address == null ||
        signature == null ||
        verifyResult == null ||
        !verifyResult.isValid)) {
      if (isTimeout) {
        return "timeout";
      }
      try {
        service.store.account.setNewAccountKey(_coinData.mnemonic);
        service.store.account.setNewAccount(_coinData.name, password);
        final acc = await service.account.importAccount(
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

        params.request = {
          "address": service.keyring.current.address,
          "data": service.keyring.current.address,
        };

        final signResult =
            await Future.any([retry(), signAsExtension(service, params)]);
        if (signResult == "timeout") {
          continue;
        } else {
          signature = signResult;
        }
        final verify =
            await Future.any([retry(), signatureVerify(service, signature)]);
        if (verify == "timeout") {
          continue;
        } else {
          verifyResult = verify;
        }
      } on Exception catch (err) {
        print("err =======${err}");
        continue;
      }
    }
    setState(() {
      mService = service;
    });
    coinDetail.signature = signature;
    coinDetail.address = service.keyring.current.address;
    coinDetail.addressIndex = pathClient;
    Map<String, dynamic> map = service.keyring.current.toJson();
    map["icon"] = null;
    coinDetail.polkaInfo = json.encode(map);
    return json.encode(CoinDetail.toJson(coinDetail));
  }

  Future retry() {
    final com = Completer();
    final future = com.future;
    Timer(Duration(milliseconds: 2000), () {
      com.complete('timeout');
    });
    return future;
  }

  Future signatureVerify(AppService service, String signature) async {
    final verifyResult = await service.plugin.sdk.api.keyring.signatureVerify(
      service.keyring.current.address,
      signature,
      service.keyring.current.address,
    );
    return verifyResult;
  }

  Future<String> signAsExtension(
      AppService service, SignAsExtensionParam param) async {
    final res =
        await service.plugin.sdk.api.keyring.signAsExtension(password, param);
    return res.signature;
  }

  List<Widget> _buildCoinList() {
    final List<Widget> res = [];
    res.addAll(_coinData.coinDetails.map((i) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await _selectCoin(i);
        },
        onTapDown: (d) {
          setState(() {
            i.isPressed = true;
          });
        },
        onTapCancel: () {
          setState(() {
            i.isPressed = false;
          });
        },
        onTapUp: (d) {
          setState(() {
            i.isPressed = false;
          });
        },
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: 72,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(getBgIcon(i.position, i.isPressed)),
                  fit: BoxFit.fill),
            ),
            child: ImportCoinItem(
                getCoinCode(i.coinCode),
                i.coinName,
                "",
                i.coinCode.toLowerCase() == _coinData.selectCoin.toLowerCase(),
                i.position)),
      );
    }));
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _coinData != null
              ? Column(children: [..._buildCoinList()])
              : Container(),
        ));
  }
}
