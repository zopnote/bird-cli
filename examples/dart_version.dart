import 'package:stepflow/cli.dart';
import 'package:stepflow/common.dart';

class PrintOutDartVersion extends ConfigureStep {
  const PrintOutDartVersion();
  @override
  Step configure() {
    String version = "";
    return Chain(
      steps: [
        Check(
          name: "Ensures the availability of the Dart SDK",
          programs: ["dart"],
          searchCanStartProcesses: false,
          onFailure: (context, notFound) {
            context.close("The Dart SDK isn't available on this platform.");
          },
        ),
        Shell(
          name: "Receives the Dart SDK's version",
          program: "dart",
          arguments: ["--version"],
          onStdout: (context, chars) {
            version += String.fromCharCodes(chars);
          },
        ),
        Runnable(name: "Prints out the version", (context) {
          print(
            "The version of the installed Dart SDK is " +
                version.split(" ")[3] +
                "!",
          );
        }),
      ],
    );
  }
}

Future<void> main() async {
  await runWorkflow(const PrintOutDartVersion());
}
