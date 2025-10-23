import 'package:stepflow/common.dart';

/**
 * A [Chain] is a [Bubble] that has a builder, which only will returning [Step]s
 * until the length of the [Chain] is reached.
 *
 * If you want an infinite [Chain], create your own [Bubble].
 */
final class Chain extends Bubble {
  /**
   * The [build] function has to return a [Step] until the index is as high,
   * as the length allows. The function will be executed every time,
   * the forgoing [Step] is done with it's execution.
   */
  late final Step Function(int index) build;

  /**
   * The [length] parameter is the length of the [Chain]
   * and will specify of how many [Step]s the [Chain] consists of.
   */
  final int length;

  Chain._internal({required this.build, required this.length});

  /**
   * A [Chain] that consists of a [List] of [Step].
   *
   * Will execute the [Step] in their order,
   * if the context won't [pop()] or [close()].
   */
  factory Chain({required List<Step> steps}) {
    return Chain._internal(
      build: (index) {
        return steps[index];
      },
      length: steps.length,
    );
  }

  /**
   * A [Chain] that consists of it's [builder] function and [length].
   *
   * Will execute the builder's [Step]s, if the context won't [pop()] or [close()].
   */
  factory Chain.builder(Step builder(int index), {required final int length}) {
    return Chain._internal(build: builder, length: length);
  }

  /**
   * The [index] of the currently ongoing [Step].
   */
  int _index = 0;

  /**
   * The [builder()] of the [Chain]'s execution order.
   */
  @override
  Step builder() {
    if (_index == length - 1) {
      leave = true;
      return build(_index++);
    }
    return build(_index++);
  }

  @override
  Map<String, dynamic> toJson() => {
    "type": "chain",
    "length": length,
    "current_index": _index,
  };
}
