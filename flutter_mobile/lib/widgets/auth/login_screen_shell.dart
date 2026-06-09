import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'login_blobs.dart';
import 'premium_login_theme.dart';

class LoginScreenShell extends StatelessWidget {
  const LoginScreenShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumLoginTheme.background,
      resizeToAvoidBottomInset: !kIsWeb,
      body: SafeArea(
        child: Stack(
          children: [
            const LoginBlobs(),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
