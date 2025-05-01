import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:custom_rules/src/final_over_var_rule.dart';
import 'package:custom_rules/src/method_name_word_count_rule.dart';
import 'src/import_sorting_rule.dart';
import 'src/no_print_rule.dart';

PluginBase createPlugin() => _CustomRulesPlugin();

class _CustomRulesPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ImportSortingRule(),
        PreferFinalRule(),
        MethodNameWordCountRule(),
        PrintStatementRule(),
      ];
}
