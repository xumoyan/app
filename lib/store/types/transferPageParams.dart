import 'package:json_annotation/json_annotation.dart';

part 'transferPageParams.g.dart';

@JsonSerializable()
class TransferPageParams extends _TransferPageParams {
  static TransferPageParams fromJson(Map<String, dynamic> json) =>
      _$TransferPageParamsFromJson(json);
  static Map<String, dynamic> toJson(TransferPageParams data) =>
      _$TransferPageParamsToJson(data);
}

abstract class _TransferPageParams {
  String address = "";
  String chainTo = "";
  int rate = 0;
  String currency = "";
}
