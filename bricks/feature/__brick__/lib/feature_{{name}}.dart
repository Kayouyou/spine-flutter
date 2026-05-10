import 'package:routing/routing.dart';
import 'src/di/setup.dart';

export 'src/cubit/{{name}}_cubit.dart';
export 'src/cubit/{{name}}_state.dart';
export 'src/ui/{{name}}_page.dart';
export 'src/di/setup.dart';
export 'src/routes/{{name}}_route_module.dart';

// 在 import 时自动注册
final _feature{{name.pascalCase()}}Setup = FeatureRegistry.instance.register('feature_{{name}}', setupFeature{{name.pascalCase()}});
