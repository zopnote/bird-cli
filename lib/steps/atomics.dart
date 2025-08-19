import 'dart:async';

import 'package:stepflow/environment.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/config.dart';


/**
 * The blueprint for a atomic, representation of a step inside the workflows.
 */
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
 * Derived classes have to override the execution function because an [AtomicStep]
 * is the smallest unit, and the only unit that is executable.
 *
 * After configuration the configured steps will be parsed into their smallest parts [AtomicSteps].
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
