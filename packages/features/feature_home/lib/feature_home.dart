import 'package:routing/routing.dart';
import 'src/di/setup.dart';

export 'src/cubit/home_cubit.dart';
export 'src/cubit/home_state.dart';
export 'src/ui/home_page.dart';
export 'src/di/setup.dart';
export 'src/routes/home_route_module.dart';

// 在 import 时自动注册
final _featureHomeSetup = FeatureRegistry.instance.register('feature_home', setupFeatureHome);
