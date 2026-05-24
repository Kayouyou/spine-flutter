import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:feature_home/feature_home.dart';
import 'package:domain/domain.dart';

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Result<HomeData, DomainException>> getHomeData() async {
    return Result.failure(NetworkException('unknown'));
  }

  @override
  Future<Result<HomeData, DomainException>> refreshHomeData() async {
    return Result.failure(NetworkException('unknown'));
  }
}

class _FakeHomeCubit extends HomeCubit {
  _FakeHomeCubit() : super(_FakeHomeRepository());
}

void main() {
  testWidgets('shows debug action only when callback is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>.value(
          value: _FakeHomeCubit(),
          child: HomePage(onOpenDebugInspector: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });
}
