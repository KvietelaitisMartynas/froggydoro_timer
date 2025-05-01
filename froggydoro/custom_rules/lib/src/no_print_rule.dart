import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';

custom_lint.PluginBase createPlugin() => _PrintStatementLinter();

class _PrintStatementLinter extends custom_lint.PluginBase {
  @override
  List<custom_lint.LintRule> getLintRules(custom_lint.CustomLintConfigs configs) =>
      [PrintStatementRule()];
}

class PrintStatementRule extends custom_lint.DartLintRule {
  static const _code = custom_lint.LintCode(
    name: 'no_print_statements',
    problemMessage: 'Avoid using print statements in the code.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  PrintStatementRule() : super(code: _code);

  @override
  void run(
    custom_lint.CustomLintResolver resolver,
    ErrorReporter reporter,
    custom_lint.CustomLintContext context,
  ) {
    context.registry.addExpression((Expression node) {
      if (node is MethodInvocation && node.methodName.name == 'print') {
        reporter.atNode(node, _code);
      }
    });
  }
}
