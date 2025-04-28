import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/error/error.dart';

custom_lint.PluginBase createPlugin() => _NoTodoCommentsLinter();

class _NoTodoCommentsLinter extends custom_lint.PluginBase {
  @override
  List<custom_lint.LintRule> getLintRules(custom_lint.CustomLintConfigs configs) => [
        NoTodoCommentsRule(),
      ];
}

class NoTodoCommentsRule extends custom_lint.DartLintRule {
  NoTodoCommentsRule() : super(code: _code);

  static const _code = custom_lint.LintCode(
    name: 'no_todo_comments',
    problemMessage: 'TODO comments are not allowed.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    custom_lint.CustomLintResolver resolver,
    ErrorReporter reporter,
    custom_lint.CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      if (node.toSource().contains('To do')) {
        reporter.atNode(node, code);
      }
    });
  }
}
