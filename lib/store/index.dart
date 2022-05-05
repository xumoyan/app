import 'package:polka_module/store/account.dart';
import 'package:polka_module/store/assets.dart';
import 'package:polka_module/store/parachain.dart';
import 'package:polka_module/store/settings.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';

class AppStore {
  AppStore(this.storage);

  final GetStorage storage;

  AccountStore account;
  SettingsStore settings;
  AssetsStore assets;
  ParachainStore parachain;

  @action
  Future<void> init() async {
    settings = SettingsStore(storage);
    await settings.init();
    account = AccountStore(storage);
    assets = AssetsStore(storage);
    parachain = ParachainStore(storage);
  }
}
