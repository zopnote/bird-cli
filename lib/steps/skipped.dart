import 'package:stepflow/workflow.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';

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