import 'dart:async';

import 'package:polka_module/common/components/jumpToLink.dart';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/pages/profile/acalaCrowdLoan/acaCrowdLoanFormPage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

const acaThemeColor = MaterialColor(
  0xFF7E74FA,
  const <int, Color>{
    50: const Color(0xFFEBEAFC),
    100: const Color(0xFFEBEAFC),
    200: const Color(0xFFEBEAFC),
    300: const Color(0xFFEBEAFC),
    400: const Color(0xFF7E74FA),
    500: const Color(0xFF7E74FA),
    600: const Color(0xFF7E74FA),
    700: const Color(0xFF7E74FA),
    800: const Color(0xFF7E74FA),
    900: const Color(0xFF7E74FA),
  },
);

const aca_statement_store_key = 'aca_statement_store_key';
const aca_token_decimal = 12;
const dot_token_decimal = 10;

class AcaCrowdLoanPage extends StatefulWidget {
  AcaCrowdLoanPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/public/aca/auction';

  static BigInt contributeAmountMax = BigInt.from(10000000000000000);
  static BigInt contributeAmountMaxDivider = BigInt.from(1500000000000000000);
  static double rewardAmountMax = 150;

  @override
  _AcaCrowdLoanPageState createState() => _AcaCrowdLoanPageState();
}

class _AcaCrowdLoanPageState extends State<AcaCrowdLoanPage> {
  int _tab = 0;
  int _bestNumber = 0;
  Map _fundInfo;

  KeyPairData _account = KeyPairData();

  bool _submitting = false;

  bool _accepted = false;

  Map _statement;
  Map _promotion;
  bool _signed = false;

  List _contributions = [];
  Timer _txQueryTimer;
  bool _txQuerying = true;

  Future<void> _updateBestNumber() async {
    final res = await widget.service.plugin.sdk.webView
        .evalJavascript('api.derive.chain.bestNumber()');
    final blockNumber = int.parse(res.toString());
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final promotion =
        await WalletApi.getKarCrowdLoanPromotion(endpoint, blockNumber);
    if (mounted) {
      setState(() {
        _bestNumber = blockNumber;
        _promotion = promotion;
      });
    }
  }

  List _mergeLocalTxData(List txs) {
    final pubKey = widget.service.keyring.current.pubKey;
    final Map cache =
        widget.service.store.storage.read('$local_tx_store_key:$pubKey') ?? {};
    final local = cache[pubKey] ?? [];
    if (local.length == 0) return txs;

    bool isInBlock = false;
    int inBlockTxCount = 0;
    int inBlockTxIndex = 0;
    local.forEach((e) {
      if (e['module'] == 'crowdloan' && e['call'] == 'contribute') {
        txs.forEach((tx) {
          if (tx['blockHash'] == e['blockHash']) {
            isInBlock = true;
            inBlockTxIndex = inBlockTxCount;
          }
        });
      }
      inBlockTxCount++;
    });
    if (isInBlock) {
      local.removeAt(inBlockTxIndex);
      cache[pubKey] = local;
      widget.service.store.storage.write('$local_tx_store_key:$pubKey', cache);
      if (_txQueryTimer != null) {
        _txQueryTimer.cancel();
      }
      return txs;
    } else {
      final tx = local[inBlockTxIndex];
      final List res = [
        {
          'contributionAmount': tx['args'][1],
          'timestamp': tx['timestamp'],
          'eventId': tx['hash'],
        }
      ];
      res.addAll(txs);
      setState(() {
        _txQueryTimer = Timer(Duration(seconds: 12), _getCrowdLoanHistory);
      });
      return res;
    }
  }

  Future<void> _getCrowdLoanInfo() async {
    await _getKarStatement();
    _getCrowdLoanHistory();

    if (widget.connectedNode == null) return;

    _updateBestNumber();
    final res = await widget.service.plugin.sdk.webView.evalJavascript(
        'api.query.crowdloan.funds("${_statement['paraId'].toString()}")');
    if (mounted) {
      setState(() {
        _fundInfo = res;
      });
    }
  }

  Future<void> _getCrowdLoanHistory() async {
    if (mounted) {
      setState(() {
        _txQuerying = true;
      });
    }
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final res =
        await WalletApi.getKarCrowdLoanHistory(_account.address, endpoint);
    if (res != null && mounted) {
      final txs = _mergeLocalTxData(res.reversed.toList());
      setState(() {
        _contributions = txs;
        _txQuerying = false;
      });
    }

    // we can get users' statement signature if we got the history
    // for aca, there's no signature info in history API data.
    // if (!_signed && res.length > 0) {
    //   final singedIndex = res.indexWhere((e) => e['type'] == 'CONTRIBUTION');
    //   if (singedIndex < 0) return;
    //
    //   final signed = res[singedIndex]['statement']['signature'];
    //   widget.service.store.storage
    //       .write('$aca_statement_store_key${_account.pubKey}', signed);
    //   if (mounted) {
    //     setState(() {
    //       _signed = true;
    //     });
    //   }
    // }
  }

  Future<void> _getKarStatement() async {
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final res = await WalletApi.getKarCrowdLoanStatement(endpoint);
    if (res != null && mounted) {
      setState(() {
        _statement = res;
      });
    }
  }

  Future<void> _selectAccount() async {
    final res = await Navigator.of(context).pushNamed(AccountListPage.route,
        arguments: AccountListPageParams(
            list: widget.service.keyring.keyPairs, title: 'Accounts'));
    if (res != null) {
      final acc = res as KeyPairData;
      if (acc.pubKey == _account.pubKey) return;

      // change account in app so we can get the balance
      widget.service.keyring.setCurrent(acc);
      widget.service.plugin.changeAccount(acc);
      widget.service.store.assets
          .loadCache(acc, widget.service.plugin.basic.name);

      final signed = widget.service.store.storage
          .read('$aca_statement_store_key${acc.pubKey}');

      setState(() {
        _account = acc;
        _accepted = false;
        _signed = signed != null;
      });

      _getCrowdLoanHistory();
    }
  }

  Future<void> _acceptAndSign() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });

    final password =
        await widget.service.account.getPassword(context, _account);

    if (password != null) {
      final params = SignAsExtensionParam();
      params.msgType = "pub(bytes.sign)";
      params.request = {
        "address": _account.address,
        "data": _statement['statement'],
      };

      final signRes = await widget.service.plugin.sdk.api.keyring
          .signAsExtension(password, params);
      widget.service.store.storage.write(
          '$aca_statement_store_key${_account.pubKey}', signRes.signature);

      setState(() {
        _submitting = false;
        _signed = true;
      });

      await _goToContribute();
    } else {
      setState(() {
        _submitting = false;
      });
    }
  }

  Future<void> _goToContribute() async {
    final res = await Navigator.of(context).pushNamed(
        AcaCrowdLoanFormPage.route,
        arguments: AcaCrowdLoanPageParams(
            _account,
            _statement,
            _tab == 0 ? AcaPloType.proxy : AcaPloType.direct,
            _promotion,
            _fundInfo));
    if (res != null) {
      _getCrowdLoanInfo();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = widget.service.keyring.current;
      final signed = widget.service.buildTarget == BuildTargets.dev
          ? null
          : widget.service.store.storage
              .read('$aca_statement_store_key${acc.pubKey}');

      setState(() {
        _account = widget.service.keyring.current;
        _signed = signed != null;
      });

      _getCrowdLoanInfo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.connectedNode != null && _fundInfo == null) {
      _getCrowdLoanInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    final titleColor = Colors.black87;
    final grayColor = Colors.black38;
    final labelStyle = TextStyle(
        color: Color(0xff2b2b2b),
        fontSize: 46.sp,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none);

    final raised = _fundInfo != null
        ? BigInt.parse(_fundInfo['raised'].toString())
        : BigInt.zero;
    final double ratioAcaMax = raised > AcaCrowdLoanPage.contributeAmountMax
        ? raised / AcaCrowdLoanPage.contributeAmountMaxDivider
        : AcaCrowdLoanPage.rewardAmountMax;

    final contributions = _contributions.toList();
    if (_tab == 0) {
      contributions.removeWhere((e) => e['type'] == 'CONTRIBUTION');
    } else {
      contributions.removeWhere((e) => e['type'] == 'TRANSFER');
    }
    return Scaffold(
      body: AcaPloPageLayout(
          '',
          Column(
            children: [
              Container(
                width: double.infinity,
                child: Image.asset("assets/images/public/aca_plo_bg.png"),
              ),
              _PLOTabs(
                _tab,
                onChange: (v) {
                  if (v != _tab) {
                    setState(() {
                      _tab = v;
                    });
                  }
                },
              ),
              _fundInfo == null || _bestNumber == 0
                  ? CupertinoActivityIndicator()
                  : Container(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dic['auction.address'],
                            style: labelStyle,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20.h, bottom: 48.h),
                            child: AddressFormItem(
                              widget.service.keyring.current,
                              svg: widget.service.keyring.current.icon,
                              onTap: _selectAccount,
                              color: acaThemeColor,
                              borderWidth: 4.w,
                              imageRight: 48.w,
                              margin: EdgeInsets.zero,
                            ),
                          ),
                          (_tab == 1 && !_signed) ||
                                  (_tab == 0 && contributions.length == 0)
                              ? Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Theme(
                                          child: SizedBox(
                                            height: 48,
                                            width: 32,
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8),
                                              child: Checkbox(
                                                value: _accepted,
                                                onChanged: (v) {
                                                  setState(() {
                                                    _accepted = v;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          data: ThemeData(
                                            primarySwatch: acaThemeColor,
                                            unselectedWidgetColor:
                                                acaThemeColor, // Your color
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dic['auction.read'],
                                              style:
                                                  TextStyle(color: titleColor),
                                            ),
                                            Row(
                                              children: [
                                                JumpToLink(
                                                  'https://acala.network/terms',
                                                  text:
                                                      '${dic['auction.term.0']}',
                                                  color: acaThemeColor,
                                                ),
                                                Text(
                                                  ' & ',
                                                  style: TextStyle(
                                                      color: titleColor),
                                                ),
                                                JumpToLink(
                                                  'https://acala.network/privacy',
                                                  text:
                                                      ' ${dic['auction.term.2']}',
                                                  color: acaThemeColor,
                                                )
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                )
                              : _txQuerying
                                  ? CupertinoActivityIndicator()
                                  : contributions.length > 0
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Text(dic['auction.txs'],
                                                  style: labelStyle),
                                            ),
                                            Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  16, 8, 16, 8),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8)),
                                                border: Border.all(
                                                    width: 4.w,
                                                    color: acaThemeColor),
                                              ),
                                              child: Column(
                                                children:
                                                    contributions.map((e) {
                                                  final karAmountStyle =
                                                      TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 12);
                                                  final contributeAmount =
                                                      Fmt.balance(
                                                          e['contributionAmount'],
                                                          decimals);
                                                  List<Widget> acaAmount = [
                                                    Text(
                                                      dic['auction.tx.confirming'],
                                                      style: karAmountStyle,
                                                    )
                                                  ];
                                                  if (e['blockHash'] != null) {
                                                    final acaAmountInt =
                                                        Fmt.balanceInt(
                                                            e['baseBonus']);
                                                    final refereeBonus =
                                                        Fmt.balanceInt(
                                                            e['refereeBonus']);
                                                    final karContributionBonus =
                                                        Fmt.balanceInt(e[
                                                            'karuraContributorBonus']);
                                                    final acaExtraBonus = e[
                                                                'promotion'] !=
                                                            null
                                                        ? Fmt.balanceInt(e[
                                                                'promotion']
                                                            ['acaExtraBonus'])
                                                        : BigInt.zero;
                                                    final karAmountMin =
                                                        Fmt.bigIntToDouble(
                                                            acaAmountInt +
                                                                refereeBonus +
                                                                karContributionBonus +
                                                                acaExtraBonus,
                                                            aca_token_decimal);
                                                    final karAmountMax =
                                                        karAmountMin *
                                                            ratioAcaMax /
                                                            3;
                                                    acaAmount = [
                                                      Text(
                                                        '≈ ${Fmt.priceFloor(karAmountMin)} - ${Fmt.priceFloor(karAmountMax)} ACA',
                                                        style: karAmountStyle,
                                                      )
                                                    ];
                                                  }
                                                  return Container(
                                                    margin: EdgeInsets.only(
                                                        top: 8, bottom: 8),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '$contributeAmount DOT',
                                                                  style: TextStyle(
                                                                      color:
                                                                          titleColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                _tab == 0
                                                                    ? Text(
                                                                        '(= $contributeAmount lcDOT)',
                                                                        style:
                                                                            karAmountStyle)
                                                                    : Container()
                                                              ],
                                                            ),
                                                            Text(
                                                                Fmt.dateTime(DateTime
                                                                    .fromMillisecondsSinceEpoch(e[
                                                                        'timestamp'])),
                                                                style: TextStyle(
                                                                    color:
                                                                        grayColor,
                                                                    fontSize:
                                                                        13))
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            ...acaAmount,
                                                            JumpToLink(
                                                              e['blockHash'] ==
                                                                      null
                                                                  ? 'https://kusama.subscan.io/extrinsic/${e['eventId']}'
                                                                  : 'https://kusama.subscan.io/account/${_account.address}',
                                                              text: 'Subscan',
                                                              color:
                                                                  acaThemeColor,
                                                            )
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          ],
                                        )
                                      : Container(),
                          Container(
                            margin: EdgeInsets.only(top: 16, bottom: 32),
                            child: _signed || _tab == 0
                                ? RoundedButton(
                                    text: dic['auction.contribute'],
                                    color: acaThemeColor,
                                    borderRadius: 8,
                                    onPressed: _accepted
                                        ? _goToContribute
                                        : () => null,
                                  )
                                : RoundedButton(
                                    icon: _submitting
                                        ? CupertinoActivityIndicator()
                                        : null,
                                    text: dic['auction.accept'],
                                    color: acaThemeColor,
                                    borderRadius: 8,
                                    onPressed: _accepted && !_submitting
                                        ? _acceptAndSign
                                        : () => null,
                                  ),
                          )
                        ],
                      ),
                    )
            ],
          )),
    );
  }
}

class _PLOTabs extends StatelessWidget {
  _PLOTabs(this.activeTab, {this.onChange});
  final int activeTab;
  final Function(int) onChange;

  void _showProxyInfo(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(dic['auction.proxy.title']),
        content: _InfoPanelsInDialog(
          closeDialog: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return Container(
      margin: EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border.all(color: acaThemeColor),
                borderRadius: const BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    bottomLeft: const Radius.circular(8)),
                color: activeTab == 0
                    ? acaThemeColor
                    : Theme.of(context).cardColor,
              ),
              child: Text(
                dic['auction.proxy'],
                style: TextStyle(
                    color: activeTab == 0
                        ? Theme.of(context).cardColor
                        : acaThemeColor),
              ),
            ),
            onTap: () => onChange(0),
          ),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border.all(color: acaThemeColor),
                borderRadius: const BorderRadius.only(
                    topRight: const Radius.circular(8),
                    bottomRight: const Radius.circular(8)),
                color: activeTab == 1
                    ? acaThemeColor
                    : Theme.of(context).cardColor,
              ),
              child: Text(
                dic['auction.direct'],
                style: TextStyle(
                    color: activeTab == 1
                        ? Theme.of(context).cardColor
                        : acaThemeColor),
              ),
            ),
            onTap: () => onChange(1),
          ),
          Container(
            margin: EdgeInsets.only(left: 8),
            child: GestureDetector(
              child: Container(
                child: Text('?', style: TextStyle(color: acaThemeColor)),
                padding: EdgeInsets.fromLTRB(5, 6, 4, 4),
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 1, color: acaThemeColor),
                ),
              ),
              onTap: () => _showProxyInfo(context),
            ),
          )
        ],
      ),
    );
  }
}

class _InfoPanelsInDialog extends StatefulWidget {
  _InfoPanelsInDialog({this.closeDialog});
  final Function closeDialog;
  @override
  _InfoPanelsInDialogState createState() => _InfoPanelsInDialogState();
}

class _InfoPanelsInDialogState extends State<_InfoPanelsInDialog> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final dic2 = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 8, bottom: 8),
          child: Image.asset("assets/images/public/plo_proxy_$_page.png",
              height: 80),
        ),
        Container(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [Text(dic['auction.proxy.${_page + 1}'])],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              child: Text(
                dic2['cancel'],
                style: TextStyle(
                  color: acaThemeColor,
                ),
              ),
              onTap: widget.closeDialog,
            ),
            GestureDetector(
              child: Text(
                dic2['next'],
                style: TextStyle(color: acaThemeColor),
              ),
              onTap: () {
                setState(() {
                  if (_page == 2) {
                    _page = 0;
                  } else {
                    _page += 1;
                  }
                });
              },
            )
          ],
        )
      ],
    );
  }
}

class AcaPloPageLayout extends StatelessWidget {
  AcaPloPageLayout(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.black87;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: child,
          ),
          Container(
            height: 56,
            margin: EdgeInsets.only(top: 32, left: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: titleColor),
                    onPressed: () => Navigator.of(context).pop()),
                Text(
                  title,
                  style: TextStyle(color: titleColor, fontSize: 24),
                ),
                Container(width: 48)
              ],
            ),
          )
        ],
      ),
    );
  }
}
