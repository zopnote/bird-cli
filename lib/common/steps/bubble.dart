import 'dart:async';

import 'package:meta/meta.dart';

import '../workflow.dart';
import 'atomics.dart';

abstract class Bubble extends Step {
  @protected
  bool leave = false;

  Step builder();

  @override
  FutureOr<Step?> execute(
    final FlowContext context, [
    FutureOr<Step?> candidate()?,
  ]) async {
    context.increaseDepth();
    final int chainsDepth = context.depth;
    return builder().execute(context, () async {
      if (chainsDepth < context.depth) {
        return (candidate ?? () => null)();
      }
      if (leave) {
        context.decreaseDepth();
        return (candidate ?? () => null)();
      }
      return await builder();
    });
  }
}
