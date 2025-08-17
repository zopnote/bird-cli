import 'dart:async';
import '../environment.dart';
import '../response.dart';
import 'atomics.dart';

class Runnable extends AtomicStep {
  final FutureOr<Response> Function(Environment environment) run;
  Runnable(this.run, {required super.name, required super.description});
  @override
  FutureOr<Response> execute(final Environment environment) => run(environment);
}
