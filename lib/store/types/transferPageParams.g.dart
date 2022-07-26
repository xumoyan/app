// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transferPageParams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferPageParams _$TransferPageParamsFromJson(Map<String, dynamic> json) {
  return TransferPageParams()
    ..address = json['address'] as String
    ..chainTo = json['chainTo'] as String
    ..rate = json['rate'] as int
    ..currency = json['currency'] as String;
}

Map<String, dynamic> _$TransferPageParamsToJson(TransferPageParams instance) =>
    <String, dynamic>{
      'address': instance.address,
      'chainTo': instance.chainTo,
      'rate': instance.rate,
      'currency': instance.currency,
    };
