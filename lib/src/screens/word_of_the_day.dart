import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/extensions.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/wotd.dart';
import 'package:wotd/src/widgets/error.dart';

class WordOfTheDayScreen extends StatelessWidget {
  const WordOfTheDayScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word of the Day',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 16.0),
        const Expanded(
          child: Card(
            child: SizedBox(
              width: double.infinity,
              child: TodaysWordOfTheDay(),
            ),
          ),
        ),
      ],
    );
  }
}

class TodaysWordOfTheDay extends ConsumerWidget {
  const TodaysWordOfTheDay({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var wotd = ref.watch(wordOfTodayProvider);
    var theme = Theme.of(context);

    return wotd.when(
      data: (data) {
        if (!data.isFinished) {
          return const _AnimatedNoWordAvailable();
        }
        return _AnimatedWordOfTodayDisplay(wordOfTheDay: data);
      },
      error: (error, stackTrace) {
        return ErrorDisplay(error: error);
      },
      loading: () {
        return Center(
          child: Text(
            'Welcome to the word of the day!',
            style: theme.textTheme.displayLarge,
          ),
        );
      },
    );
  }
}

class _AnimatedWordOfTodayDisplay extends HookWidget {
  const _AnimatedWordOfTodayDisplay({required this.wordOfTheDay});

  final WordOfTheDay wordOfTheDay;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var style = theme.textTheme.displaySmall;
    var headingStyle = theme.textTheme.headlineLarge;

    Widget section(String title, String value) {
      return Column(
        children: [
          Text(
            title,
            style: headingStyle,
          ),
          const SizedBox(height: 16.0),
          Text(
            value,
            style: style,
          ),
        ],
      );
    }

    var sections = [
      section('Today is', wordOfTheDay.dateTime.toDateIsoString()),
      section('The word is:', wordOfTheDay.word!),
      section('And it means the following:', wordOfTheDay.description!),
    ];

    var currentStep = useState(0);

    useEffect(() {
      if (currentStep.value < sections.length) {
        var step = currentStep.value;
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted && step == currentStep.value) {
            currentStep.value++;
          }
        });
      }
      return null;
    }, [currentStep.value]);

    return Stack(
      children: [
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1500),
            opacity: currentStep.value == 0 ? 1 : 0,
            child: Text(
              'Welcome to the word of the day!',
              style: theme.textTheme.displayLarge,
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              sections.length,
              (index) => AnimatedOpacity(
                opacity: currentStep.value > index ? 1 : 0,
                duration: const Duration(milliseconds: 1500),
                child: sections[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedNoWordAvailable extends HookWidget {
  const _AnimatedNoWordAvailable();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var style = theme.textTheme.displaySmall;
    var headingStyle = theme.textTheme.headlineLarge;

    Widget section(String title, String value) {
      return Column(
        children: [
          Text(
            title,
            style: headingStyle,
          ),
          const SizedBox(height: 16.0),
          Text(
            value,
            style: style,
          ),
        ],
      );
    }

    var sections = [
      section('Today is', DateTime.now().toDateIsoString()),
      section(
        'There unfortunately is no word...',
        'But you are welcome to submit one!',
      ),
    ];

    var currentStep = useState(0);

    useEffect(() {
      if (currentStep.value < sections.length) {
        var step = currentStep.value;
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted && step == currentStep.value) {
            currentStep.value++;
          }
        });
      }
      return null;
    }, [currentStep.value]);

    return Stack(
      children: [
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1500),
            opacity: currentStep.value == 0 ? 1 : 0,
            child: Text(
              'Welcome to the word of the day!',
              style: theme.textTheme.displayLarge,
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              sections.length,
              (index) => AnimatedOpacity(
                opacity: currentStep.value > index ? 1 : 0,
                duration: const Duration(milliseconds: 1500),
                child: sections[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
