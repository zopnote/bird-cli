import 'package:stepflow/common.dart';

/**
 * A looped chain of [Step]s.
 */
final class Loop extends Bubble {

  /**
   * Length of the loop.
   * Indicates how often the [build] function would be run.
   */
  final int length;

  /**
   * Returns the next step to be executed as part of the loop.
   * If [null] is returned the loop will end.
   */
  late final Step? Function(int index) build;

  /**
   * Constructs a [Loop] by it's length and builder.
   * Closes the loop whenever the [build] function returns [null].
   */
  Loop.builder(this.build, this.length);

  /**
   * Constructs a [Loop] by a closure test and a list of steps.
   */
  Loop({
    required final bool Function() close,
    required final List<Step> steps
}) : length = steps.length {
    build = (i) {
      if (close()) return null;
      return steps[i];
    };
  }

  /**
   * Index marking the position of the step inside the loop.
   * Used for indication.
   */
  int index = 0;

  /**
   * Retrieves a [Step] from the [build] function
   * and returns a [Skipped] step as well as ends the loop,
   * whenever the retrieved step is [null].
   */
  @override
  Step builder() {
    final Step? step = build(index++);
    if (index == length - 1) index = 0;
    leave = step == null;
    return step ?? Skipped();
  }

  @override
  Map<String, dynamic> toJson() => {
    "type": "loop",
    "length": length,
    "leave": leave,
    "index": index
  };
}