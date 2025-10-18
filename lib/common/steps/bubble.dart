import 'dart:async';

import 'package:meta/meta.dart';

import '../workflow.dart';
import 'atomics.dart';

/**
 * A [Bubble] is a [Step] that consists of running a builder function,
 * and its returned [Step], until it receives the prompt to stop.
 * Then it will run the candidate it got on the execution of itself.
 *
 * A [Bubble] can be closed by [FlowContext.pop()], [FlowContext.close()] or
 * by setting the [bool leave] to [true].
 * * [pop()] and [close()] are meant for errors
 * that can occur as part of the workflow inside of the [Bubble].
 * * [leave] is
 * way to escape the [Bubble] successfully.
 *
 * As example, in the [Chain] step,
 * [leave] is set to true whenever the length of the steps is reached.
 */
abstract class Bubble extends Step {
  /**
   * Marks if the [Bubble] should be closed after the current running [Step].
   *
   * Should be used only inside of subclasses derived from [Bubble].
   */
  @protected
  bool leave = false;

  /**
   * The builder function will be called whenever the previous step inside the
   * [Bubble] passes by without an error.
   *
   * In a [Bubble] where no [FlowContext.pop()],
   * [FlowContext.close()] or [bool leave = true] occurs,
   * the builder function should never allocate memory that
   * lives longer than the step it returns, because it will be ran infinite times.
   */
  Step builder();

  /**
   * Executes the builder function until an escape prompt is received.
   *
   * Increases the [FlowContext]'s depth and runs steps.
   *
   * If closed the function will return it's given [candidate] or [null].
   */
  @override
  FutureOr<Step?> execute(
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]) async {
    controller.depth++;
    final int chainsDepth = controller.depth;

    /*
     * The [decide()] function will be the candidate for every [Step] of his
     * builder. Therefore whenever the next Step should be returned, the [Bubble]
     * will decide if it is still open and return the next [decide()] or the actual
     * next "[candidate]" ([Step] in execution order).
     */
    FutureOr<Step?> decide() async {
      /*
       * The [depth] of the controller will be able to change from the
       * [Step]s the [Bubble] includes.
       */
      if (chainsDepth > controller.depth) {
        return (candidate ?? () => null)();
      }
      /*
       * In a derived class, leave can be set to leave the [Bubble] successfully.
       * (Just without an error message)
       */
      if (leave) {
        controller.depth--;
        return (candidate ?? () => null)();
      }
      return builder().execute(controller, decide);
    }
    return decide();
  }
}
