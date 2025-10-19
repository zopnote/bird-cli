import 'package:stepflow/cli.dart';
import 'package:stepflow/common.dart';

String message = "";

void main(List<String> args) => Command(
  use: "example_cli",
  description:
      "Example arguments and flags to show off the structure of the cli tooling.",
  run: (context) {x
    return Response();
  },
  flags: [
    BoolFlag(name: "", value: false)
  ]
).execute(args, globalFlags: [BoolFlag(name: "smile", value: false)]);
