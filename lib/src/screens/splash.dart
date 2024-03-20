import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/services/init.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({
    required this.onComplete,
    super.key,
  });

  static const _splashDelay = Duration(seconds: 1);

  final void Function() onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayLarge;

    var future = useMemoized(
      () => Future<bool>.delayed(_splashDelay, () => true),
    );

    var status = useFuture(future);

    if (status.hasData) {
      var asyncInitialization = ref.read(initializationProvider);
      if (asyncInitialization.hasValue && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          onComplete();
        });
      } else {
        ref.listen(initializationProvider, (_, value) {
          if (value.hasValue) {
            onComplete();
          }
        });
      }
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: double.infinity),
          const Spacer(),
          Text('Word', style: style),
          const SizedBox(height: 8.0),
          Text('Of', style: style),
          const SizedBox(height: 8.0),
          Text('The', style: style),
          const SizedBox(height: 8.0),
          Text('Day', style: style),
          const Spacer(),
          const CircularProgressIndicator(),
          const Spacer(),
        ],
      ),
    );
  }
}
