import 'package:polka_module/common/consts.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polka_module/store/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/global.dart';

class TransferPageParams {
  TransferPageParams({
    this.address,
    this.redirect,
  });
  final String address;
  final String redirect;
}

class TransferPage extends StatefulWidget {
  const TransferPage(this.plugins, this.buildTarget);

  static final String route = '/assets/transfer';
  final List<PolkawalletPlugin> plugins;
  final BuildTargets buildTarget;

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();
  AppService service;
  Keyring keyring;

  final TextEditingController _amountCtrl = new TextEditingController();

  PolkawalletPlugin _chainTo;
  KeyPairData _accountTo;
  List<KeyPairData> _accountOptions = [];
  bool _keepAlive = true;

  String _accountToError;

  TxFeeEstimateResult _fee;
  List _xcmEnabledChains;

  bool _submitting = false;

  Future<String> _checkAccountTo(KeyPairData acc) async {
    if (service.keyring.allAccounts.indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await service.plugin.sdk.webView.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await service.plugin.sdk.api.account
          .checkAddressFormat(acc.address, _chainTo.basic.ss58);
      if (res != null && !res) {
        return I18n.of(context)
            .getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData acc) async {
    final error = await _checkAccountTo(acc);
    setState(() {
      _accountToError = error;
    });
  }

  Future<void> _onScan() async {
    final to =
        (await Navigator.of(context).pushNamed(ScanPage.route) as QRCodeResult);
    if (to == null) return;

    _updateAccountTo(to.address.address, name: to.address.name);
  }

  bool _isFromXTokensParaChain() {
    return service.plugin.basic.name == para_chain_name_karura ||
        service.plugin.basic.name == para_chain_name_bifrost;
  }

  bool _isToParaChain() {
    return _chainTo.basic.name != relay_chain_name_ksm &&
        _chainTo.basic.name != relay_chain_name_dot &&
        _chainTo.basic.name != para_chain_name_statemine &&
        _chainTo.basic.name != para_chain_name_statemint;
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null &&
        _formKey.currentState.validate() &&
        !_submitting) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol = (service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals = (service.plugin.networkState.tokenDecimals ?? [12])[0];

      /// send XCM tx if cross chain
      if (_chainTo.basic.name != service.plugin.basic.name) {
        final isFromXTokensParaChain = _isFromXTokensParaChain();
        final isToParaChain = _isToParaChain();

        final isToParent = _chainTo.basic.name == relay_chain_name_ksm ||
            _chainTo.basic.name == relay_chain_name_dot;

        final txModule = isToParent
            ? 'polkadotXcm'
            : isFromXTokensParaChain
                ? 'xTokens'
                : 'xcmPallet';
        final txCall = isToParaChain
            ? isFromXTokensParaChain
                ? 'transfer'
                : 'reserveTransferAssets'
            : 'teleportAssets';

        final amount =
            Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString();
        final isV1XCM = await service.plugin.sdk.webView.evalJavascript(
            'api.createType(api.tx.$txModule.$txCall.meta.args[0].toJSON()["type"]).defKeys.includes("V1")',
            wrapPromise: false);
        final is9100 = await service.plugin.sdk.webView.evalJavascript(
            'api.tx.$txModule.$txCall.meta.args.length === 5',
            wrapPromise: false);

        String destPubKey = _accountTo.pubKey;
        // we need to decode address for the pubKey here
        if (destPubKey == null || destPubKey.isEmpty) {
          setState(() {
            _submitting = true;
          });
          final pk = await service.plugin.sdk.api.account
              .decodeAddress([_accountTo.address]);
          setState(() {
            _submitting = false;
          });
          if (pk == null) return null;

          destPubKey = pk.keys.toList()[0];
        }

        List paramsX;
        if (isFromXTokensParaChain && isToParaChain) {
          /// this is transfer KAR from Karura to Bifrost
          /// paramsX: [token, amount, dest, dest_weight]
          paramsX = [
            {'Token': symbol},
            amount,
            [
              1,
              {
                'X2': [
                  {'Parachain': _chainTo.basic.parachainId},
                  {
                    'AccountId32': {'id': destPubKey, 'network': 'Any'}
                  }
                ]
              }
            ],
            xcm_dest_weight_bifrost
          ];
        } else {
          /// this is KSM/DOT transfer RelayChain <-> ParaChain
          /// paramsX: [dest, beneficiary, assets, dest_weight]
          final dest = {
            'X1': isToParent
                ? 'Parent'
                : {'Parachain': _chainTo.basic.parachainId}
          };
          final beneficiary = {
            'X1': {
              'AccountId32': {'id': destPubKey, 'network': 'Any'}
            }
          };
          final assets = [
            {
              'ConcreteFungible': isToParent
                  ? {
                      'amount': amount,
                      'id': {'X1': 'Parent'}
                    }
                  : {'amount': amount}
            }
          ];
          paramsX = isV1XCM
              ? is9100
                  ? [
                      {'V0': dest},
                      {'V0': beneficiary},
                      {'V0': assets},
                      0,
                      xcm_dest_weight_ksm
                    ]
                  : [
                      {'V0': dest},
                      {'V0': beneficiary},
                      {'V0': assets},
                      0
                    ]
              : [dest, beneficiary, assets, xcm_dest_weight_ksm];
        }
        return TxConfirmParams(
          txTitle: '${dic['transfer']} $symbol (${dic['cross.chain']})',
          module: txModule,
          call: txCall,
          txDisplay: {
            "chain": _chainTo.basic.name,
            "destination": _accountTo.address,
            "currency": symbol,
            "amount": _amountCtrl.text.trim(),
          },
          params: paramsX,
        );
      }

      /// else send normal transfer
      // params: [to, amount]
      final params = [
        _accountTo.address,
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ];
      return TxConfirmParams(
        txTitle: '${dic['transfer']} $symbol',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplay: {
          "destination": _accountTo.address,
          "currency": symbol,
          "amount": _amountCtrl.text.trim(),
        },
        params: params,
      );
    }
    return null;
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final txParams = await _getTxParams();
    if (txParams == null) return '';

    final txInfo = TxInfoData(
        txParams.module,
        txParams.call,
        TxSenderData(
            service.keyring.current.address, service.keyring.current.pubKey));

    final fee =
        await service.plugin.sdk.api.tx.estimateFees(txInfo, txParams.params);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  BigInt _getExistAmount(BigInt notTransferable, BigInt existentialDeposit) {
    return notTransferable > BigInt.zero
        ? notTransferable >= existentialDeposit
            ? BigInt.zero
            : existentialDeposit - notTransferable
        : existentialDeposit;
  }

  Future<void> _setMaxAmount(BigInt available, BigInt existAmount) async {
    final decimals = (service.plugin.networkState.tokenDecimals ?? [12])[0];
    final fee = await _getTxFee();
    // keep 1.2 * amount of estimated fee left
    final max = available -
        Fmt.balanceInt(fee) -
        (Fmt.balanceInt(fee) ~/ BigInt.from(5)) -
        (_keepAlive ? existAmount : BigInt.zero);
    if (mounted) {
      setState(() {
        _amountCtrl.text = max > BigInt.zero
            ? Fmt.bigIntToDouble(max, decimals).toStringAsFixed(8)
            : '0';
      });
    }
  }

  Future<void> _updateAccountTo(String address, {String name}) async {
    final acc = KeyPairData();
    acc.address = address;
    if (name != null) {
      acc.name = name;
    }
    setState(() {
      _accountTo = acc;
    });

    final res = await Future.wait([
      service.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc),
    ]);
    if (res != null && res[0] != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = address;
      if (name != null) {
        accWithIcon.name = name;
      }

      final List icon = res[0];
      accWithIcon.icon = icon[0][1];

      setState(() {
        _accountTo = accWithIcon;
        _accountToError = res[1];
      });
    }
  }

  /// only support：
  /// Kusama -> Karura
  /// Kusama -> Statemine
  /// Statemine -> Kusama
  void _onSelectChain() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final allPlugins = service.allPlugins.toList();
    allPlugins.retainWhere((e) {
      return [service.plugin.basic.name, ..._xcmEnabledChains]
              .indexOf(e.basic.name) >
          -1;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(dic['cross.para.select']),
        actions: allPlugins.map((e) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: e.basic.icon,
                  ),
                ),
                Text(
                  e.basic.name.toUpperCase(),
                )
              ],
            ),
            onPressed: () async {
              if (e.basic.name != _chainTo.basic.name) {
                // set ss58 of _chainTo so we can get according address
                // from AddressInputField
                service.keyring.setSS58(e.basic.ss58);
                final options = service.keyring.allWithContacts.toList();
                service.keyring.setSS58(service.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  final isInAccountList = options
                          .indexWhere((e) => e.pubKey == _accountTo.pubKey) >=
                      0;
                  if (isInAccountList) {
                    _accountTo = options
                        .firstWhere((e) => e.pubKey == _accountTo.pubKey);
                  }
                });

                _validateAccountTo(_accountTo);

                // update estimated tx fee if switch ToChain
                _getTxFee(
                    isXCM: e.basic.name != relay_chain_name_ksm, reload: true);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<int> initSdk() async {
    Keyring _keyring = Keyring();
    await _keyring
        .init(widget.plugins.map((e) => e.basic.ss58).toSet().toList());

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

    await service.plugin.beforeStart(
      _keyring,
      jsCode: useLocalJS
          ? WalletApi.getPolkadotJSCode(
              store.storage, service.plugin.basic.name)
          : null,
    );
    if (_keyring.keyPairs.length > 0) {
      store.assets.loadCache(_keyring.current, service.plugin.basic.name);
    }
    this.service = service;
    this.keyring = _keyring;
    return _keyring.allAccounts.length;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initSdk();
      _getTxFee();

      final Map<String, dynamic> arguments =
          Map<String, dynamic>.from(ModalRoute.of(context).settings.arguments);
      final TransferPageParams args = arguments["params"];

      if (args.address != null) {
        _updateAccountTo(args.address);
      } else {
        if (service.keyring.allWithContacts.length > 0) {
          setState(() {
            _accountTo = service.keyring.allWithContacts[0];
          });
        }
      }

      final xcmEnabledChains = await service.store.settings
          .getXcmEnabledChains(service.plugin.basic.name);
      setState(() {
        _chainTo = service.plugin;
        _accountOptions = service.keyring.allWithContacts.toList();
        _xcmEnabledChains = xcmEnabledChains;
      });
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<int>(
      future: initSdk(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && service != null) {
          return Observer(
            builder: (_) {
              final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
              final symbol =
                  (service.plugin.networkState.tokenSymbol ?? [''])[0];
              final decimals =
                  (service.plugin.networkState.tokenDecimals ?? [12])[0];

              final available = Fmt.balanceInt(
                  (service.plugin.balances.native?.availableBalance ?? 0)
                      .toString());
              final reserved = Fmt.balanceInt(
                  (service.plugin.balances.native?.reservedBalance ?? 0)
                      .toString());
              final locked = Fmt.balanceInt(
                  (service.plugin.balances.native?.lockedBalance ?? 0)
                      .toString());
              final notTransferable = reserved + locked;

              final canCrossChain =
                  _xcmEnabledChains != null && _xcmEnabledChains.length > 0;

              final destChainName = _chainTo?.basic?.name ?? 'karura';
              final isCrossChain = service.plugin.basic.name != destChainName;

              final existDeposit = Fmt.balanceInt(service
                  .plugin.networkConst['balances']['existentialDeposit']
                  .toString());
              final existAmount =
                  _getExistAmount(notTransferable, existDeposit);

              final destExistDeposit = isCrossChain
                  ? Fmt.balanceInt(
                      xcm_send_fees[destChainName]['existentialDeposit'])
                  : BigInt.zero;
              final destFee = isCrossChain
                  ? Fmt.balanceInt(xcm_send_fees[destChainName]['fee'])
                  : BigInt.zero;

              final colorGrey = Theme.of(context).unselectedWidgetColor;
              return Scaffold(
                appBar: AppBar(
                  title: Text('${dic['transfer']} $symbol'),
                  centerTitle: true,
                  actions: <Widget>[
                    IconButton(
                      padding: EdgeInsets.only(right: 8),
                      icon: SvgPicture.asset(
                        'assets/images/scan.svg',
                        color: Theme.of(context).cardColor,
                        width: 28,
                      ),
                      onPressed: _onScan,
                    )
                  ],
                ),
                body: SafeArea(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AddressInputField(
                                service.plugin.sdk.api,
                                _accountOptions,
                                label: dic['cross.to'],
                                initialValue: _accountTo,
                                onChanged: (KeyPairData acc) async {
                                  final accValid = await _checkAccountTo(acc);
                                  setState(() {
                                    _accountTo = acc;
                                    _accountToError = accValid;
                                  });
                                },
                                key: ValueKey<KeyPairData>(_accountTo),
                              ),
                              _accountToError != null
                                  ? Container(
                                      margin: EdgeInsets.only(top: 4),
                                      child: Text(_accountToError,
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.red)),
                                    )
                                  : Container(),
                              canCrossChain
                                  ? GestureDetector(
                                      child: Container(
                                        color: Theme.of(context).canvasColor,
                                        margin: EdgeInsets.only(
                                            top: 16, bottom: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                dic['to.chain'],
                                                style: TextStyle(
                                                    color: colorGrey,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      width: 32,
                                                      height: 32,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(32),
                                                        child: _chainTo
                                                            ?.basic?.icon,
                                                      ),
                                                    ),
                                                    Text(destChainName
                                                        .toUpperCase())
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    isCrossChain
                                                        ? TextTag(
                                                            dic['cross.chain'],
                                                            margin:
                                                                EdgeInsets.only(
                                                                    right: 8),
                                                            color: Colors.red)
                                                        : Container(),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 18,
                                                      color: colorGrey,
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: _onSelectChain,
                                    )
                                  : Container(),
                              Form(
                                key: _formKey,
                                child: TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    hintText: dic['amount'],
                                    labelText:
                                        '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                                      available,
                                      decimals,
                                      lengthMax: 6,
                                    )})',
                                    suffix: GestureDetector(
                                      child: Text(dic['amount.max'],
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      onTap: () =>
                                          _setMaxAmount(available, existAmount),
                                    ),
                                  ),
                                  inputFormatters: [
                                    UI.decimalInputFormatter(decimals)
                                  ],
                                  controller: _amountCtrl,
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  validator: (v) {
                                    if (v.isEmpty) {
                                      return dic['amount.error'];
                                    }
                                    final input = Fmt.tokenInt(v, decimals);
                                    final feeLeft = available -
                                        input -
                                        (_keepAlive
                                            ? existAmount
                                            : BigInt.zero);
                                    BigInt fee = BigInt.zero;
                                    if (feeLeft <
                                            Fmt.tokenInt('0.02', decimals) &&
                                        _fee?.partialFee != null) {
                                      fee = Fmt.balanceInt(
                                          _fee.partialFee.toString());
                                    }
                                    if (feeLeft - fee < BigInt.zero) {
                                      return dic['amount.low'];
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              isCrossChain
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: TapTooltip(
                                              message: dic['amount.exist.msg'],
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 4),
                                                    child: Text(
                                                        dic['cross.exist']),
                                                  ),
                                                  Icon(
                                                    Icons.info,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .unselectedWidgetColor,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                              flex: 0,
                                              child: Text(
                                                  '${Fmt.priceCeilBigInt(destExistDeposit, decimals, lengthMax: 6)} $symbol')),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              isCrossChain
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Text(dic['cross.fee']),
                                            ),
                                          ),
                                          Text(
                                              '${Fmt.priceCeilBigInt(destFee, decimals, lengthMax: 6)} $symbol'),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TapTooltip(
                                        message: dic['amount.exist.msg'],
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Text(dic['amount.exist']),
                                            ),
                                            Icon(
                                              Icons.info,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .unselectedWidgetColor,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                        '${Fmt.priceCeilBigInt(existDeposit, decimals, lengthMax: 6)} $symbol'),
                                  ],
                                ),
                              ),
                              _fee?.partialFee != null
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Text(dic['amount.fee']),
                                            ),
                                          ),
                                          Text(
                                              '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee?.partialFee?.toString()), decimals, lengthMax: 6)} $symbol'),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      flex: 0,
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dic['transfer.alive']),
                                      ),
                                    ),
                                    TapTooltip(
                                      message: dic['transfer.alive.msg'],
                                      child: Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                      ),
                                    ),
                                    Expanded(child: Container(width: 2)),
                                    CupertinoSwitch(
                                      value: _keepAlive,
                                      // account is not allow_death if it has
                                      // locked/reserved balances
                                      onChanged: notTransferable > BigInt.zero
                                          ? null
                                          : (res) {
                                              setState(() {
                                                _keepAlive = res;
                                              });
                                            },
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: TxButton(
                          text: dic['make'],
                          getTxParams: _getTxParams,
                          onFinish: (res) {
                            if (res != null) {
                              Navigator.of(context).pop(res);
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Container(color: Theme.of(context).canvasColor);
        }
      },
    ));
  }
}
