import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:froggydoro/main.dart' as app;

void main() {
  setUrlStrategy(PathUrlStrategy());
  app.main();
}
