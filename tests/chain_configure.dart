import 'dart:async';

import 'package:stepflow/cli/console_environment.dart';
import 'package:stepflow/config.dart';
import 'package:stepflow/environment.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/chain.dart';
import 'package:stepflow/steps/runnable.dart';
import 'package:stepflow/cli/steps/shell.dart';

Future<void> main() async {
  runFlow(
    step: Chain(
      steps: [
        Runnable(
          (environment) {
            return const Response();
          },
          name: "Test atomic step.",
          description:
              "Runnable is an atomic step, that can be used with conditionals to ensure logic.",
        ),
        const Shell(
          name: 'test command configure step',
          description:
          'shell is an configure step and will be transformed to an actual atomic runnable step',
          program: "cmake",
          arguments: ["--help"]
        )
      ],
    ),
    environment: ConsoleEnvironment(config: Config()),
  );
}
