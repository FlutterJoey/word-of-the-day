import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/extensions.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/wotd.dart';
import 'package:wotd/src/widgets/error.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    var data = ref.watch(wordsOfThePastProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Words of the Past',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: data.when(
            data: (data) {
              return HistoryLayout(words: data);
            },
            error: (error, _) {
              return ErrorDisplay(error: error);
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        )
      ],
    );
  }
}

class HistoryLayout extends StatelessWidget {
  const HistoryLayout({
    super.key,
    required this.words,
  });

  final List<WordOfTheDay> words;

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.small.isActive(context)) {
      return HistoryListLayout(words: words);
    }

    var gridSize = 3;
    if (Breakpoints.medium.isActive(context)) {
      gridSize = 2;
    }
    return HistoryGridLayout(
      columns: gridSize,
      words: words,
    );
  }
}

class HistoryGridLayout extends StatelessWidget {
  const HistoryGridLayout({
    required this.columns,
    required this.words,
    super.key,
  });

  final List<WordOfTheDay> words;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      children: [
        for (var word in words) ...[
          HistoryGridTile(
            word: word,
          ),
        ]
      ],
    );
  }
}

class HistoryListLayout extends StatelessWidget {
  const HistoryListLayout({
    super.key,
    required this.words,
  });

  final List<WordOfTheDay> words;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (var word in words) ...[
          HistoryListTile(word: word),
          const SizedBox(height: 16.0)
        ]
      ],
    );
  }
}

class HistoryListTile extends StatelessWidget {
  final WordOfTheDay word;

  const HistoryListTile({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word.word!,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  word.dateTime.toDateIsoString(),
                  style: theme.textTheme.titleMedium,
                )
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              word.description!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryGridTile extends StatelessWidget {
  final WordOfTheDay word;

  const HistoryGridTile({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    var radius = 12.0;
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),
              ),
              child: Text(
                word.word!,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day:',
                      style: labelStyle,
                    ),
                    Text(
                      word.dateTime.toDateIsoString(),
                      style: theme.textTheme.titleMedium,
                    )
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Description',
                  style: labelStyle,
                ),
                const SizedBox(height: 8.0),
                Text(
                  word.description!,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
