import 'package:stepflow/cli.dart';

Future<void> main(List<String> rawArgs) => runCommand(
  Command(
    use: "my_cli",
    description: "Just a short cli example",
    hidden: true,
    inheritFlags: false,
    flags: [
      BoolFlag(name: "smile", value: false)
    ],
    run: (info) {
      if (info.getFlag("smile").value) {
        return Response(":)", Level.status);
      }
      return Response(info.formatSyntax(), Level.status);
    },
    subCommands: [
      Command(
        use: "greet",
        description: "Greets the entire world.",
        run: (info) {
          return Response(
            "Hello world!" + (info.getFlag("smile").value ? " :)" : ""),
          );
        },
      ),
    ],
  ),
  rawArgs,
);
