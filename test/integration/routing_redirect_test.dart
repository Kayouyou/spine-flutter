// test/integration/routing_redirect_test.dart
//
// P1-3: 登出后 GoRouter 自动跳到 /login via refreshListenable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:routing/routing.dart';
import 'package:spine_flutter/core/routing/go_router_refresh_stream.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit authCubit;

  setUp(() {
    authCubit = AuthCubit(_MockAuthRepository());
  });

  testWidgets('登出后 GoRouter 自动跳到 /login (P1-3)', (tester) async {
    final refreshListenable = GoRouterRefreshStream(authCubit.stream);

    final router = GoRouter(
      initialLocation: '/home',
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        return AuthGuard.check(
          state.matchedLocation,
          () => authCubit.isLoggedIn,
        );
      },
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // 1) 登录 → 跳到 /profile
    authCubit.setAuthState(
      const AuthState(status: AuthStatus.loggedIn, userId: 'u1'),
    );
    router.go('/profile');
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/profile',
    );

    // 2) 登出 → refreshListenable notifyListeners → GoRouter rerun redirect → /login
    authCubit.setAuthState(const AuthState());
    await tester.pumpAndSettle();

    final uri = router.routerDelegate.currentConfiguration.uri.toString();
    expect(
      uri,
      contains('/login'),
      reason: '登出后应通过 refreshListenable 自动跳到 /login',
    );
  });
}
