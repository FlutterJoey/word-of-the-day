import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_iconica_utilities/flutter_hooks_iconica_utilities.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/extensions.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/auth.dart';
import 'package:wotd/src/services/votes.dart';
import 'package:wotd/src/services/wotd.dart';
import 'package:wotd/src/widgets/error.dart';
import 'package:wotd/src/widgets/primary_button.dart';

class VoteScreen extends ConsumerWidget {
  const VoteScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    var asyncWordOfTheDay = ref.watch(wordOfTodayProvider);

    var body = asyncWordOfTheDay.when<Widget>(
      data: (wordOfTheDay) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!wordOfTheDay.hasVoteConcluded) ...[
              _VoteSubmissionSection(
                wotd: wordOfTheDay,
              ),
              const SizedBox(
                height: 16.0,
              )
            ],
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _CurrentVote(
                    wotd: wordOfTheDay,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, _) {
        return ErrorDisplay(error: error);
      },
      loading: () {
        return const SizedBox(
          height: 16.0,
          child: LinearProgressIndicator(),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word of Tomorrow',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 16.0),
        Expanded(child: body),
      ],
    );
  }
}

class _CurrentVote extends StatelessWidget {
  const _CurrentVote({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context) {
    if (wotd.hasVoteConcluded) {
      return const _VoteClosed();
    }

    if (!wotd.isVoteOpen) {
      return const _VoteNotOpened();
    }

    return _VoteForAWord(
      wotd: wotd,
    );
  }
}

class _VoteClosed extends StatelessWidget {
  const _VoteClosed();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Center(
      child: Text(
        'Vote is closed! You can view the result tomorrow',
        style: theme.textTheme.displayMedium,
      ),
    );
  }
}

class _VoteForAWord extends HookConsumerWidget {
  const _VoteForAWord({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var asyncSuggestions = ref.watch(wordSuggestionsProvider(wotd.id));
    var authProvider = ref.read(authServiceProvider);
    var userId = authProvider.getId();

    return asyncSuggestions.when(
      data: (suggestions) => ListView(
        children: [
          for (var suggestion in suggestions) ...[
            _VotesTile(
              wotd: wotd,
              suggestion: suggestion,
              userId: userId!,
            ),
            const SizedBox(
              height: 16.0,
            ),
          ]
        ],
      ),
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
    required this.userId,
  });

  final WordSuggestion suggestion;
  final String userId;
  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isOwner = suggestion.owner == userId;
    bool isSelected = suggestion.votes.contains(userId);

    var theme = Theme.of(context);

    var labelStyle = theme.textTheme.titleMedium;

    Future<void> vote() async {
      var votesService = ref.read(votesServiceProvider(wotd.id));
      await votesService.voteForSuggestion(suggestion);
    }

    var callBack = useLoadingCallback(vote);

    var onPressed = isOwner || isSelected ? null : callBack.optional;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: 256,
              child: Text(
                suggestion.word,
                style: theme.textTheme.titleLarge,
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
                child: Text(isSelected ? 'Voted!' : 'Vote!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteNotOpened extends StatelessWidget {
  const _VoteNotOpened();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Center(
      child: Text(
        'Vote has not opened. Wait for the admin to open the vote',
        style: theme.textTheme.displayMedium,
      ),
    );
  }
}

class _VoteSubmissionSection extends ConsumerWidget {
  const _VoteSubmissionSection({
    required this.wotd,
  });

  final WordOfTheDay wotd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var asyncSubmission = ref.watch(
      myVoteSubmissionProvider(wotd.dateTime.toDateIsoString()),
    );

    return asyncSubmission.when(
      data: (data) {
        if (data == null) {
          return _VoteSubmissionForm(
            wordOfTheDay: wotd,
          );
        }
        return CurrentSubmission(
          wordOfTheDay: wotd,
          mySuggestion: data,
        );
      },
      error: (error, _) => ErrorDisplay(error: error),
      loading: () {
        return const SizedBox.shrink();
      },
    );
  }
}

class CurrentSubmission extends ConsumerWidget {
  const CurrentSubmission({
    required this.wordOfTheDay,
    required this.mySuggestion,
    super.key,
  });

  final WordOfTheDay wordOfTheDay;
  final WordSuggestion mySuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    var style = theme.textTheme.titleLarge;

    Widget section(String label, String value) {
      return Row(
        children: [
          Text(
            label,
            style: style,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    var word = section('Word:', mySuggestion.word);
    var description = section('Description:', mySuggestion.description);
    var votes = Row(
      children: [
        Expanded(child: section('Reason:', mySuggestion.reason)),
        Expanded(child: section('Votes:', '${mySuggestion.votes.length}')),
      ],
    );

    var button = PrimaryButton(
      onPressed: () async {
        ref.read(votesServiceProvider(wordOfTheDay.id)).deleteSuggestion();
      },
      child: const Text('Delete'),
    );

    if (Breakpoints.large.isActive(context)) {
      return _LargeSubmissionFormLayout(
        wordInput: word,
        descriptionInput: description,
        reasonInput: votes,
        button: button,
      );
    }
    return _SmallSubmissionFormLayout(
      wordInput: word,
      descriptionInput: description,
      reasonInput: votes,
      button: button,
    );
  }
}

class _VoteSubmissionForm extends HookConsumerWidget {
  const _VoteSubmissionForm({
    required this.wordOfTheDay,
  });

  final WordOfTheDay wordOfTheDay;

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var key = useMemoized(() => GlobalKey<FormState>());

    var currentSubmission = useRef(WordSuggestion.empty());

    void save(WordSuggestion Function(WordSuggestion) edit) {
      currentSubmission.value = edit(currentSubmission.value);
    }

    Future<void> onSubmit() async {
      var form = key.currentState;

      if (form == null) {
        return;
      }

      if (form.validate()) {
        form.save();
        form.reset();
        var service = ref.read(votesServiceProvider(wordOfTheDay.id));

        await service.submitSuggestion(currentSubmission.value);
      }
    }

    var wordInput = TextFormField(
      validator: _validateNotEmpty,
      onSaved: (word) => save(
        (suggestion) => suggestion.copyWith(word: word),
      ),
      decoration: const InputDecoration(
        hintText: 'Your word',
      ),
    );

    var descriptionInput = TextFormField(
      validator: _validateNotEmpty,
      onSaved: (description) => save(
        (suggestion) => suggestion.copyWith(description: description),
      ),
      decoration: const InputDecoration(
        hintText: 'What does your word mean',
      ),
    );

    var reasonInput = TextFormField(
      validator: _validateNotEmpty,
      onSaved: (reason) => save(
        (suggestion) => suggestion.copyWith(reason: reason),
      ),
      decoration: const InputDecoration(
        hintText: 'Why should people vote for your word',
      ),
    );

    var button = PrimaryButton(
      onPressed: onSubmit,
      child: const Text('Submit'),
    );

    var largeLayout = _LargeSubmissionFormLayout(
      wordInput: wordInput,
      descriptionInput: descriptionInput,
      reasonInput: reasonInput,
      button: button,
    );

    var smallLayout = _SmallSubmissionFormLayout(
      wordInput: wordInput,
      descriptionInput: descriptionInput,
      reasonInput: reasonInput,
      button: button,
    );

    return Form(
      key: key,
      child: switch (Breakpoints.large.isActive(context)) {
        false => smallLayout,
        true => largeLayout,
      },
    );
  }
}

class _SmallSubmissionFormLayout extends StatelessWidget {
  const _SmallSubmissionFormLayout({
    required this.wordInput,
    required this.descriptionInput,
    required this.reasonInput,
    required this.button,
  });

  final Widget wordInput;
  final Widget descriptionInput;
  final Widget reasonInput;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wordInput,
        const SizedBox(height: 16.0),
        descriptionInput,
        const SizedBox(height: 16.0),
        reasonInput,
        const SizedBox(height: 16.0),
        SizedBox(
          width: 256,
          child: button,
        ),
      ],
    );
  }
}

class _LargeSubmissionFormLayout extends StatelessWidget {
  const _LargeSubmissionFormLayout({
    required this.wordInput,
    required this.descriptionInput,
    required this.reasonInput,
    required this.button,
  });

  final Widget wordInput;
  final Widget descriptionInput;
  final Widget reasonInput;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: wordInput,
            ),
            const SizedBox(width: 32.0),
            Expanded(
              flex: 2,
              child: descriptionInput,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: reasonInput,
            ),
            const SizedBox(width: 32.0),
            SizedBox(
              width: 256,
              child: button,
            ),
          ],
        ),
      ],
    );
  }
}
