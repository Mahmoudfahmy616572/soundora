import 'package:flutter/material.dart';
import 'package:soundora/common/backButton/back_button.dart';

class BasicAppbar extends StatelessWidget implements PreferredSizeWidget {
  const BasicAppbar(
      {super.key, this.title, this.isLeading = false, this.actions});
  final Widget? title;
  final bool isLeading;
  final Widget? actions;
  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: title ?? const Text(''),
        actions: [actions ?? Container()],
        elevation: 0,
        leading: isLeading ? null : backButton(context));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
