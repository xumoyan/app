import 'package:polka_module/common/consts.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/service/walletApi.dart';
import 'package:polka_module/utils/UI.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/jumpToBrowserLink.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AboutPage extends StatefulWidget {
  AboutPage(this.service);

  final AppService service;

  static final String route = '/profile/about';

  @override
  _AboutPage createState() => _AboutPage();
}

class _AboutPage extends State<AboutPage> {
  bool _loading = false;

  Future<void> _checkUpdate() async {
    setState(() {
      _loading = true;
    });
    final versions = await WalletApi.getLatestVersion();
    setState(() {
      _loading = false;
    });
    AppUI.checkUpdate(context, versions, widget.service.buildTarget);
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final currentJSVersion = WalletApi.getPolkadotJSVersion(
        widget.service.store.storage,
        widget.service.plugin.basic.name,
        widget.service.plugin.basic.jsCodeVersion);
    final githubLink = plugin_github_links[widget.service.plugin.basic.name];
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text(dic['about']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(48),
              width: MediaQuery.of(context).size.width / 2,
              child: Image.asset('assets/images/logo_about.png'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  dic['about.brif'],
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: JumpToBrowserLink('https://polkawallet.io'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 4),
                  child:
                      SvgPicture.asset('assets/images/public/github_logo.svg'),
                ),
                JumpToBrowserLink(
                  githubLink,
                  text: Fmt.address(githubLink, pad: 16),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('${dic['about.version']}: $app_beta_version'),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('API: $currentJSVersion'),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: RoundedButton(
                text: dic['update'],
                onPressed: () {
                  _checkUpdate();
                },
                submitting: _loading,
              ),
            )
          ],
        ),
      ),
    );
  }
}
