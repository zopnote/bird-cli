import 'dart:async';

import 'package:stepflow/common.dart';

Future<void> runWorkflow(Step step, [void Function(Response)? onData]) async {
  final FlowContext context = FlowContext.observed(onData ?? (_) {});
  Step? next = step;
  while (next != null) {
    print(next.runtimeType);
    next = await next.execute(context);
  }
}

/**
 *
 */
class FlowContext {
  final StreamController<Response> responses;
  int _depth = 0;
  int get depth => _depth;
  FlowContext(this.responses);
  factory FlowContext.observed(void Function(Response)? onData) {
    return FlowContext(StreamController.broadcast(sync: true));
  }
  void increaseDepth() => _depth++;
  void decreaseDepth() => _depth--;

  void pop(final String message) {
    responses.sink.add(Response(message, Level.error));
    _depth--;
  }

  Future<dynamic> addStream(Stream<Response> stream) =>
      responses.sink.addStream(stream);

  void send(final Response response) => responses.sink.add(response);

  Future<Response> close() async {
    await responses.close();
    return responses.stream.lastWhere(
      (_) => true,
      orElse: () => const Response(),
    );
  }
}
