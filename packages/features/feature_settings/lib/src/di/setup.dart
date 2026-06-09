import 'package:get_it/get_it.dart';
import 'package:routing/routing.dart';
import '../routes/settings_route_module.dart';

void setupFeatureSettings(GetIt sl) {
  RouteModuleRegistry.instance.register(
    'feature_settings',
    (ctx) => SettingsRouteModule(ctx),
  );
}
