
import 'dart:io';
import 'package:stepflow/cli.dart' show Shell;
import 'package:stepflow/common.dart';

class Test extends ConfigureStep {
  const Test();
  @override
  Step configure() {
    return Chain.builder((index) {
      if (index == 0) {
        return Chain(
          steps: [
            Shell(
              name: "Gets the version of Dart SDK",
              program: "dart",
              arguments: ["--version"],
              onStdout: (chars, _) {
                stdout.add(chars);
              }
            ),
          ],
        );
      }
      return Runnable(name: "Print out hello world", (context) {
        print("Hello world");
      });
    }, length: 5);
  }
}

Future<void> main() async {
  await runWorkflow(
   const Test(),
  );
}
