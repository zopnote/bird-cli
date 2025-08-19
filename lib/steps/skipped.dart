import 'package:stepflow/environment.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';

class Skipped extends AtomicStep {
  Skipped()
      : super(
    name: "Skipped step",
    description: "A step that represents no action.",
  );
  @override
  Response execute(final Environment environment) {
    return Response();
  }
  @override
  Map<String, dynamic> toJson() => {};
}