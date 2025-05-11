import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';

custom_lint.PluginBase createPlugin() => _MethodNameWordCountLinter();

class _MethodNameWordCountLinter extends custom_lint.PluginBase {
  @override
  List<custom_lint.LintRule> getLintRules(
          custom_lint.CustomLintConfigs configs) =>
      [
        MethodNameWordCountRule(),
      ];
}

class MethodNameWordCountRule extends custom_lint.DartLintRule {
  const MethodNameWordCountRule() : super(code: _code);

  static const _code = custom_lint.LintCode(
    name: 'method_name_min_words',
    problemMessage: 'Method names should contain at least two words.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    custom_lint.CustomLintResolver resolver,
    ErrorReporter reporter,
    custom_lint.CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((MethodDeclaration node) {
      final name = node.name.lexeme;

      final words =
          RegExp(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])').allMatches(name).length;

      final ignoredNames = {
        'main',
        'build',
        'initState',
        'dispose',
        'database'
      };
      if (!ignoredNames.contains(name) && words < 2) {
        reporter.atNode(node, _code);
      }
    });
  }
}
