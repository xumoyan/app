import 'package:json_annotation/json_annotation.dart';
import 'package:polka_module/store/types/coinDetail.dart';

part 'coinData.g.dart';

@JsonSerializable()
class CoinData extends _CoinData {
  static CoinData fromJson(Map<String, dynamic> json) =>
      _$CoinDataFromJson(json);
  
  static Map<String, dynamic> toJson(CoinData data) => _$CoinDataToJson(data);
}

abstract class _CoinData {
  String selectCoin = "";
  String mnemonic = "";
  int position = 99;
  String name = "";
  String currency = "CNY";
  String language = "zh";
  @_CoinDetailConverter()
  List<CoinDetail> coinDetails = [];
}

class _CoinDetailConverter
    implements JsonConverter<List<CoinDetail>, List<dynamic>> {
  const _CoinDetailConverter();

  @override
  List<CoinDetail> fromJson(List<dynamic> list) {
    final List<CoinDetail> models = [];
    if (list.length > 0) {
      if (list is List) {
        for (final element in list) {
          models.add(CoinDetail.fromJson(element));
        }
      }
    }
    return models;
  }

  @override
  List<dynamic> toJson(List<CoinDetail> object) {
    throw UnimplementedError();
  }
}
