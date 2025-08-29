import 'dart:async';
import 'package:meta/meta.dart';

import '../environment.dart';
import '../response.dart';
import 'atomics.dart';

class Runnable extends AtomicStep {
  final FutureOr<Response> Function(Environment environment) run;
  Runnable(this.run, {required super.name, required super.description});

  @override
  @protected
  FutureOr<Response> execute(final Environment environment) => run(environment);
}
