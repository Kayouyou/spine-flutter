import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/bootstrap/bootstrap_options.dart';

void main() {
  test('defaults keep optional integrations disabled', () {
    const options = BootstrapOptions();

    expect(options.enableDebugTools, isFalse);
    expect(options.enableDataSync, isFalse);
    expect(options.enableUpgradePrompt, isFalse);
  });
}
