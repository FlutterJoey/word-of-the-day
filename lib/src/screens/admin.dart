import 'package:flutter/material.dart';
import 'package:flutter_hooks_iconica_utilities/flutter_hooks_iconica_utilities.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/votes.dart';
import 'package:wotd/src/services/wotd.dart';
import 'package:wotd/src/widgets/error.dart';
import 'package:wotd/src/widgets/primary_button.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    var asyncWotd = ref.watch(wordOfTodayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administration',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: asyncWotd.when(
            data: (wotd) {
              return Column(
                children: [
                  _VoteControl(
                    wotd: wotd,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Divider(),
                  ),
                  Expanded(
                    child: _PickAWinner(wotd: wotd),
                  ),
                ],
              );
            },
            error: (error, _) => ErrorDisplay(error: error),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoteControl extends StatelessWidget {
  const _VoteControl({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textTheme = theme.textTheme;

    var status = 'Ready to Open';
    if (wotd.hasVoteConcluded) {
      status = 'Closed';
    } else if (wotd.isVoteOpen) {
      status = 'Open';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ControlTitle(textTheme: textTheme, wotd: wotd),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 64.0,
          runSpacing: 16.0,
          children: [
            _VoteStatus(
              textTheme: textTheme,
              status: status,
            ),
            SizedBox(
              width: 256,
              child: _VoteToggle(
                wotd: wotd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VoteToggle extends HookConsumerWidget {
  const _VoteToggle({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> toggle() async {
      var service = ref.read(wotdServiceProvider);
      if (wotd.hasVoteConcluded) {
        return await service.reopenVote(wotd);
      }
      if (wotd.isVoteOpen) {
        return await service.closeVote(wotd);
      }
      return await service.openVote(wotd);
    }

    var status = 'Open the vote';
    if (wotd.hasVoteConcluded) {
      status = 'Reopen the vote';
    } else if (wotd.isVoteOpen) {
      status = 'Close the vote';
    }

    return PrimaryButton(
      onPressed: toggle,
      height: 56,
      child: Text(status),
    );
  }
}

class _VoteStatus extends StatelessWidget {
  const _VoteStatus({
    required this.textTheme,
    required this.status,
  });

  final TextTheme textTheme;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16.0,
      runSpacing: 16.0,
      children: [
        Text(
          'The vote is: ',
          style: textTheme.displayMedium,
        ),
        const SizedBox(width: 16.0),
        Chip(
          label: Text(
            status,
            style: textTheme.displaySmall,
          ),
        ),
      ],
    );
  }
}

class _ControlTitle extends StatelessWidget {
  const _ControlTitle({
    required this.textTheme,
    required this.wotd,
  });

  final TextTheme textTheme;
  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today',
          style: textTheme.displayLarge,
        ),
        const SizedBox(width: 16.0),
        Chip(
          label: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              wotd.id,
              style: textTheme.displaySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickAWinner extends HookConsumerWidget {
  const _PickAWinner({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var asyncSuggestions = ref.watch(wordSuggestionsProvider(wotd.id));

    return asyncSuggestions.when(
      data: (suggestions) {
        var sortedSuggestions = List<WordSuggestion>.from(suggestions)
          ..sort(
            (a, b) => a.votes.length.compareTo(b.votes.length),
          );
        return ListView(
          children: [
            for (var suggestion in sortedSuggestions) ...[
              _VotesTile(
                wotd: wotd,
                suggestion: suggestion,
              ),
              const SizedBox(
                height: 16.0,
              ),
            ]
          ],
        );
      },
      error: (error, _) => ErrorDisplay(error: error),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _VotesTile extends HookConsumerWidget {
  const _VotesTile({
    required this.wotd,
    required this.suggestion,
  });

  final WordSuggestion suggestion;
  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);

    var labelStyle = theme.textTheme.titleMedium;

    Future<void> pick() async {
      var votesService = ref.read(wotdServiceProvider);
      await votesService.pickSuggestion(suggestion);
    }

    var callBack = useLoadingCallback(pick);

    var onPressed = wotd.hasVoteConcluded ? callBack.optional : null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: 256,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.word,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    'Votes: ${suggestion.votes.length}',
                    style: labelStyle,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 256,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: labelStyle,
                  ),
                  Text(
                    suggestion.description,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 256,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: labelStyle,
                  ),
                  Text(suggestion.reason),
                ],
              ),
            ),
            SizedBox(
              width: 256,
              child: PrimaryButton(
                onPressed: onPressed,
                isLoading: callBack.isLoading,
                child: const Text('Pick'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
