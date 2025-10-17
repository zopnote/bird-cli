
import 'package:stepflow/common.dart';

Future<void> main() async {
  await runWorkflow(
    Chain.builder((index) {
      return Runnable((context) {
        print("Hello world");
      }, name: "Says hello");
    }, length: 5),
  );
}
