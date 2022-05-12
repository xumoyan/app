import 'package:json_annotation/json_annotation.dart';

part 'polkaChannel.g.dart';

@JsonSerializable()
class PolkaChannel extends _PolkaChannel {
  static PolkaChannel fromJson(Map<String, dynamic> json) =>
      _$PolkaChannelFromJson(json);
  static Map<String, dynamic> toJson(PolkaChannel data) =>
      _$PolkaChannelToJson(data);
}

abstract class _PolkaChannel {
  String action = "";
  bool passwordResult = false;
}
