import 'dart:ui';
import 'package:flutter/material.dart';

class BlurryAlert extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback continueCallBack;

  const BlurryAlert(this.title, this.content, this.continueCallBack,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          title: Text(title),
          scrollable: true,
          content: Text(content),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Got it!"),
              onPressed: () async {
                continueCallBack();
              },
            ),
          ],
        ));
  }
}
