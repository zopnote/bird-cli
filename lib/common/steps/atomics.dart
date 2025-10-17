import 'dart:async';

import 'package:stepflow/cli.dart';
import 'package:stepflow/common.dart';

/**
 * The blueprint for an atomic, representation of a step inside the workflows.
 */
abstract class Step {
  const Step();
  FutureOr<Step?> execute(final FlowContext context, [FutureOr<Step?> candidate()?]);
  Map<String, dynamic> toJson();
}

abstract class ConfigureStep extends Step {
  const ConfigureStep();

  Step configure();

  @override
  FutureOr<Step?> execute(final FlowContext context, [FutureOr<Step?> candidate()?]) =>
      this.configure().execute(context, candidate);

  @override
  Map<String, dynamic> toJson() => {};
}

/** ----------------------------------------------------------------------------- [NOTE]
 * It is important to notice, that an atomic step has to be capable of manipulating the execution
 * order as well as only run some code. We want to lazy configure steps and therefore the
 * configuration has to be part of the execution manipulation.
 *
 * ConfigureStep will just be a step, that will reduce its own components by itself down to atomics.
 */

class Test extends ConfigureStep {
  @override
  Step configure() {
    return Chain.builder((index) {
      if (index == 0) {
        return Chain(
          steps: [
            Shell(
              name: "Gets the version of Dart SDK",
              program: "dart",
              arguments: ["--version"],
            ),
          ],
        );
      }
      return Runnable(name: "Print out hello world", (context) {
        print("Hello world");
      });
    }, length: 5);
  }
}
