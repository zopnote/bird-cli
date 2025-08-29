import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/chain.dart';

import 'config.dart';

abstract class Environment {
  final Config config;
  final Map<String, dynamic> variables = const {};
  final List<Message> messages = const [];
  const Environment({required this.config});

  void onMessage(Message message) {}

  void onInit() {}

  FutureOr<void> dispose() {}

  @protected
  void addMessage(Message message) {
    if (messages.isNotEmpty) {
      if (messages.last.isOpen) {
        messages.last.close();
      }
    }
    messages.add(message);
    onMessage(message);
  }

  operator [](String key) => variables[key];
}



/**
 * Executes an workflow based on the entry step provided in this function.
 * [runFlow] configures the steps to atomic steps and then execute them chronologically.
 */
Future<Response> runFlow({required Step step, required Environment environment}) async {
  environment.onInit();

  while (!(step is AtomicStep)) {
    step = step.configure(environment.config);
    print("a");
  }
  AtomicStep atomic = step;

  Response response = Response(message: "Nothing was executed.");
  while (true) {
    response = await atomic.execute(environment);
    print("Execute ${atomic.name}");
    if (response.isError ||
        atomic.next == null) {
      break;
    }
    atomic = atomic.next!;
  }
  return response;
}


class Message {
  const Message(this.content);
  final String content;
  bool get isOpen => false;
  void open(IOSink sink) => sink.writeln(content);
  void close() {}
}
