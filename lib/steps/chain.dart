
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/skipped.dart';

final class Chain extends ConfigureStep {
  final List<Step> _steps;

  const Chain({required final List<Step> steps})
      : _steps = steps,
        super(
        name: "Execute chained steps",
        description:
        "A step containing chained subordinary steps. "
            "Steps may depend on each other.",
      );

  @override
  Step configure() {
    if (_steps.isEmpty) return Skipped();
    final List<AtomicStep> atomicSteps = [];
    for (Step step in _steps) {
      while (!(step is AtomicStep)) {
        step = step.configure();
      }
      atomicSteps.add(step);
    }
    AtomicStep step = atomicSteps.first;
    for (int i = 0; i < atomicSteps.length - 1; i++) {
      if (i >= atomicSteps.length - 1) {
        continue;
      }
      step.next = atomicSteps[i + 1];
      step = step.next!;
    }
    return atomicSteps.first;
  }

  @override
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> jsonList = [];
    _steps.forEach((step) {
      jsonList.add(step.toJson());
    });
    return {"steps": jsonList};
  }
}