import 'package:polka_module/common/components/assetTabbar.dart';
import 'package:polka_module/common/consts.dart';
import 'package:polka_module/pages/assets/asset/locksDetailPage.dart';
import 'package:polka_module/pages/assets/asset/rewardsChart.dart';
import 'package:polka_module/pages/assets/transfer/detailPage.dart';
import 'package:polka_module/pages/assets/transfer/transferPage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/store/types/transferData.dart';
import 'package:polka_module/utils/ShowCustomAlterWidget.dart';
import 'package:polka_module/utils/Utils.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/cardButton.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/mainTabBar.dart';

class AssetPage extends StatefulWidget {
  AssetPage(this.service);
  final AppService service;

  static final String route = '/assets/detail';

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  bool _loading = false;

  int _tab = 0;
  String history = 'all';
  int _txsPage = 0;
  bool _isLastPage = false;
  ScrollController _scrollController;

  List<dynamic> _marketPriceList;

  double _rate = 1.0;

  Future<void> _updateData() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    widget.service.plugin.updateBalances(widget.service.keyring.current);

    final res = await widget.service.assets.updateTxs(_txsPage);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _txsPage += 1;
    });

    if (res['transfers'] == null ||
        res['transfers'].length < tx_list_page_size) {
      setState(() {
        _isLastPage = true;
      });
    }
  }

  Future<void> _refreshData() async {
    if (widget.service.plugin.sdk.api.connectedNode == null) return;

    setState(() {
      _txsPage = 0;
      _isLastPage = false;
    });

    widget.service.assets.fetchMarketPrices();

    await _updateData();
  }

  void _showAction() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(I18n.of(context)
                    .getDic(i18n_full_dic_app, 'assets')['address.subscan']),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              ],
            ),
            onPressed: () {
              String networkName = widget.service.plugin.basic.name;
              if (widget.service.plugin.basic.isTestNet) {
                networkName = '${networkName.split('-')[0]}-testnet';
              }
              final snLink =
                  'https://$networkName.subscan.io/account/${widget.service.keyring.current.address}';
              UI.launchURL(snLink);
              Navigator.of(context).pop();
            },
          ),
        ],
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

  @override
  void initState() {
    super.initState();

    WalletApi.getMarketPriceList(
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0], 7)
        .then((value) {
      if (mounted) {
        setState(() {
          if (value['data'] != null) {
            _marketPriceList = value['data']['price'] as List;
          }
        });
      }
    });

    if (widget.service.plugin.basic.name == para_chain_name_acala ||
        widget.service.plugin.basic.name == para_chain_name_karura) return;

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (_tab == 0 && !_isLastPage) {
          _updateData();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      getRate();
    });
  }

  Future<void> getRate() async {
    var rate = await widget.service.store.settings.getRate();
    setState(() {
      this._rate = rate;
    });
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  List<Widget> _buildTxList() {
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final txs = widget.service.store.assets.txs.toList();
    txs.retainWhere((e) {
      switch (_tab) {
        case 2:
          return e.to == widget.service.keyring.current.address;
        case 1:
          return e.from == widget.service.keyring.current.address;
        default:
          return true;
      }
    });
    final List<Widget> res = [];
    res.addAll(txs.map((i) {
      return Column(
        children: [
          Container(
              margin: EdgeInsets.only(bottom: 12.h),
              height: 70.h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(const Radius.circular(8)),
                color: Color.fromARGB(0xFF, 0xF6, 0xF9, 0xFD),
              ),
              child: TransferListItem(
                data: i,
                token: symbol,
                isOut: i.from == widget.service.keyring.current.address,
                crossChain:
                    i.to == bridge_account['acala'] ? 'Acala Bridge' : null,
                hasDetail: true,
              ))
        ],
      );
    }));

    res.add(ListTail(
      isEmpty: txs.length == 0,
      isLoading: _loading,
    ));

    return res;
  }

  List<TimeSeriesAmount> getTimeSeriesAmounts(List<dynamic> marketPriceList) {
    List<TimeSeriesAmount> datas = [];
    for (int i = 0; i < marketPriceList.length; i++) {
      datas.add(TimeSeriesAmount(
          DateTime.now().add(Duration(days: -1 * i)), i * 1.0));
    }
    return datas;
  }

  List<Color> getBgColors() {
    switch (widget.service.plugin.basic.name) {
      case relay_chain_name_ksm:
      case para_chain_name_statemine:
        return [Color(0xFF767575), Color(0xFF2A2A2B)];
      case para_chain_name_karura:
        return [Color(0xFF2B292A), Color(0xFFCD4337)];
      case para_chain_name_acala:
        return [Color(0xFFFD4732), Color(0xFF645AFF)];
      case para_chain_name_bifrost:
        return [
          Color(0xFF5AAFE1),
          Color(0xFF596ED2),
          Color(0xFFB358BD),
          Color(0xFFFFAE5E)
        ];
      case relay_chain_name_dot:
        return [Color(0xFFDD1878), Color(0xFF72AEFF)];
      case chain_name_edgeware:
        return [Color(0xFF21C1D5), Color(0xFF057AA9)];
      case chain_name_dbc:
        return [Color(0xFF5BC1D3), Color(0xFF374BD4)];
      default:
        return [Theme.of(context).primaryColor, Theme.of(context).hoverColor];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          symbol,
          style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackBtn(),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Observer(
        builder: (_) {
          BalanceData balancesInfo = widget.service.plugin.balances.native;
          final txs = widget.service.plugin.getNativeTokenTransfers(
              address: widget.service.keyring.current.address,
              transferType: _tab);
          return Column(
            children: <Widget>[
              BalanceCard(
                balancesInfo,
                symbol: symbol,
                decimals: decimals,
                marketPrices:
                    (widget.service.store.assets.marketPrices[symbol] ?? 0) *
                        (widget.service.store.settings.priceCurrency == "CNY"
                            ? _rate
                            : 1.0),
                // backgroundImage: widget.service.plugin.basic.backgroundImage,
                bgColors: getBgColors(),
                icon: widget.service.plugin.tokenIcons[symbol],
                marketPriceList: _marketPriceList,
                priceCurrency: widget.service.store.settings.priceCurrency,
              ),
              Container(
                height: 64.h,
                child: RoundedCard(
                    margin: EdgeInsets.only(left: 13.w, right: 13.w, top: 15.h),
                    padding: EdgeInsets.only(left: 8.w, right: 8.w),
                    radius: const BorderRadius.only(
                        topLeft: const Radius.circular(8),
                        topRight: const Radius.circular(8)),
                    boxShadow: BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 1.0,
                      spreadRadius: 0.0,
                      offset: Offset(
                        1.0,
                        -1,
                      ),
                    ),
                    child: AssetTabbar(
                      tabs: {
                        dic['tab.all']: false,
                        dic['tab.out']: false,
                        dic['tab.in']: false
                      },
                      activeTab: _tab,
                      onTap: (i) {
                        setState(() {
                          _tab = i;
                        });
                      },
                    )),
              ),
              Expanded(
                  child: Container(
                transform: Matrix4.translationValues(0, -2, 0),
                child: RoundedCard(
                  margin: EdgeInsets.only(left: 13.w, right: 13.w),
                  padding: EdgeInsets.only(left: 8.w, right: 8.w),
                  radius: const BorderRadius.only(
                      bottomLeft: const Radius.circular(8),
                      bottomRight: const Radius.circular(8)),
                  boxShadow: BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 1.0,
                    spreadRadius: 0.0,
                    offset: Offset(
                      1,
                      2,
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.only(left: 4.w, right: 4.w),
                    color: Theme.of(context).cardColor,
                    child: txs == null
                        ? RefreshIndicator(
                            key: _refreshKey,
                            onRefresh: _refreshData,
                            child: ListView(
                              physics: BouncingScrollPhysics(),
                              controller: _scrollController,
                              children: [..._buildTxList()],
                            ),
                          )
                        : txs,
                  ),
                ),
              )),
              Container(
                  margin: EdgeInsets.only(top: 15.h),
                  height: 80.h,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          if (widget.service.plugin.basic.name ==
                              para_chain_name_karura) {
                            final symbol = (widget
                                    .service.plugin.networkState.tokenSymbol ??
                                [''])[0];
                            Navigator.of(context).pushNamed(
                                '/assets/token/transfer',
                                arguments: {
                                  'params': {'tokenNameId': symbol}
                                });
                            return;
                          }
                          Navigator.pushNamed(context, TransferPage.route);
                        },
                        child: Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: new AssetImage(
                                    'assets/images/icon_details_bigbutton.png'),
                                fit: BoxFit.fill),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dic['transfer'],
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      )),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AccountQrCodePage.route);
                        },
                        child: Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: new AssetImage(
                                    'assets/images/icon_wireframe_bigbutton.png'),
                                fit: BoxFit.fill),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dic['receive'],
                                style: TextStyle(
                                    color:
                                        Color.fromARGB(0xFF, 0x39, 0x41, 0x60),
                                    fontSize: 14),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      ))
                    ],
                  )),
            ],
          );
        },
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  BalanceCard(this.balancesInfo,
      {this.marketPrices,
      this.symbol,
      this.decimals,
      // this.backgroundImage,
      this.bgColors,
      this.icon,
      this.marketPriceList,
      this.priceCurrency});

  final String symbol;
  final int decimals;
  final BalanceData balancesInfo;
  final double marketPrices;
  // final ImageProvider backgroundImage;
  final List<Color> bgColors;
  final Widget icon;
  final List<dynamic> marketPriceList;
  final String priceCurrency;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final balance = Fmt.balanceTotal(balancesInfo);

    String tokenPrice;
    if (marketPrices != null && balancesInfo != null) {
      tokenPrice =
          Fmt.priceFloor(marketPrices * Fmt.bigIntToDouble(balance, decimals));
    }
    final titleColor = Color.fromARGB(0xFF, 0x33, 0x33, 0x33);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 0),
          padding: EdgeInsets.all(9.w),
          decoration: BoxDecoration(
            image: DecorationImage(
                image: new AssetImage('assets/images/icon_details_button.png'),
                fit: BoxFit.fill),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                      height: 25.w,
                      width: 25.w,
                      margin: EdgeInsets.only(left: 21.w, top: 16.h),
                      child: icon),
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 10.w, top: 16.h),
                        height: 17.h,
                        child: Text(
                          symbol,
                          style: TextStyle(color: Colors.white, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 21.w, top: 5.h, bottom: 16.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          Fmt.token(balance, decimals, length: 8),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              letterSpacing: -0.8),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 10.w),
                          child: Visibility(
                            visible: tokenPrice != null,
                            child: Text(
                              '≈ ${Utils.currencySymbol(priceCurrency)} ${tokenPrice ?? '--.--'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  .copyWith(
                                      color: Colors.white,
                                      letterSpacing: -0.8,
                                      fontSize: 11),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        Container(
            child: RoundedCard(
          margin: EdgeInsets.only(left: 13.w, right: 13.w, top: 4.h),
          child: Column(
            children: [
              priceItemBuild(
                  dic['available'],
                  Fmt.priceFloorBigInt(
                    Fmt.balanceInt(
                        (balancesInfo?.availableBalance ?? 0).toString()),
                    decimals,
                    lengthMax: 4,
                  ),
                  titleColor),
              priceItemBuild(
                  dic['locked'],
                  Fmt.priceFloorBigInt(
                    Fmt.balanceInt(
                        (balancesInfo?.lockedBalance ?? 0).toString()),
                    decimals,
                    lengthMax: 4,
                  ),
                  titleColor),
              priceItemBuild(
                  dic['reserved'],
                  Fmt.priceFloorBigInt(
                    Fmt.balanceInt(
                        (balancesInfo?.reservedBalance ?? 0).toString()),
                    decimals,
                    lengthMax: 4,
                  ),
                  titleColor),
            ],
          ),
        ))
      ],
    );
  }

  List<TimeSeriesAmount> getTimeSeriesAmounts(List<dynamic> marketPriceList) {
    List<TimeSeriesAmount> datas = [];
    for (int i = 0; i < marketPriceList.length; i++) {
      datas.add(TimeSeriesAmount(DateTime.now().add(Duration(days: -1 * i)),
          marketPriceList[i] * 1.0));
    }
    return datas;
  }

  Widget priceItemBuild(String title, String price, Color color) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: Container(
            padding: EdgeInsets.only(left: 21.w, right: 21.w),
            height: 32.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Color.fromARGB(0xFF, 0x66, 0x66, 0x66),
                      fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    price,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color: Color.fromARGB(0xFF, 0x33, 0x33, 0x33),
                        fontSize: 16),
                  ),
                )
              ],
            )));
  }
}

class TransferListItem extends StatelessWidget {
  TransferListItem({
    this.data,
    this.token,
    this.isOut,
    this.hasDetail,
    this.crossChain,
  });

  final TransferData data;
  final String token;
  final String crossChain;
  final bool isOut;
  final bool hasDetail;

  @override
  Widget build(BuildContext context) {
    final address = isOut ? data.to : data.from;
    final title =
        Fmt.address(address) ?? data.extrinsicIndex ?? Fmt.address(data.hash);
    final colorFailed = Theme.of(context).unselectedWidgetColor;
    final amount = Fmt.priceFloor(double.parse(data.amount), lengthFixed: 4);
    return GestureDetector(
      child: Container(
          margin: EdgeInsets.only(left: 12, right: 12),
          child: Row(
            children: [
              data.success
                  ? isOut
                      ? TransferIcon(type: TransferIconType.rollOut)
                      : TransferIcon(type: TransferIconType.rollIn)
                  : TransferIcon(type: TransferIconType.failure),
              Expanded(
                  child: Container(
                      margin: EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                            margin: EdgeInsets.only(top: 10, right: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$title${crossChain != null ? ' ($crossChain)' : ''}',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Color.fromARGB(
                                              0xFF, 0x33, 0x33, 0x33),
                                          fontSize: 12),
                                    ),
                                    Container(
                                        margin: EdgeInsets.only(left: 5),
                                        child: GestureDetector(
                                          child: Image.asset(
                                            "assets/images/icon_adress_magnifier_b.png",
                                            width: 14,
                                            height: 14,
                                          ),
                                          onTap: () {
                                            showCupertinoModalPopup(
                                                context: context,
                                                builder: (context) {
                                                  return ShowCustomAlterWidget(
                                                    confirmCallback: (value) {},
                                                    cancel: '取消',
                                                    options: ["1"],
                                                  );
                                                });
                                          },
                                        ))
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 5, top: 3),
                                  child: Text(
                                      Fmt.getRelativeDate(
                                          data.blockTimestamp * 1000,
                                          locale: I18n.of(context)
                                              .locale
                                              .languageCode),
                                      style: TextStyle(
                                          color: Color.fromARGB(
                                              0xFF, 0x99, 0x99, 0x99),
                                          fontSize: 11)),
                                )
                              ],
                            ),
                          )),
                          Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                child: Text(
                                  '${isOut ? '-' : '+'} $amount $token',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isOut
                                          ? Color(0xff00BE75)
                                          : Color(0xff5680E0)),
                                  textAlign: TextAlign.right,
                                ),
                              )
                            ],
                          ),
                        ],
                      )))
            ],
          )),
      onTap: hasDetail
          ? () {
              Navigator.pushNamed(
                context,
                TransferDetailPage.route,
                arguments: data,
              );
            }
          : null,
    );
  }
}
