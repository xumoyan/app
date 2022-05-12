// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polkaChannel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolkaChannel _$PolkaChannelFromJson(Map<String, dynamic> json) {
  return PolkaChannel()
    ..action = json['action'] as String
    ..passwordResult = json['passwordResult'] as bool;
}

Map<String, dynamic> _$PolkaChannelToJson(PolkaChannel instance) =>
    <String, dynamic>{
      'action': instance.action,
      'passwordResult': instance.passwordResult,
    };
