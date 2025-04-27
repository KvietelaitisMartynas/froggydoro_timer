import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart'; // Defines ErrorReporter
// custom_lint_builder re-exports the necessary types like ResolvedUnitResult
import 'package:custom_lint_builder/custom_lint_builder.dart';
// We also need AnalysisSession directly for getLibraryByUri
import 'package:analyzer/dart/analysis/session.dart';
// And ResolvedUnitResult is needed for the type annotation, import its source
import 'package:analyzer/dart/analysis/results.dart';

// This is the entrypoint of our custom linter
PluginBase createPlugin() => _ExampleLinter();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _ExampleLinter extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    NoDirectSharedPreferencesLint(),
    // Add other lint rules here if needed
  ];
}

class NoDirectSharedPreferencesLint extends DartLintRule {
  NoDirectSharedPreferencesLint() : super(code: _code);

  // Define the lint code
  static const _code = LintCode(
    name: 'no_direct_shared_preferences',
    problemMessage:
        'Do not access SharedPreferences directly. Use SettingsManager instead.',
    // Optional: A more detailed explanation for users
    // correctionMessage: 'Refactor the code to use the SettingsManager class for accessing preferences.',
    // errorSeverity: ErrorSeverity.WARNING, // Default is WARNING
  );

  // Corrected run method using atNode
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) async {
      // --- Get Resolution Info ---
      final ResolvedUnitResult result = await resolver.getResolvedUnitResult();
      final typeProvider = result.typeProvider;
      final typeSystem = result.typeSystem;
      // --- End: Get Resolution Info ---

      // --- Get the SharedPreferences type ---
      final sharedPreferencesUri = Uri.parse(
        'package:shared_preferences/shared_preferences.dart',
      );
      final AnalysisSession session = result.session;
      final libraryResult = await session.getLibraryByUri(
        sharedPreferencesUri.toString(),
      );

      InterfaceElement? sharedPreferencesElement;
      if (libraryResult is LibraryElementResult) {
        sharedPreferencesElement =
            libraryResult.element.exportNamespace.get('SharedPreferences')
                as InterfaceElement?;
      }

      if (sharedPreferencesElement == null) {
        return; // SharedPreferences not resolvable
      }
      final sharedPreferencesType = sharedPreferencesElement.thisType;
      // --- End: Get the SharedPreferences type ---

      // Check if the code is inside the allowed 'SettingsManager' class
      if (_isInsideSettingsManager(node)) {
        return; // Ignore calls within SettingsManager
      }

      final target = node.target;
      final methodName = node.methodName.name;

      // Case 1: Static call like SharedPreferences.getInstance()
      if (target is SimpleIdentifier &&
          target.name == 'SharedPreferences' &&
          methodName == 'getInstance') {
        final staticElement = target.staticElement;
        if (staticElement is InterfaceElement &&
            staticElement == sharedPreferencesElement) {
          // Use atNode here
          reporter.atNode(node, code);
          return;
        }
      }

      // Case 2: Instance method calls like prefs.getString(...)
      if (target != null) {
        final targetType = target.staticType;

        if (targetType != null &&
            typeSystem.isAssignableTo(targetType, sharedPreferencesType)) {
          // Use atNode here
          reporter.atNode(node, code);
        }
      }
    });
  }

  /// Checks if the given AST node is located inside a class named 'SettingsManager'.
  bool _isInsideSettingsManager(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is ClassDeclaration &&
          current.name.lexeme == 'SettingsManager') {
        return true;
      }
      current = current.parent;
    }
    return false;
  }
}
