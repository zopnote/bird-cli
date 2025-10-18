import 'dart:async';

import 'package:stepflow/common.dart';

class Skipped extends Step {
  const Skipped();
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
