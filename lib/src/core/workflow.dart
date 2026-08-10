import 'dart:async';

import 'package:stepflow/core.dart';

final class FlowException implements Exception {
  final Exception exception;
  final List<StackTrace> stackTrace;
  final int depth;
  final Step currentStep;
  const FlowException(
      {required this.exception,
      required this.stackTrace,
      required this.depth,
      required this.currentStep});
  @override
  String toString() => "FlowException at ${currentStep.runtimeType} "
      "with depth $depth:\n$exception\n"
      "\n${stackTrace.join("\n")}";
}

/**
 * Runs the [Step] as workflow and creates a [FlowController] for it.
 *
 * [onData] calls whenever a [Response] occurs.
 */
Future<void> runWorkflow(
  Step step, [
  void Function(FlowException)? onException,
]) async {
  final FlowController controller = FlowController();
  try {
    await controller.execute(step);
  } catch (e, st) {
    if (e is! Exception) {
      rethrow;
    }
    final FlowException exception = FlowException(
        exception: e,
        stackTrace: [st],
        depth: controller._depth,
        currentStep: controller._current!);
    if (onException == null) {
      throw st;
    }
    onException.call(exception);
  }
  return controller.close();
}

/**
 * Controls and contains the [FlowContext] for a workflow.
 *
 * For creating a workflow a [FlowController] mus be provided.
 */
final class FlowController {
  /**
   * The current depth of the workflow, characterized through the nesting of [Bubble].
   *
   * If the value changes, the workflow will react through changing it's current
   * position of steps.
   */
  int _depth = 0;

  Step? _current;

  Future<void> execute(Step step) async {
    await (_current = step).execute(this);
  }

  Future<void> createBubble(Step? Function() builder) async {
    _depth++;
    final int initialDepth = _depth;

    /*
     * The [decide()] function will be the candidate for every [Step] of his
     * builder. Therefore whenever the next Step should be returned, the [Bubble]
     * will decide if it is still open and return the next [decide()] or the actual
     * next "[candidate]" ([Step] in execution order).
     */
    FutureOr<Step?> decide() async {
      _current = builder();
      /*
       * The [depth] of the controller will be able to change from the
       * [Step]s the [Bubble] includes.
       */
      if (initialDepth > _depth) {
        return null;
      }
      return _current?.execute(this, decide);
    }

    await decide();
  }

  /**
   * Closes the workflow and it's [FlowController].
   */
  Future<void> close() async {
    _depth = 0;
  }
}
