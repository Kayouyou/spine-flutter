import 'package:flutter_test/flutter_test.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:get_it/get_it.dart';
import 'package:routing/routing.dart';

void main() {
  late GetIt sl;

  void setup() {
    FeatureRegistry.instance.clear();
    sl.reset();
    FeatureRegistry.instance.register('feature_home', setupFeatureHome);
    FeatureRegistry.instance.register('feature_detail', setupFeatureDetail);
    FeatureRegistry.instance.register('feature_auth', setupFeatureAuth);
  }

  setUp(() {
    sl = GetIt.instance;
    setup();
  });

  tearDown(() {
    FeatureRegistry.instance.clear();
    sl.reset();
  });

  group('FeatureRegistry explicit registration', () {
    test('runAll registers HomeCubit', () {
      FeatureRegistry.instance.runAll(sl);
      expect(sl.isRegistered<HomeCubit>(), isTrue);
    });

    test('runAll registers DetailCubit', () {
      FeatureRegistry.instance.runAll(sl);
      expect(sl.isRegistered<DetailCubit>(), isTrue);
    });

    test('runAll registers LoginCubit', () {
      FeatureRegistry.instance.runAll(sl);
      expect(sl.isRegistered<LoginCubit>(), isTrue);
    });

    test('new feature added before runAll is picked up', () {
      var newFeatureCalled = false;
      void fakeSetup(GetIt s) {
        newFeatureCalled = true;
      }
      FeatureRegistry.instance.register('fake_feature', fakeSetup);
      FeatureRegistry.instance.runAll(sl);
      expect(newFeatureCalled, isTrue);
    });

    test('register prevents duplicate name entries', () {
      var callCount = 0;
      void fakeSetup(GetIt s) => callCount++;
      FeatureRegistry.instance.register('test_dup', fakeSetup);
      FeatureRegistry.instance.register('test_dup', fakeSetup);
      FeatureRegistry.instance.runAll(sl);
      expect(callCount, 1);
    });
  });
}
