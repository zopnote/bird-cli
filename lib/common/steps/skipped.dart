
import 'package:stepflow/common.dart';


class Skipped extends AtomicStep {
  Skipped()
      : super(
    name: "Skipped step",
    description: "A step that represents no action.",
  );
  @override
  Response execute(final FlowContext environment) {
    return Response();
  }
  @override
  Map<String, dynamic> toJson() => {};
}