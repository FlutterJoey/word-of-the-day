import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/screens/admin.dart';
import 'package:wotd/src/screens/history.dart';
import 'package:wotd/src/screens/login.dart';
import 'package:wotd/src/screens/splash.dart';
import 'package:wotd/src/screens/vote.dart';
import 'package:wotd/src/screens/word_of_the_day.dart';
import 'package:wotd/src/services/init.dart';
import 'package:wotd/src/widgets/base_screen.dart';

final routesProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      debugPrint('Navigating to ${state.uri.path}');
      if (!ref.read(initializationProvider).hasValue && state.uri.path != '/') {
        return '/?origin=${state.uri}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          var origin = state.uri.queryParameters['origin'];
          return SplashScreen(
            onComplete: () {
              context.go(origin ?? '/word-of-the-day');
            },
          );
        },
      ).noTransition(),
      ShellRoute(
        builder: (context, state, child) => BaseScreen(
          routePath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) {
              return LoginScreen(
                onLogin: () {
                  context.go('/admin');
                },
                onLogout: () {
                  context.go('/');
                },
              );
            },
          ).noTransition(),
          GoRoute(
            path: '/votes',
            builder: (context, state) {
              return const VoteScreen();
            },
          ).noTransition(),
          GoRoute(
            path: '/word-of-the-day',
            builder: (context, state) {
              return const WordOfTheDayScreen();
            },
          ).noTransition(),
          GoRoute(
            path: '/history',
            builder: (context, state) {
              return const HistoryScreen();
            },
          ).noTransition(),
          GoRoute(
            redirect: (context, state) {
              if (FirebaseAuth.instance.currentUser?.isAnonymous ?? true) {
                return '/login';
              }
              return null;
            },
            path: '/admin',
            builder: (context, state) {
              return const AdminScreen();
            },
          ).noTransition(),
        ],
      ),
    ],
  );
});

extension NoTransition on GoRoute {
  GoRoute noTransition() {
    assert(builder != null);
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: parentNavigatorKey,
      redirect: redirect,
      onExit: onExit,
      routes: routes,
      pageBuilder: (context, state) {
        return NoTransitionPage(child: builder!.call(context, state));
      },
    );
  }
}
