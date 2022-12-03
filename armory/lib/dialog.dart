import 'dart:ui';
import 'package:flutter/material.dart';

class BlurryDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback continueCallBack;

  const BlurryDialog(this.title, this.content, this.continueCallBack,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          title: Text(title),
          scrollable: true,
          content: content,
          actions: <Widget>[
            OutlinedButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Connect"),
              onPressed: () async {
                continueCallBack();
              },
            ),
          ],
        ));
  }
}
