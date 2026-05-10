import 'package:routing/routing.dart';
import 'src/di/setup.dart';

export 'src/cubit/detail_cubit.dart';
export 'src/cubit/detail_state.dart';
export 'src/ui/detail_page.dart';
export 'src/di/setup.dart';
export 'src/routes/detail_route_module.dart';

final _featureDetailSetup = FeatureRegistry.instance.register('feature_detail', setupFeatureDetail);
