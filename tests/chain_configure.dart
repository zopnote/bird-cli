import 'package:stepped_cli/config.dart';
import 'package:stepped_cli/environment.dart';
import 'package:stepped_cli/response.dart';
import 'package:stepped_cli/step.dart';
import 'package:stepped_cli/steps.dart';

void main() {
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

  if (!(step is AtomicStep)) {
    throw Exception("Error, step isn't an atomic step");
  }
  while (step != null) {
    step = (step as AtomicStep).next!;
    print(step.toJson());
  }
}
