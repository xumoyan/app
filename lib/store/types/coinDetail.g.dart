// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coinDetail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoinDetail _$CoinDetailFromJson(Map<String, dynamic> json) {
  return CoinDetail()
    ..coinCode = json['coinCode'] as String
    ..displayCode = json['displayCode'] as String
    ..tokenLogo = json['tokenLogo'] as String
    ..unitDecimal = json['unitDecimal'] as int
    ..pricePrecision = json['pricePrecision'] as int
    ..pCoinCode = json['pCoinCode'] as String
    ..sortNum = json['sortNum'] as int
    ..contractAddress = json['contractAddress'] as String
    ..balance = json['balance'] as String
    ..coinName = json['coinName'] as String
    ..isAdd = json['isAdd'] as bool
    ..isFirst = json['isFirst'] as bool
    ..isSubLast = json['isSubLast'] as bool
    ..level = json['level'] as int
    ..reputation = json['reputation'] as int
    ..price = json['price'] as String
    ..tokenId = json['tokenId'] as String
    ..denom = json['denom'] as String
    ..symbol = json['symbol'] as String
    ..isFixed = json['isFixed'] as bool
    ..identifier = json['identifier'] as String
    ..isOpen = json['isOpen'] as int
    ..chainName = json['chainName'] as String
    ..customrpc = json['customrpc'] as bool
    ..chainId = json['chainId'] as int
    ..rpcHost = json['rpcHost'] as String
    ..blacklistInfo = json['blacklistInfo'] as String
    ..mnemonic = json['mnemonic'] as String
    ..password = json['password'] as String
    ..name = json['name'] as String
    ..isSelect = json['isSelect'] as bool
    ..address = json['address'] as String
    ..addressIndex = json['addressIndex'] as String
    ..signature = json['signature'] as String
    ..polkaInfo = json['polkaInfo'] as String
    ..position = json['position'] as int
    ..currency = json['currency'] as String
    ..language = json['language'] as String;
}

Map<String, dynamic> _$CoinDetailToJson(CoinDetail instance) =>
    <String, dynamic>{
      'coinCode': instance.coinCode,
      'displayCode': instance.displayCode,
      'tokenLogo': instance.tokenLogo,
      'unitDecimal': instance.unitDecimal,
      'pricePrecision': instance.pricePrecision,
      'pCoinCode': instance.pCoinCode,
      'sortNum': instance.sortNum,
      'contractAddress': instance.contractAddress,
      'balance': instance.balance,
      'coinName': instance.coinName,
      'isAdd': instance.isAdd,
      'isFirst': instance.isFirst,
      'isSubLast': instance.isSubLast,
      'level': instance.level,
      'reputation': instance.reputation,
      'price': instance.price,
      'tokenId': instance.tokenId,
      'denom': instance.denom,
      'symbol': instance.symbol,
      'isFixed': instance.isFixed,
      'identifier': instance.identifier,
      'isOpen': instance.isOpen,
      'chainName': instance.chainName,
      'customrpc': instance.customrpc,
      'chainId': instance.chainId,
      'rpcHost': instance.rpcHost,
      'blacklistInfo': instance.blacklistInfo,
      'mnemonic': instance.mnemonic,
      'password': instance.password,
      'name': instance.name,
      'isSelect': instance.isSelect,
      'address': instance.address,
      'addressIndex': instance.addressIndex,
      'signature': instance.signature,
      'polkaInfo': instance.polkaInfo,
      'position': instance.position,
      'currency': instance.currency,
      'language': instance.language,
    };
