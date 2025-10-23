import 'dart:async';

import 'package:meta/meta.dart';

import '../workflow.dart';
import 'atomics.dart';

/**
 * Executes the [run] function as atomic part of a workflow.
 */
final class Runnable extends Step {
  /**
   * Function that will be run at [Step]'s execution.
   */
  final FutureOr<void> Function(FlowContext context) run;

  /**
   * Tag describing what the [Runnable] does.
   */
  final String name;
  Runnable(this.run, {required this.name});

  /**
   * Executes the [run] function and returns the candidate.
   */
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
