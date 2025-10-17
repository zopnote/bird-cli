import 'dart:async';

import 'package:meta/meta.dart';

import '../workflow.dart';
import 'atomics.dart';

final class Runnable extends Step {
  final FutureOr<void> Function(FlowContext context) run;
  final String name;
  Runnable(this.run, {required this.name});

  @protected
  @override
  Future<Step?> execute(
    final FlowContext context, [
    FutureOr<Step?> candidate()?,
  ]) async {
    await run(context);
    return (candidate ?? () => null)();
  }

  @override
  Map<String, dynamic> toJson() => {"type": "runnable", "name": name};
}
