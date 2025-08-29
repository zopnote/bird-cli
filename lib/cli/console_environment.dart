import 'dart:io';

import 'package:stepflow/environment.dart';

class ConsoleEnvironment extends Environment {
  const ConsoleEnvironment({required super.config});

  @override
  void onMessage(Message message) => message.open(stdout);

}