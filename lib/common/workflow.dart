import 'dart:async';

import 'package:stepflow/common.dart';

class Workflow {
  final Step? ancestor;
  final AtomicStep chain;
  final StreamController<Response> responses = StreamController.broadcast(
    sync: true,
    onListen: () {},
    onCancel: () {},
  );

  Workflow({required this.chain, this.ancestor});

  factory Workflow.from(final Step step) {
    Step currentStep = step;
    while (true) {
      currentStep = currentStep.configure();
      if (currentStep is AtomicStep) {
        break;
      }
    }
    final AtomicStep atomicStep = currentStep;
    return Workflow(ancestor: step, chain: atomicStep);
  }

  /**
   * Executes an workflow based on the entry step provided in this function.
   * [run] configures the steps to atomic steps and then execute them chronologically.
   *
   * Returns the final and last Response.
   */
  FutureOr<Response> run() async {
    final FlowContext context = FlowContext(
      responseSink: responses.sink,
      variables: const {},
    );

    AtomicStep currentStep = chain;
    Response? response;
    while (true) {
      response = await currentStep.execute(context);
      if (response != null) {
        responses.sink.add(response);
      }
      if (currentStep.next == null) {
        break;
      }
      currentStep = currentStep.next!;
    }
    return response ?? const Response(message: "", level: ResponseLevel.status);
  }

  /**
   * Listen to the messages send by the workflow
   */
  void listen(void Function(Response) listener) =>
      responses.stream.listen(listener);
}

/**
 *
 */
class FlowContext {
  final StreamSink<Response> _responseSink;
  final Map<String, dynamic> variables;

  FlowContext({
    required StreamSink<Response> responseSink,
    required this.variables,
  }) : _responseSink = responseSink;

  operator [](String key) => variables[key];

  Future<dynamic> addStream(Stream<Response> stream) =>
      _responseSink.addStream(stream);
  void send(final Response response) => _responseSink.add(response);
}
