import 'dart:async';
import 'dart:io';

import 'package:stepflow/environment.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/config.dart';

class Skipped extends AtomicStep {
  Skipped()
    : super(
        name: "Skipped step",
        description: "A step that represents no action.",
      );
  @override
  FutureOr<Response> execute(final Environment environment) {
    return Response();
  }
}



abstract class Step {
  final String name;
  final String description;

  const Step({required this.name, required this.description});

  Step configure(final Config config);
  FutureOr<Response> execute(final Environment environment);

  Map<String, dynamic> toJson() => {"name": name, "description": description};
}

/**
 * Smallest mutable unit of the steps flow logic.
 * Contains a plain execution
 * After configuration the configured steps will be parsed into the [AtomicSteps].
 */
abstract class AtomicStep extends Step {
  AtomicStep({required super.name, required super.description});

  /**
   * After configuration, every step links to its descendant.
   *
   * Before configuration step will be [null], after it will only be [null]
   * if it would be the last of the chain.
   */
  AtomicStep? next;

  @override
  Step configure(final Config config) => this;

  @override
  Map<String, dynamic> toJson() => {}
    ..addAll(super.toJson())
    ..addAll({if (next != null) "next": next!.toJson()});
}

abstract class ConfigureStep extends Step {
  const ConfigureStep({required super.name, required super.description});

  @override
  FutureOr<Response> execute(final Environment environment) =>
      configure(Config()).execute(environment);
}
