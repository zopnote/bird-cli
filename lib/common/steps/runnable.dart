import 'dart:async';

import 'package:meta/meta.dart';

import '../workflow.dart';
import 'atomics.dart';

/**
 * Executes the [run] function and returns the next [Step].
 */
final class Runnable extends Step {
  /// Function that will be run at [Step] execution.
  final FutureOr<void> Function(FlowContext context) run;

  /// Nametag of what this [Step] does.
  final String name;
  Runnable(this.run, {required this.name});

  @protected
  @override
  Future<Step?> execute(
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]) async {
    await run(controller.context);
    return (candidate ?? () => null)();
  }

  @override
  Map<String, dynamic> toJson() => {"type": "runnable", "name": name};
}
