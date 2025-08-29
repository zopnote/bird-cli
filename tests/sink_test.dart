import 'package:stepflow/cli/console_environment.dart';
import 'package:stepflow/config.dart';
import 'package:stepflow/environment.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/chain.dart';
import 'package:stepflow/steps/runnable.dart';

void main() => runFlow(
  step: Chain(
    steps: [
      Runnable(name: "jnhijidgfjidjfg", description: "", (environment) {
        return Response(message: "");
      }),
      Runnable(name: "jnhijidgfjidjfg", description: "", (environment) {
        return Response(message: "");
      }),
      Runnable(name: "jnhijidgfjidjfg", description: "", (environment) {
        return Response(message: "");
      }),
      Runnable(name: "jnhijidgfjidjfg", description: "", (environment) {
        return Response(message: "");
      }),
      Runnable(name: "jnhijidgfjidjfg", description: "", (environment) {
        return Response(message: "");
      }),
    ],
  ),
  environment: ConsoleEnvironment(config: Config()),
);
