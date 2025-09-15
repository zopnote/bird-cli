import 'dart:convert';

import 'package:stepflow/cli/steps/shell.dart';
import 'package:stepflow/workflow.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/chain.dart';
import 'package:stepflow/steps/runnable.dart';

class AtomizeWorkflowTestStep extends ConfigureStep {
  const AtomizeWorkflowTestStep()
    : super(
        name: "atomize_workflow_test_step",
        description:
            "Step to use in the unit test to ensure the atomization of a workflow.",
      );
  @override
  Step configure() {
    return Chain(
      steps: [
        Runnable(
          (context) {
            return Response();
          },
          name: "Runnable",
          description: "Does nothing and executes the next.",
        ),
        const Shell(
          name: "Get Dart version",
          description: "Retrieves the version of the installed Dart SDK",
          program: "dart",
          arguments: ["version"],
        ),
      ],
    );
  }

}

Future<void> main() async {
  final Workflow workflow = Workflow.from(const AtomizeWorkflowTestStep());
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  print("Not configured: " + encoder.convert(const AtomizeWorkflowTestStep().toJson()));
  final response = await workflow.run();
  print("\nAtomized: " + encoder.convert(workflow.chain.toJson()));
  print(response.message);
}
