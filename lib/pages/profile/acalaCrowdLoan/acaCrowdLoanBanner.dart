import 'package:polka_module/common/consts.dart';
import 'package:polka_module/pages/profile/acalaCrowdLoan/acaCrowdLoanPage.dart';
import 'package:polka_module/pages/profile/crowdLoan/crowdLoanPage.dart';
import 'package:polka_module/service/index.dart';
import 'package:polka_module/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class ACACrowdLoanBanner extends StatelessWidget {
  ACACrowdLoanBanner(this.service, this.switchNetwork);
  final AppService service;
  final Future<void> Function(String) switchNetwork;

  Future<void> _goToCrowdLoan(BuildContext context, bool active) async {
    if (service.plugin.basic.name != relay_chain_name_dot) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('${dic['auction.switch']} $relay_chain_name_dot ...'),
            content: Container(height: 64, child: CupertinoActivityIndicator()),
          );
        },
      );
      await switchNetwork(relay_chain_name_dot);
      Navigator.of(context).pop();
    }

    Navigator.of(context)
        .pushNamed(active ? AcaCrowdLoanPage.route : CrowdLoanPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final active = service.buildTarget == BuildTargets.dev;
      // todo: activate the banner
      // final active = service.buildTarget == BuildTargets.dev
      //     ? true
      //     : (service.store.settings.adBannerState['startedAca'] ?? false);
      return Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          GestureDetector(
            child: Container(
              margin: EdgeInsets.all(8),
              child: Image.asset('assets/images/public/banner_aca_plo.png'),
            ),
            onTap: () => _goToCrowdLoan(context, active),
          ),
        ],
      );
    });
  }
}
