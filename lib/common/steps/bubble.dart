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
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]) async {
    controller.depth++;
    final int chainsDepth = controller.depth;
    FutureOr<Step?> decide() async {
      if (chainsDepth > controller.depth) {
        return (candidate ?? () => null)();
      }
      if (leave) {
        controller.depth--;
        return (candidate ?? () => null)();
      }
      return builder().execute(controller, decide);
    }
    return decide();
  }
}
