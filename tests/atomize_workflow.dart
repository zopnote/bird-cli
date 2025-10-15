import 'dart:convert';

import 'package:stepflow/cli.dart';
import 'package:stepflow/common.dart';

class AtomizeWorkflowTestStep extends ConfigureStep {
  const AtomizeWorkflowTestStep()
      : super(
    name: "atomize_workflow_test_step",
    description:
    "Step to use in the unit test to ensure the atomization of a workflow.",
  );
  @override
  Step configure() {
    String sdkVersion = "";
    return Chain(
      steps: [
        Check(
          name: "SDK availability",
          description: "Ensures a development kit of Dart in reach.",
          programs: ["dart"],
        ),
        Shell(
          name: "SDK version",
          description: "Retrieves the version of the installed SDK.",
          program: "dart",
          arguments: ["--version"],
          onStdout: (stdout, context) async {
            context.send(
              Response(
                message: "Wait for a second.",
                level: ResponseLevel.status,
              ),
            );
            await Future.delayed(Duration(seconds: 1));
            sdkVersion += String.fromCharCodes(stdout);
          },
        ),
        Runnable(
          name: "Broadcast SDK version",
          description: "Response with the Dart SDKs version.",
              (context) {
            return Response(
              message: "The SDKs version is ${sdkVersion.split(" ")[3]}!",
            );
          },
        ),
      ],
    );
  }
}


Future<void> main() async {
  final Workflow workflow = Workflow.from(const AtomizeWorkflowTestStep());
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  print(
    "Not configured: " +
        encoder.convert(const AtomizeWorkflowTestStep().toJson()),
  );
  print("\nAtomized: " + encoder.convert(workflow.chain.toJson()));
}