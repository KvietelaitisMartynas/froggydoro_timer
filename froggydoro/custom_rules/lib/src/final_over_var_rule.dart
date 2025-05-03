import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';

custom_lint.PluginBase createPlugin() => _PreferFinalLinter();

class _PreferFinalLinter extends custom_lint.PluginBase {
  @override
  List<custom_lint.LintRule> getLintRules(custom_lint.CustomLintConfigs configs) => [
        PreferFinalRule(),
      ];
}

class PreferFinalRule extends custom_lint.DartLintRule {
  PreferFinalRule() : super(code: _code);

  static const _code = custom_lint.LintCode(
    name: 'prefer_final_over_var',
    problemMessage: 'Use final instead of var for variables that are not reassigned.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    custom_lint.CustomLintResolver resolver,
    ErrorReporter reporter,
    custom_lint.CustomLintContext context,
  ) {
    context.registry.addVariableDeclarationList((node) {
      if (node.keyword?.keyword == Keyword.VAR) {
        reporter.atNode(node, _code);
      }
    });
  }
}
