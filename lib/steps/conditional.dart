import 'package:stepflow/config.dart';
import 'package:stepflow/steps/atomics.dart';

class Conditional extends ConfigureStep {
  final bool Function(Config) condition;
  final Step child;
  const Conditional({required this.condition, required this.child})
      : super(
    name: "Configure by condition",
    description:
    "Decide based on the condition if the returned Step is a SkippedStep or the child.",
  );

  @override
  Step configure(Config config) => condition(config) ? child : Skipped();
}