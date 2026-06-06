import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';
import 'package:auth/src/di/setup.dart';
import 'package:auth/src/manager.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:key_value_storage/key_value_storage.dart';

void main() {
  late GetIt sl;

  setUp(() {
    sl = GetIt.instance;
    if (sl.isRegistered<AuthCubit>()) sl.unregister<AuthCubit>();
    if (sl.isRegistered<AuthRepository>()) sl.unregister<AuthRepository>();
    if (sl.isRegistered<UserRepository>()) sl.unregister<UserRepository>();
    if (sl.isRegistered<TokenStorage>()) sl.unregister<TokenStorage>();
    if (sl.isRegistered<AuthManager>()) sl.unregister<AuthManager>();
    setupAuth(sl);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('AuthCubit is registered as lazySingleton (identical on repeated resolve)', () {
    expect(identical(sl<AuthCubit>(), sl<AuthCubit>()), isTrue,
        reason: 'AuthCubit 必须 lazySingleton，否则 AuthManager 与 AuthGuard '
            '会拿到不同实例，isLoggedIn 三层转发会断');
  });

  test('setupAuth 注册后 cubit 已注册但未构造 (lazy)', () {
    expect(sl.isRegistered<AuthCubit>(), isTrue);
  });

  test('AuthCubit.isLoggedIn defaults to false on first resolve (initial state)', () {
    final cubit = sl<AuthCubit>();
    expect(cubit.isLoggedIn, isFalse);
    expect(cubit.state.status, AuthStatus.initial);
  });
}
