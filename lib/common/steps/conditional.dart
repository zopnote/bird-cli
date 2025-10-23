
import 'package:stepflow/common.dart';


/**
 * A [Conditional] is a simple [ConfigureStep] that will either return its child or a
 * [Skipped] [Step] based on [condition].
 */
final class Conditional extends ConfigureStep {
  /**
   * If the [child] should be returned on configuration.
   */
  final bool condition;

  /**
   * [Step] that maybe will be in condition.
   */
  final Step child;

  /**
   * Default const constructor for a conditional.
   * Uses the condition on runtime.
   */
  const Conditional({required this.condition, required this.child});

  @override
  Step configure() => condition ? child : Skipped();
}
