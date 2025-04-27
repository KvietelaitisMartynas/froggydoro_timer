import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/error/listener.dart';

/// This is the entrypoint of our custom linter.
PluginBase createPlugin() => _ImportSortingLinter();

/// A plugin class that lists all the custom lints defined by the plugin.
class _ImportSortingLinter extends PluginBase {
  /// Listing our custom lint rule.
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ImportSortingRule(),
      ];
}

class ImportSortingRule extends DartLintRule {
  // Code metadata for the lint rule.
  ImportSortingRule() : super(code: _code);

  static const _code = LintCode(
    name: 'import_sorting_rule',
    problemMessage: 'Imports must be sorted alphabetically.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Inspect the entire Dart file for import directives
    context.registry.addCompilationUnit((node) {
      final imports = node.directives.whereType<ImportDirective>().toList();

      // Check if any imports are out of order
      for (var i = 1; i < imports.length; i++) {
        final prev = imports[i - 1];
        final curr = imports[i];

        final prevUri = prev.uri.stringValue ?? '';
        final currUri = curr.uri.stringValue ?? '';

        // If the imports are not alphabetically sorted, report the issue
        if (prevUri.compareTo(currUri) > 0) {
          reporter.atNode(curr, _code);
        }
      }
    });
  }
}
