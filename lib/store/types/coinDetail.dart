import 'package:json_annotation/json_annotation.dart';

part 'coinDetail.g.dart';

@JsonSerializable()
class CoinDetail extends _CoinDetail {
  static CoinDetail fromJson(Map<String, dynamic> json) =>
      _$CoinDetailFromJson(json);
  static Map<String, dynamic> toJson(CoinDetail data) =>
      _$CoinDetailToJson(data);
}

abstract class _CoinDetail {
  String coinCode = "";
  String displayCode = "";
  String tokenLogo = "";
  int unitDecimal;
  int pricePrecision;
  String pCoinCode = "";
  int sortNum;
  String contractAddress = "";
  String balance = "";
  String coinName = "";
  bool isAdd;
  bool isFirst;
  bool isSubLast;
  int level;
  int reputation;
  String price = "";
  String tokenId = "";
  String denom = "";
  String symbol = "";
  bool isFixed;
  String identifier = "";
  int isOpen;
  String chainName = "";
  bool customrpc = false;
  int chainId = -1;
  String rpcHost = "";
  String blacklistInfo = "";
  String mnemonic = "";
  String password = "";
  String name = "";
  bool isSelect = false;
  String address = "";
  String addressIndex = "";
  String signature = "";
  String polkaInfo = "";
  int position = 99;
  String currency = "CNY";
  String language = "zh";
}
