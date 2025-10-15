
import 'package:stepflow/cli.dart';
import 'package:stepflow/common.dart';



class SDKInformationStep extends ConfigureStep {
  const SDKInformationStep()
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
              level: ResponseLevel.info
            );
          },
        ),
      ],
    );
  }
}

Future<void> main() async {
  final Workflow workflow = Workflow.from(const SDKInformationStep());
  workflow.listen((response) {
    if (response.level == ResponseLevel.info) {
      print(response.message);
    }
  });
  await workflow.run();
}
