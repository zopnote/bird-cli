import 'package:stepflow/io.dart';

class PrintOutDartVersion extends ConfigureStep {
  const PrintOutDartVersion();

  @override
  Step configure() {
    String version = "";
    return Chain(
      steps: [
        Check(
          programs: ["dart"],
          searchCanStartProcesses: false,
          onFailure: (notFound) {
            print("The Dart SDK isn't available on this platform.");
          },
        ),
        Shell(
          program: "dart",
          arguments: ["--version"],
          onStdout: (chars) {
            version += String.fromCharCodes(chars);
          },
        ),
        Runnable(() {
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
