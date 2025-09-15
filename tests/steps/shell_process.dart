

import 'package:stepflow/steps/runnable.dart';
import 'package:stepflow/workflow.dart';

Future<void> main() async {
  final Workflow workflow = Workflow.from(
    Runnable((context) {

    }, name: "", description: ""),
  );
  await workflow.run();
}
