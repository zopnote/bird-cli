import 'dart:async';

import '../workflow.dart';
import '../response.dart';
import 'atomics.dart';

final class Runnable extends AtomicStep {
  final FutureOr<Response?> Function(FlowContext environment) run;
  Runnable(this.run, {required super.name, required super.description});

  @override
  FutureOr<Response?> execute(final FlowContext environment) {
    return run(environment);
  }
}
