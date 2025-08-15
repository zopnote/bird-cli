import 'dart:async';
import 'dart:io';

import 'package:stepped_cli/environment.dart';
import 'package:stepped_cli/response.dart';
import 'package:stepped_cli/spinner.dart';
import 'package:stepped_cli/config.dart';

class Skipped<T extends Environment> extends AtomicStep<T> {
  Skipped()
    : super(
        name: "Skipped step",
        description: "A step that represents no action.",
      );
  @override
  FutureOr<Response> execute(T environment) {
    return Response();
  }
}

class Runnable<T extends Environment> extends AtomicStep<T> {
  final ProcessSpinner? spinner;
  final FutureOr<Response> Function(Environment environment) run;

  Runnable(
    this.run, {
    required super.name,
    required super.description,
    this.spinner,
  });

  @override
  Future<Response> execute(Environment environment) async {
    final bool hasSpinner = this.spinner != null;
    if (hasSpinner) {
      spinner!.start(name);
    } else {
      stdout.writeln(name);
    }
    return await run(environment);
  }
}

abstract class Step<T extends Environment> {
  final String name;
  final String description;

  const Step({required this.name, required this.description});

  Step configure(final Config config);
  FutureOr<Response> execute(final T environment);
}

abstract class AtomicStep<T extends Environment> extends Step<T> {
  AtomicStep({required super.name, required super.description});

  /**
   * After configuration, every step links to its descendant.
   *
   * Before configuration step will be [null], after it will only be [null]
   * if it would be the last of the chain.
   */
  AtomicStep? next;

  @override
  Step<T> configure(final Config config) =>
      throw Exception("An atomic steps doesn't provide a configuration step.");

  Map<String, dynamic> toJson() => {
    "name": name,
    "description": description,
    if (next != null) "next": next!.toJson(),
  };
}

abstract class ConfigureStep<T extends Environment> extends Step<T> {
  const ConfigureStep({required super.name, required super.description});

  @override
  FutureOr<Response> execute(final T environment) => throw Exception(
    "A configurable step doesn't have a execution function, because it is a composition of steps.",
  );
}
