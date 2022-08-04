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
  int unitDecimal = 0;
  int pricePrecision = 0;
  String pCoinCode = "";
  int sortNum = 0;
  String contractAddress = "";
  String balance = "";
  String coinName = "";
  bool isAdd = false;
  bool isFirst = false;
  bool isSubLast = false;
  int level = 0;
  int reputation = 0;
  String price = "";
  String tokenId = "";
  String denom = "";
  String symbol = "";
  bool isFixed = false;
  String identifier = "";
  int isOpen = 0;
  String chainName = "";
  bool customrpc = false;
  int chainId = -1;
  String rpcHost = "";
  String blacklistInfo = "";
  String address = "";
  String addressIndex = "";
  String signature = "";
  String polkaInfo = "";
  int position = 99;
  bool isPressed = false;
}
