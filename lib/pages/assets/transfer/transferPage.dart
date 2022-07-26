import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:polka_module/common/components/cupertinoAlertDialogWithCheckbox.dart';
import 'package:polka_module/common/components/jumpToLink.dart';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/utils/Utils.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_plugin_chainx/common/components/UI.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/amountTextFormField.dart';
import 'package:polkawallet_ui/components/v3/sendAddressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/sliderThumbShape.dart';
import 'package:polka_module/store/types/transferPageParams.dart';

const relay_chain_name_polkadot = 'polkadot';

class TransferPage extends StatefulWidget {
  const TransferPage(this.service);

  static final String route = '/assets/transfer';
  final AppService service;

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  double _tip = 0;
  BigInt _tipValue = BigInt.zero;

  bool showSlider = false;

  ui.Image _image;

  int rate = 0;
  String currency;

  PolkawalletPlugin _chainTo;
  KeyPairData _accountTo;
  List<KeyPairData> _accountOptions = [];
  bool _keepAlive = true;

  String _accountToError;

  TxFeeEstimateResult _fee;
  List _xcmEnabledChains;

  bool _submitting = false;

  Future<String> _checkBlackList(KeyPairData acc) async {
    final addresses = await widget.service.plugin.sdk.api.account
        .decodeAddress([acc.address]);
    if (addresses != null) {
      final pubKey = addresses.keys.toList()[0];
      if (widget.service.plugin.sdk.blackList.indexOf(pubKey) > -1) {
        return I18n.of(context)
            .getDic(i18n_full_dic_app, 'account')['bad.scam'];
      }
    }
    return null;
  }

  Future<String> _checkAccountTo(KeyPairData acc) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;

    if (widget.service.keyring.allAccounts
            .indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.service.plugin.sdk.webView
        .evalJavascript('(account.checkAddressFormat != undefined ? {}:null)',
            wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.service.plugin.sdk.api.account
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
    return widget.service.plugin.basic.name == para_chain_name_karura ||
        widget.service.plugin.basic.name == para_chain_name_bifrost;
  }

  bool _isToParaChain() {
    return _chainTo.basic.name != relay_chain_name_ksm &&
        _chainTo.basic.name != relay_chain_name_dot &&
        _chainTo.basic.name != para_chain_name_statemine &&
        _chainTo.basic.name != para_chain_name_statemint;
  }

  TxConfirmParams _getDotAcalaBridgeTxParams() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    return TxConfirmParams(
      txTitle: '${dic['transfer']} $symbol (${dic['cross.chain']})',
      module: 'balances',
      call: 'transfer',
      txDisplay: {
        dic['to.chain']: _chainTo.basic.name,
      },
      txDisplayBold: {
        dic['amount']: Text(
          _amountCtrl.text.trim() + ' $symbol',
          style: Theme.of(context).textTheme.headline1,
        ),
        dic['to']: Row(
          children: [
            AddressIcon(_accountTo.address, svg: _accountTo.icon),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                child: Text(
                  Fmt.address(_accountTo.address, pad: 8),
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
            ),
          ],
        ),
      },
      params: [
        bridge_account[_chainTo.basic.name],
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ],
    );
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null &&
        _formKey.currentState.validate() &&
        !_submitting) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      /// send XCM tx if cross chain
      if (_chainTo.basic.name != widget.service.plugin.basic.name) {
        // todo: remove this after polkadot xcm alive
        if (widget.service.plugin.basic.name == relay_chain_name_polkadot &&
            _chainTo.basic.name == para_chain_name_acala) {
          return _getDotAcalaBridgeTxParams();
        }

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
            : 'limitedTeleportAssets';

        final amount =
            Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString();
        final isV1XCM = await widget.service.plugin.sdk.webView.evalJavascript(
            'api.createType(api.tx.$txModule.$txCall.meta.args[0].toJSON()["type"]).defKeys.includes("V1")',
            wrapPromise: false);
        final is9100 = await widget.service.plugin.sdk.webView.evalJavascript(
            'api.tx.$txModule.$txCall.meta.args.length === 5',
            wrapPromise: false);

        String destPubKey = _accountTo.pubKey;
        // we need to decode address for the pubKey here
        if (destPubKey == null || destPubKey.isEmpty) {
          setState(() {
            _submitting = true;
          });
          final pk = await widget.service.plugin.sdk.api.account
              .decodeAddress([_accountTo.address]);
          setState(() {
            _submitting = false;
          });
          if (pk == null) return null;

          destPubKey = pk.keys.toList()[0];
        }

        List paramsX;
        if (isFromXTokensParaChain && isToParaChain) {
          final dest = {
            'parents': 1,
            'interior': {
              'X2': [
                {'Parachain': _chainTo.basic.parachainId},
                {
                  'AccountId32': {'id': destPubKey, 'network': 'Any'}
                }
              ]
            }
          };

          /// this is transfer KAR from Karura to Bifrost
          /// paramsX: [token, amount, dest, dest_weight]
          paramsX = [
            {'Token': symbol},
            amount,
            {'V1': dest},
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
                      "Unlimited"
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
            dic['to.chain']: _chainTo.basic.name,
          },
          txDisplayBold: {
            dic['amount']: Text(
              _amountCtrl.text.trim() + ' $symbol',
              style: Theme.of(context).textTheme.headline1,
            ),
            dic['to']: Row(
              children: [
                AddressIcon(_accountTo.address, svg: _accountTo.icon),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                    child: Text(
                      Fmt.address(_accountTo.address, pad: 8),
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
              ],
            ),
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
        txDisplayBold: {
          dic['to']: Row(
            children: [
              AddressIcon(_accountTo.address, svg: _accountTo.icon),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo.address, pad: 8),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
          dic['amount']: Text(
            _amountCtrl.text.trim() + ' $symbol',
            style: Theme.of(context).textTheme.headline1,
          ),
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

    TxConfirmParams txParams;
    if (_fee == null) {
      txParams = TxConfirmParams(
        txTitle: '',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplay: {},
        params: [
          widget.service.keyring.allWithContacts[0].address,
          '10000000000',
        ],
      );
    } else {
      txParams = await _getTxParams();
    }

    final txInfo = TxInfoData(
        txParams.module,
        txParams.call,
        TxSenderData(widget.service.keyring.current.address,
            widget.service.keyring.current.pubKey));
    final fee = await widget.service.plugin.sdk.api.tx
        .estimateFees(txInfo, txParams.params);
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
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
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
      widget.service.plugin.sdk.api.account.getAddressIcons([acc.address]),
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
  ///
  /// DOT from polkadot to acala with acala bridge
  void _onSelectChain() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final allPlugins = widget.service.allPlugins.toList();
    allPlugins.retainWhere((e) {
      return [widget.service.plugin.basic.name, ..._xcmEnabledChains]
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
                // todo: remove this after polkadot xcm alive
                final isAcalaBridge = widget.service.plugin.basic.name ==
                        relay_chain_name_polkadot &&
                    e.basic.name == para_chain_name_acala;
                if (isAcalaBridge) {
                  await _showAcalaBridgeAlert();
                }

                // set ss58 of _chainTo so we can get according address
                // from AddressInputField
                widget.service.keyring.setSS58(e.basic.ss58);
                final options = widget.service.keyring.allWithContacts.toList();
                widget.service.keyring
                    .setSS58(widget.service.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  if (e.basic.name != widget.service.plugin.basic.name) {
                    _accountTo = widget.service.keyring.current;
                  }
                  if (isAcalaBridge) {
                    _keepAlive = true;
                  }
                });

                _validateAccountTo(_accountTo);

                if (_amountCtrl.text.trim().toString().length > 0) {
                  // update estimated tx fee if switch ToChain
                  _getTxFee(
                      isXCM: e.basic.name != relay_chain_name_ksm,
                      reload: true);
                }
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

  Future<void> _showAcalaBridgeAlert() async {
    await showCupertinoDialog(
        context: context,
        builder: (_) {
          final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
          return CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dic['dot.bridge']),
                JumpToLink(
                  'https://wiki.acala.network/acala/get-started/acalas-dot-bridge',
                  text: '',
                )
              ],
            ),
            content: CupertinoAlertDialogContentWithCheckbox(
              content: Text(dic['dot.bridge.info']),
            ),
          );
        });
  }

  void _onSwitchCheckAlive(bool res, BigInt notTransferable) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    if (!res) {
      // todo: remove this after polkadot xcm alive
      if (widget.service.plugin.basic.name == relay_chain_name_polkadot &&
          _chainTo?.basic?.name == para_chain_name_acala) {
        return;
      }

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['note']),
            content: Text(dic['note.msg1']),
            actions: <Widget>[
              CupertinoButton(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_ui, 'common')['cancel']),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();

                  if (notTransferable > BigInt.zero) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CupertinoAlertDialog(
                          title: Text(dic['note']),
                          content: Text(dic['note.msg2']),
                          actions: <Widget>[
                            CupertinoButton(
                              child: Text(I18n.of(context)
                                  .getDic(i18n_full_dic_ui, 'common')['ok']),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      _keepAlive = res;
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _keepAlive = res;
      });
    }
  }

  Future<KeyPairData> _getAccountFromInput(String input) async {
    // return local account list if input empty
    if (input.isEmpty || input.trim().length < 3) {
      return null;
    }

    // todo: eth address not support now
    if (input.trim().startsWith('0x')) {
      return null;
    }

    // check if user input is valid address or indices
    final checkAddress =
        await widget.service.plugin.sdk.api.account.decodeAddress([input]);
    if (checkAddress == null) {
      return null;
    }

    final acc = KeyPairData();
    acc.address = input;
    acc.pubKey = checkAddress.keys.toList()[0];
    if (input.length < 47) {
      // check if input indices in local account list
      final int indicesIndex = _accountOptions.indexWhere((e) {
        final Map accInfo = e.indexInfo;
        return accInfo != null && accInfo['accountIndex'] == input;
      });
      if (indicesIndex >= 0) {
        return _accountOptions[indicesIndex];
      }
      // query account address with account indices
      final queryRes = await widget.service.plugin.sdk.api.account
          .queryAddressWithAccountIndex(input);
      if (queryRes != null) {
        acc.address = queryRes;
        acc.name = input;
      }
    } else {
      // check if input address in local account list
      final int addressIndex =
          _accountOptions.indexWhere((e) => _itemAsString(e).contains(input));
      if (addressIndex >= 0) {
        return _accountOptions[addressIndex];
      }
    }

    // fetch address info if it's a new address
    final res = await widget.service.plugin.sdk.api.account
        .getAddressIcons([acc.address]);
    if (res != null) {
      if (res.length > 0) {
        acc.icon = res[0][1];
      }

      // The indices query too slow, so we use address as account name
      if (acc.name == null) {
        acc.name = Fmt.address(acc.address);
      }
    }
    return acc;
  }

  String _itemAsString(KeyPairData item) {
    final Map accInfo = _getAddressInfo(item);
    String idx = '';
    if (accInfo != null && accInfo['accountIndex'] != null) {
      idx = accInfo['accountIndex'];
    }
    if (item.name != null) {
      return '${item.name} $idx ${item.address}';
    }
    return '${UI.accountDisplayNameString(item.address, accInfo)} $idx ${item.address}';
  }

  Map _getAddressInfo(KeyPairData acc) {
    return acc.indexInfo;
  }

  void _onTipChanged(double tip) {
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    /// tip division from 0 to 19:
    /// 0-10 for 0-0.1
    /// 10-19 for 0.1-1
    BigInt value = Fmt.tokenInt('0.01', decimals) * BigInt.from(tip.toInt());
    if (tip > 10) {
      value = Fmt.tokenInt('0.1', decimals) * BigInt.from((tip - 9).toInt());
    }
    setState(() {
      _tip = tip;
      _tipValue = value;
    });
  }

  Future<ui.Image> load(String asset) async {
    ByteData data = await rootBundle.load(asset);
    ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 36, targetHeight: 36);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  String getMinerFeeDes(int decimals, String symbol) {
    String feeStr = Fmt.priceCeilBigInt(
        Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")) + _tipValue,
        decimals,
        lengthMax: 6);
    String moneyStr = Fmt.priceCeilBigInt(
        (Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")) + _tipValue) *
            BigInt.from(rate),
        decimals + 2,
        lengthMax: 2);
    return '${feeStr} ${symbol} ≈ ${Utils.getCurrencySymbol(currency)} ${moneyStr}';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      print("lang========${Localizations.localeOf(context).toString()}");
      print("network========${widget.service.store.settings.network}");
      print(
          "widget.service.keyring.current==========${widget.service.keyring.current}");

      load('assets/images/icon_slider.png').then((i) {
        setState(() {
          _image = i;
        });
      });

      final params = Utils.getParams(ModalRoute.of(context).settings.arguments);
      TransferPageParams args;

      if (params != null) {
        if (params is TransferPageParams) {
          args = Utils.getParams(ModalRoute.of(context).settings.arguments)
              as TransferPageParams;
        } else {
          args = TransferPageParams.fromJson(
              new Map<String, dynamic>.from(params));
        }
      }

      if (args?.address != null) {
        _updateAccountTo(args.address);
      } else {
        setState(() {
          _accountTo = widget.service.keyring.current;
        });
      }
      if (args?.rate != null) {
        setState(() {
          rate = args?.rate;
        });
      }
      if (args?.currency != null) {
        setState(() {
          currency = args?.currency;
        });
      }

      final xcmEnabledChains = await widget.service.store.settings
          .getXcmEnabledChains(widget.service.plugin.basic.name);

      setState(() {
        _accountOptions = widget.service.keyring.allWithContacts.toList();
        _xcmEnabledChains = xcmEnabledChains;

        if (args?.chainTo != null) {
          final chainToIndex = xcmEnabledChains.indexOf(args.chainTo);
          if (chainToIndex > -1) {
            _chainTo = widget.service.allPlugins
                .firstWhere((e) => e.basic.name == args.chainTo);
            _accountTo = widget.service.keyring.current;
            return;
          }
        }
        _chainTo = widget.service.plugin;
      });

      // todo: remove this after polkadot xcm alive
      if (widget.service.plugin.basic.name == relay_chain_name_polkadot &&
          args?.chainTo == para_chain_name_acala) {
        _showAcalaBridgeAlert();
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        print("lang========${Localizations.localeOf(context).toString()}");
        print("local========${I18n.of(context).locale}");
        print("languageCode========${I18n.of(context).locale.languageCode}");
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final connected = widget.service.plugin.sdk.api.connectedNode != null;

        final available = Fmt.balanceInt(
            (widget.service.plugin.balances.native?.availableBalance ?? 0)
                .toString());
        final notTransferable = Fmt.balanceInt(
                (widget.service.plugin.balances.native?.reservedBalance ?? 0)
                    .toString()) +
            Fmt.balanceInt(
                (widget.service.plugin.balances.native?.lockedBalance ?? 0)
                    .toString());

        final canCrossChain =
            _xcmEnabledChains != null && _xcmEnabledChains.length > 0;

        final destChainName = _chainTo?.basic?.name ?? 'karura';
        final isCrossChain = widget.service.plugin.basic.name != destChainName;

        // todo: remove this after polkadot xcm alive
        final isAcalaBridge =
            widget.service.plugin.basic.name == relay_chain_name_polkadot &&
                _chainTo?.basic?.name == para_chain_name_acala;

        final existDeposit = Fmt.balanceInt(
            ((widget.service.plugin.networkConst['balances'] ??
                        {})['existentialDeposit'] ??
                    0)
                .toString());
        final existAmount = _getExistAmount(notTransferable, existDeposit);

        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['fee'])
            : BigInt.zero;

        final colorGrey = Theme.of(context).unselectedWidgetColor;

        final labelStyle = Theme.of(context).textTheme.headline4;

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['transfer']} $symbol',
                style: TextStyle(color: Color(0xFF515151), fontSize: 17)),
            centerTitle: true,
            leading: BackBtn(),
            leadingWidth: 60,
          ),
          backgroundColor: Color(0xFFF5F6F8),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Visibility(
                                          visible: !isAcalaBridge,
                                          child: SendAddressTextFormField(
                                            widget.service.plugin.sdk.api,
                                            _accountOptions,
                                            notInputAddress: true,
                                            labelText: dic['cross.to'],
                                            labelStyle: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF333333),
                                                fontWeight: FontWeight.w500),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF333333),
                                                fontWeight: FontWeight.w400),
                                            hintText:
                                                '${dic['input.address.hint.prefix']}${symbol}${dic['input.address.hint.suffix']}',
                                            hintStyle: TextStyle(
                                                color: Color(0xFF999999),
                                                fontSize: 14,
                                                fontFamily:
                                                    'PingFangSC-Regular'),
                                            initialValue: _accountTo,
                                            // formKey: _formKey,
                                            onChanged: (KeyPairData acc) async {
                                              final accValid =
                                                  await _checkAccountTo(acc);
                                              setState(() {
                                                _accountTo = acc;
                                                _accountToError = accValid;
                                              });
                                            },
                                            key: ValueKey<KeyPairData>(
                                                _accountTo),
                                            addressBookPressed: () {
                                              BoostNavigator.instance.push(
                                                  'native_present_AddressBookActivity',
                                                  arguments: {
                                                    'test': '123123'
                                                  });
                                            },
                                          ),
                                        ),
                                        Container(height: 20.h),
                                        AmountTextFormField(
                                          widget.service.plugin.sdk.api,
                                          _accountOptions,
                                          symbol: symbol,
                                          rate: rate,
                                          labelText: dic['transfer.amount'],
                                          labelStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF333333),
                                              fontWeight: FontWeight.w500),
                                          currencyHintText: '0.00',
                                          coinHintText: '0.00',
                                          balance: Fmt.priceFloorBigInt(
                                            available,
                                            decimals,
                                            lengthMax: 6,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Color(0xFF999999),
                                            fontSize: 17,
                                            fontFamily: 'PingFangSC-Regular',
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            height: 1,
                                          ),
                                          initialValue: _accountTo,
                                          // formKey: _formKey,
                                          onChanged: (KeyPairData acc) async {
                                            final accValid =
                                                await _checkAccountTo(acc);
                                            setState(() {
                                              _accountTo = acc;
                                              _accountToError = accValid;
                                            });
                                          },
                                          key:
                                              ValueKey<KeyPairData>(_accountTo),
                                        ),
                                      ],
                                    ),
                                  ),
                                ])),
                        Container(
                          margin: EdgeInsets.only(left: 15, top: 12, right: 15),
                          padding: EdgeInsets.only(left: 15, right: 15),
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(8)),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                  child: GestureDetector(
                                child: Row(
                                  children: [
                                    Text(
                                      '矿工费',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w400),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(left: 4),
                                      transform:
                                          Matrix4.translationValues(0, -4, 0),
                                      child: Image.asset(
                                        'assets/images/icon_question.png',
                                        width: 8,
                                        height: 8,
                                      ),
                                    )
                                  ],
                                ),
                              )),
                              Container(
                                child: Row(children: [
                                  Text(
                                    '${getMinerFeeDes(decimals, symbol)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
                                        fontWeight: FontWeight.w400),
                                  )
                                ]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            margin:
                                EdgeInsets.only(top: 12, left: 15, right: 15),
                            child: Column(
                              children: [
                                GestureDetector(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        dic['advanced'],
                                        style: TextStyle(
                                            color: showSlider
                                                ? Color(0xFF5887E3)
                                                : Color(0xFF333333),
                                            fontSize: 12),
                                      ),
                                      Image.asset(
                                        showSlider
                                            ? 'assets/images/icon_arrow_up.png'
                                            : 'assets/images/icon_arrow_down.png',
                                        width: 22,
                                        height: 22,
                                      ),
                                    ],
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    print('123123123');
                                    setState(() {
                                      showSlider = !showSlider;
                                    });
                                  },
                                ),
                              ],
                            )),
                        Visibility(
                          visible: showSlider,
                          child: Container(
                              margin:
                                  EdgeInsets.only(left: 15, top: 10, right: 15),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                    const Radius.circular(8)),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                          child: GestureDetector(
                                        child: Row(
                                          children: [
                                            Text(
                                              '小费',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF333333),
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(left: 4),
                                              transform:
                                                  Matrix4.translationValues(
                                                      0, -4, 0),
                                              child: Image.asset(
                                                'assets/images/icon_question.png',
                                                width: 8,
                                                height: 8,
                                              ),
                                            )
                                          ],
                                        ),
                                      ))
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Text('0',
                                          style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14)),
                                      Expanded(
                                        child: SliderTheme(
                                            data: SliderThemeData(
                                                trackHeight: 6,
                                                activeTrackColor:
                                                    Color(0xFF8FBED5),
                                                inactiveTrackColor:
                                                    Color(0xFFf2f2f2),
                                                overlayColor:
                                                    Colors.transparent,
                                                activeTickMarkColor:
                                                    Colors.transparent,
                                                inactiveTickMarkColor:
                                                    Colors.transparent,
                                                thumbShape:
                                                    SliderThumbShape(_image)),
                                            child: Slider(
                                              min: 0,
                                              max: 19,
                                              divisions: 19,
                                              value: _tip,
                                              onChanged: _onTipChanged,
                                            )),
                                      ),
                                      Text('1',
                                          style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14))
                                    ],
                                  ),
                                  Text(
                                    '${Fmt.token(_tipValue, decimals)} $symbol',
                                    style: TextStyle(
                                        fontSize: 14, color: Color(0xFF999999)),
                                  ),
                                ],
                              )),
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 32, right: 32),
                  height: 82,
                  color: Colors.white,
                  child: TxButton(
                    text: connected ? dic['next'] : dic['connecting'],
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                    getTxParams: connected ? _getTxParams : () => null,
                    imageType: 2,
                    height: 64,
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
  }
}
