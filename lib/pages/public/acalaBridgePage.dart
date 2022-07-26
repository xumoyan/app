import 'package:polka_module/common/consts.dart';
import 'package:polka_module/pages/assets/transfer/transferPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polka_module/store/types/transferPageParams.dart';

class AcalaBridgePage extends StatelessWidget {
  static const route = '/bridge/aca';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).popAndPushNamed(TransferPage.route, arguments: {
        "params":
            TransferPageParams.fromJson({"chainTo": para_chain_name_acala})
      });
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(width: 1, height: 1),
    );
  }
}
