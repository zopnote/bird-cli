import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/skipped.dart';

class Conditional extends ConfigureStep {
  final bool condition;
  final Step child;
  const Conditional({required this.condition, required this.child})
    : super(
        name: "Configure by condition",
        description:
            "Decide based on the condition if the returned Step is a SkippedStep or the child.",
      );

  @override
  Step configure() => condition ? child : Skipped();
}
