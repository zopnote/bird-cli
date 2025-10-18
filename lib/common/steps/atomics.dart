import 'dart:async';

import 'package:stepflow/common.dart';

/**
 * Blueprint of the atomic representation of a step inside of workflows.
 *
 * An [Step] is capable of manipulating the execution order.
 * It can also run whatever code it wants.
 */
abstract class Step {
  const Step();

  /**
   * Work this [Step] will do.
   *
   * The controller holds the context of the workflow and can manipulate it's data.
   *
   * The function has to return the [Step] that will follow in the execution chain.
   * If you don't want to manipulate the order, just return the [candidate].
   * For an example look at the implementation of [Bubble].
   */
  FutureOr<Step?> execute(
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]);

  /**
   * For debugging purposes a [Step] should be able to save it's values into
   * a json map.
   */
  Map<String, dynamic> toJson();
}

/**
 * A [ConfigureStep] will build it's [configure()] function into the smallest parts and executes them.
 */
abstract class ConfigureStep extends Step {
  const ConfigureStep();

  /**
   * Composes [Step]s into one unit to enable more
   * modular and understandable workflows.
   *
   * Has to return a [Step].
   */
  Step configure();

  /**
   * A [ConfigureStep] will just executes it's underlying [Step]s of [configure()].
   */
  @override
  FutureOr<Step?> execute(
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]) => this.configure().execute(controller, candidate);

  @override
  Map<String, dynamic> toJson() => {};
}
