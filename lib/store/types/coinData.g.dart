// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coinData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoinData _$CoinDataFromJson(Map<String, dynamic> json) {
  return CoinData()
    ..selectCoin = json['selectCoin'] as String
    ..mnemonic = json['mnemonic'] as String
    ..position = json['position'] as int
    ..name = json['name'] as String
    ..currency = json['currency'] as String
    ..language = json['language'] as String
    ..coinDetails = const _CoinDetailConverter()
        .fromJson(json['coinDetails'] as List<dynamic>);
}

Map<String, dynamic> _$CoinDataToJson(CoinData instance) => <String, dynamic>{
      'selectCoin': instance.selectCoin,
      'mnemonic': instance.mnemonic,
      'position': instance.position,
      'name': instance.name,
      'currency': instance.currency,
      'language': instance.language,
      'coinDetails': const _CoinDetailConverter().toJson(instance.coinDetails),
    };
