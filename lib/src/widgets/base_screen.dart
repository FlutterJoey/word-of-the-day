import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';

class BaseScreen extends StatelessWidget {
  const BaseScreen({
    required this.child,
    required this.routePath,
    super.key,
  });

  final Widget child;
  final String routePath;

  static const _routes = [
    '/votes',
    '/word-of-the-day',
    '/history',
    '/login',
    '/admin',
  ];

  int _getNavigationIndex() {
    return _routes.indexWhere((element) => routePath.startsWith(element));
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = FirebaseAuth.instance.currentUser;

    var isAdmin = false;

    if (currentUser != null && !currentUser.isAnonymous) {
      isAdmin = true;
    }

    return AdaptiveScaffold(
      transitionDuration: Duration.zero,
      selectedIndex: _getNavigationIndex(),
      onSelectedIndexChange: (index) {
        context.go(_routes[index]);
      },
      appBar: AppBar(
        title: const Text('Word Of The Day'),
      ),
      leadingExtendedNavRail: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Image.network(
          'https://iconica.app/wp-content/uploads/2020/06/logo-white.png',
        ),
      ),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.email_outlined),
          selectedIcon: Icon(Icons.email),
          label: 'Vote',
          tooltip: 'Click here to submit a word of the day and vote',
        ),
        const NavigationDestination(
          icon: Icon(Icons.text_fields_outlined),
          selectedIcon: Icon(Icons.text_fields),
          label: 'Word of the Day',
          tooltip: 'Click here to view the word of the day',
        ),
        const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
          tooltip: 'Click here to view all other words of the day',
        ),
        if (isAdmin) ...[
          const NavigationDestination(
            icon: Icon(Icons.logout_outlined),
            selectedIcon: Icon(Icons.logout),
            label: 'Logout',
            tooltip: 'Click here to logout',
          ),
        ] else ...[
          const NavigationDestination(
            icon: Icon(Icons.login_outlined),
            selectedIcon: Icon(Icons.login),
            label: 'Login',
            tooltip: 'Click here to login',
          ),
        ],
        if (isAdmin) ...[
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Admin',
          ),
        ]
      ],
      body: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: child,
      ),
    );
  }
}
