import 'package:flutter/material.dart';

class AssetTabbar extends StatelessWidget {
  AssetTabbar({this.tabs, this.activeTab, this.onTap});

  final Map<String, bool> tabs;
  final Function(int) onTap;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    tabs.forEach((key, value) {
      final index = tabs.keys.toList().indexOf(key);
      children.add(Expanded(
        child: GestureDetector(
          child: Container(
            alignment: Alignment.center,
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  key,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: activeTab == index
                        ? Color.fromARGB(0xFF, 0x33, 0x33, 0x33)
                        : Theme.of(context).unselectedWidgetColor,
                  ),
                ),
                Visibility(
                    visible: value,
                    child: Container(
                      width: 9,
                      height: 9,
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.5),
                          color: Theme.of(context).errorColor),
                    ))
              ],
            ),
          ),
          onTap: () => onTap(index),
        ),
      ));
    });
    return Row(
      children: children,
    );
  }
}
