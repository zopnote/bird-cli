import 'dart:convert';

import 'package:stepped_cli/config.dart';
import 'package:stepped_cli/environment.dart';
import 'package:stepped_cli/response.dart';
import 'package:stepped_cli/step.dart';
import 'package:stepped_cli/steps.dart';

Future<void> main() async {
  Step? step = Chain(
    steps: [
      Runnable(
        (Environment environment) {
          return Response();
        },
        name: "Test atomic step.",
        description:
            "Runnable is an atomic step, that can be used with conditionals to ensure logic.",
      ),



      Chain(
        steps: [
          Conditional(
            condition: true,
            child: Shell(
              program: "cmake",
              arguments: ["--help"],
              name: 'test command configure step',
              description:
                  'shell is an configure step and will be transformed to an actual atomic runnable step',
            ),
          ),
        ],
      ),
    ],
  ).configure(Config());
  if (step is AtomicStep) {
    print(JsonEncoder.withIndent("   ").convert(step.toJson()));
  }
  while ((step as AtomicStep) != null) {
    await step.execute(const Environment());
    if (step.next == null) break;
    step = step.next;
  }
}
