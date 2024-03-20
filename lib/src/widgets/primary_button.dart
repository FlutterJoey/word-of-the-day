import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_iconica_utilities/flutter_hooks_iconica_utilities.dart';

class PrimaryButton extends HookWidget {
  const PrimaryButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.height = 40,
    super.key,
  });

  final FutureOr<void> Function()? onPressed;
  final Widget child;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    var handler = useLoadingCallback(
      () async => await onPressed?.call(),
      keys: [onPressed],
    );

    return FilledButton(
      onPressed: onPressed != null ? handler.optional : null,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: child,
              ),
            ),
            if (handler.isLoading || isLoading) ...[
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
