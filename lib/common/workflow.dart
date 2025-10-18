import 'dart:async';

import 'package:stepflow/common.dart';

Future<void> runWorkflow(Step step, [void Function(Response)? onData]) async {
  await step.execute(FlowContextController.observed(onData ?? (_) {}));
}

class FlowContextController {
  int depth = 0;
  final StreamController<Response> responses;
  late final FlowContext context;
  FlowContextController(this.responses) {
    context = FlowContext(
      (value) => depth = value,
      () => depth,
      sink: responses.sink,
    );
  }
  factory FlowContextController.observed(void Function(Response)? onData) {
    final StreamController<Response> controller = StreamController.broadcast(
      sync: true,
    );
    if (onData != null) {
      controller.stream.listen(onData);
    }
    return FlowContextController(controller);
  }

  Future<Response> close() async {
    await responses.close();
    return responses.stream.lastWhere(
      (_) => true,
      orElse: () => const Response(),
    );
  }
}

/**
 *
 */
class FlowContext {
  final void Function(int value) _setDepth;
  final int Function() _getDepth;
  final StreamSink<Response> sink;
  FlowContext(this._setDepth, this._getDepth, {required this.sink});

  void pop(final String message) {
    sink.add(Response(message, Level.error));
    _setDepth(_getDepth() - 1);
  }

  void close(final String message) {
    sink.add(Response(message, Level.critical));
    _setDepth(0);
  }

  void send(final Response response) => sink.add(response);
}
