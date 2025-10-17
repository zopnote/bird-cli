
import 'package:stepflow/common.dart';


class Conditional extends ConfigureStep {
  final bool condition;
  final Step child;
  const Conditional({required this.condition, required this.child});

  @override
  Step configure() => condition ? child : Skipped();
}
