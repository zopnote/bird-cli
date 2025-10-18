import 'dart:async';

import 'package:stepflow/common.dart';

/**
 * [Step] that just return the candidate and does nothing.
 */
final class Skipped extends Step {
  const Skipped();

  /// Does nothing than returns the candidate.
  @override
  FutureOr<Step?> execute(
    final FlowContextController controller, [
    FutureOr<Step?> candidate()?,
  ]) {
    return (candidate ?? () => null)();
  }

  @override
  Map<String, dynamic> toJson() => {};
}
