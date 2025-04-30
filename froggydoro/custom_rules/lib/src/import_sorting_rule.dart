import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';

custom_lint.PluginBase createPlugin() => _ImportSortingLinter();

class _ImportSortingLinter extends custom_lint.PluginBase {
  @override
  List<custom_lint.LintRule> getLintRules(custom_lint.CustomLintConfigs configs) => [
        ImportSortingRule(),
      ];
}

class ImportSortingRule extends custom_lint.DartLintRule {
  ImportSortingRule() : super(code: _code);

  static const _code = custom_lint.LintCode(
    name: 'import_sorting_rule',
    problemMessage: 'Imports must be sorted alphabetically. wawawiwa',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    custom_lint.CustomLintResolver resolver,
    ErrorReporter reporter,
    custom_lint.CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      final imports = node.directives.whereType<ImportDirective>().toList();

      for (var i = 1; i < imports.length; i++) {
        final prev = imports[i - 1];
        final curr = imports[i];
        
        final prevUri = prev.uri.stringValue ?? '';
        final currUri = curr.uri.stringValue ?? '';

        if (prevUri.compareTo(currUri) > 0) {
          reporter.atNode(curr, _code);
        }
      }
    });
  }
}
