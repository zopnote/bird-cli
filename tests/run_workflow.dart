import 'dart:convert';
import 'dart:io';

import 'package:stepflow/cli/steps/shell.dart';
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/chain.dart';
import 'package:stepflow/steps/conditional.dart';
import 'package:stepflow/steps/runnable.dart';
import 'package:stepflow/workflow.dart';

class SimpleMessage extends ConfigureStep {
  final String message;
  const SimpleMessage(this.message)
    : super(name: "Write message", description: "Write a message to stdout.");

  @override
  Step configure() => Runnable(name: name, description: description, (context) {
    stdout.add(utf8.encode(message));
  });
}

Future<void> main() async {
  final response = await Workflow.from(
    Chain(
      steps: [
        Runnable(
          name: "Write message",
          description: "Writes a greetings message to the stdout.",
          (context) {
            final String name = Platform.localHostname;
            stdout.writeln(
              "Hey $name! \n"
              "How is it going?\n"
              "I know debugging at 3 a.m. is hard, "
              "consider to complete the task tomorrow.",
            );
          },
        ),
        const Shell(
          name: "Check Dart version",
          description:
              "Executed the dart version command to retrieve the sdk's version.",
          program: "dart",
          arguments: ["--version"],
        ),
        Conditional(
          condition: Platform.isWindows,
          child: const SimpleMessage("Hey Gates!"),
        ),
        Conditional(
          condition: Platform.isLinux,
          child: const SimpleMessage("Hey Torvalds!"),
        ),
        Conditional(
          condition: Platform.isMacOS,
          child: const SimpleMessage("Hey Jobs!"),
        ),
      ],
    ),
  ).run();
  print(response.message);
}
