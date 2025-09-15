import 'dart:async';
import 'dart:developer';

import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';

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
    if (ancestor != null) {
      postEvent("stepflow.tree", {"tree": ancestor!.toJson()});
      postEvent("stepflow.tree", {"tree": chain.toJson()});
    }
    final FlowContext context = FlowContext(
      responseSink: responses.sink,
      variables: const {},
    );

    AtomicStep currentStep = chain;
    while (true) {
      await currentStep.execute(context);
      if (currentStep.next == null) {
        break;
      }
      currentStep = currentStep.next!;
    }
    return responses.stream.last;
  }

  void listen(void Function(Response) listener) =>
      responses.stream.listen(listener);
}

class FlowContext {
  final StreamSink<Response> _responseSink;
  final Map<String, dynamic> variables;

  FlowContext({
    required StreamSink<Response> responseSink,
    required this.variables,
  }) : _responseSink = responseSink;

  operator [](String key) => variables[key];

  void send(final Response response) => _responseSink.add(response);
}
