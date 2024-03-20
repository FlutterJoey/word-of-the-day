import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/services/auth.dart';

import 'package:wotd/src/widgets/primary_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({
    required this.onLogin,
    required this.onLogout,
    super.key,
  });

  final void Function() onLogin;
  final void Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var authService = ref.read(authServiceProvider);

    return Column(
      children: [
        const Spacer(),
        if (authService.isSignedInAsAdmin()) ...[
          _LogoutCard(
            onLogout: onLogout,
          ),
        ] else ...[
          _LoginCard(
            onLogin: onLogin,
          ),
        ],
        const Spacer(
          flex: 2,
        ),
      ],
    );
  }
}

class _LogoutCard extends ConsumerWidget {
  const _LogoutCard({
    required this.onLogout,
  });

  final void Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);

    Future<void> logout() async {
      await ref.read(authServiceProvider).signOutAdmin();
      onLogout();
    }

    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Text(
                'Are you sure you want to logout?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24.0),
              PrimaryButton(
                onPressed: logout,
                child: const Text('Logout'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends ConsumerWidget {
  const _LoginCard({
    required this.onLogin,
  });

  final void Function() onLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<bool> login(LoginFormResponse response) async {
      try {
        await ref.read(authServiceProvider).login(
              response.email,
              response.password,
            );

        onLogin();
        return true;
      } on LoginFailedException catch (e) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => Dialog(
              child: _ClassFailedDialog(loginFailedException: e),
            ),
          );
        }
        return false;
      }
    }

    return SizedBox(
      height: 360,
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _LoginForm(
            onLogin: login,
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends HookWidget {
  const _LoginForm({
    required this.onLogin,
  });

  final Future<bool> Function(LoginFormResponse response) onLogin;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var formKey = useMemoized(() => GlobalKey<FormState>());

    var result = useRef(
      LoginFormResponse(email: '', password: ''),
    );

    Future<void> submitForm() async {
      var form = formKey.currentState!;

      if (form.validate()) {
        form.save();
        if (await onLogin(result.value)) {
          if (context.mounted) {
            form.reset();
            result.value = LoginFormResponse(email: '', password: '');
          }
        }
      }
    }

    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            Text(
              'Login',
              style: theme.textTheme.titleLarge,
            ),
            const Spacer(),
            TextFormField(
              textAlign: TextAlign.center,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }

                if (!RegExp(r'.*@.*\..*').hasMatch(value)) {
                  return 'Email needs to be valid';
                }
                return null;
              },
              onSaved: (value) {
                result.value = result.value.copyWith(
                  email: value,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              textAlign: TextAlign.center,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
              onSaved: (value) {
                result.value = result.value.copyWith(
                  password: value,
                );
              },
            ),
            const Spacer(),
            PrimaryButton(
              onPressed: submitForm,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginFormResponse {
  final String email;
  final String password;

  LoginFormResponse({required this.email, required this.password});

  LoginFormResponse copyWith({
    String? email,
    String? password,
  }) {
    return LoginFormResponse(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}

class _ClassFailedDialog extends StatelessWidget {
  const _ClassFailedDialog({
    required this.loginFailedException,
  });

  final LoginFailedException loginFailedException;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Login Failed!',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Text(loginFailedException.message),
          const SizedBox(height: 32.0),
          SizedBox(
            width: 128,
            child: PrimaryButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Try again!'),
            ),
          )
        ],
      ),
    );
  }
}
