import 'dart:async';

import 'package:stepflow/common.dart';

/**
 * Runs the [Step] as workflow and creates a [FlowContextController] for it.
 *
 * [onData] calls whenever a [Response] occurs.
 */
Future<Response> runWorkflow(
  Step step, [
  void Function(Response)? onData,
]) async {
  final FlowContextController controller = FlowContextController.observed(
    onData ?? (_) {},
  );
  await step.execute(controller);
  return await controller.close();
}

/**
 * Controls and contains the [FlowContext] for a workflow.
 *
 * For creating a workflow a [FlowContextController] mus be provided.
 */
final class FlowContextController {
  /**
   * The current depth of the workflow, characterized through the nesting of [Bubble].
   *
   * If the value changes, the workflow will react through changing it's current
   * position of steps.
   */
  int depth = 0;

  /**
   * Stream of the [Response]s send by the workflow to it's consumer.
   */
  final StreamController<Response> responses;

  /**
   * The controllers [FlowContext].
   */
  late final FlowContext context;

  /**
   * To ensure that the [Stream] is a broadcast stream, the constructor is internal.
   */
  FlowContextController._internal(this.responses) {
    context = FlowContext(
      (value) => depth = value,
      () => depth,
      sink: responses.sink,
    );
  }

  /**
   * Constructs a [FlowContextController] with a
   * broadcast synchronized [StreamController].
   *
   * [onData] is the listener that gets triggered whenever a [Response] is send into
   * the [FlowContext].
   */
  factory FlowContextController.observed(void Function(Response)? onData) {
    final StreamController<Response> controller = StreamController.broadcast(
      sync: true,
    );
    if (onData != null) {
      controller.stream.listen(onData);
    }
    return FlowContextController._internal(controller);
  }

  /**
   * Closes the workflow and it's [FlowContextController].
   *
   * The [FlowContextController] shouldn't be used after this function were called.
   */
  Future<Response> close() async {
    await responses.close();
    depth = 0;
    return responses.stream.lastWhere(
      (_) => true,
      orElse: () => const Response(),
    );
  }
}

/**
 * A [FlowContext] holds the information for the package's user to work with the
 * workflow's information without modifying the workflow while it's running.
 */
final class FlowContext {
  /**
   * Sets the Context's depth. Mapped to it's controller.
   */
  final void Function(int value) _setDepth;

  /**
   * Gets the Context's depth. Mapped to it's controller.
   */
  final int Function() _getDepth;

  /**
   * The [StreamSink] for all [Response]s,
   * that should be send to the user of the workflow.
   */
  final StreamSink<Response> sink;

  FlowContext(this._setDepth, this._getDepth, {required this.sink});

  /**
   * Escapes the current [Bubble].
   */
  void pop(final String message) {
    sink.add(Response(message, Level.error));
    _setDepth(_getDepth() - 1);
  }

  /**
   * Escapes the entire workflow.
   */
  void close(final String message) {
    sink.add(Response(message, Level.critical));
    _setDepth(0);
  }

  /**
   * Sends a [Response] to the consumer of the workflows communication ([onData]).
   */
  void send(final Response response) => sink.add(response);
}
