library custom_rules;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/import_sorting_rule.dart'; // Import your rule
import 'src/rule34.dart'; // Import your rule

PluginBase createPlugin() => _CustomRulesPlugin();

class _CustomRulesPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ImportSortingRule(), // Add your rule here
        NoTodoCommentsRule(), // Add your rule here
      ];
}
