import 'dart:async';
import 'dart:io';

import 'package:bird_cli/response.dart';

import 'flag.dart';

final class Command {
  const Command({
    required this.use,
    required this.description,
    required this.run,
    this.hidden = false,
    this.flags = const [],
    this.subCommands = const [],
  });

  /// The use name of the command that has to be
  final String use;
  final String description;
  final bool hidden;
  final List<Flag> flags;
  final List<Command> subCommands;
  final CommandRunner run;

  /**
   * Runs a root command and applies the parsed arguments as
   * subcommands or flags to it. At the end one [Command].run() function is
   * determined and will be executed.
   */
  FutureOr<int> execute(
    List<String> rawArguments, {
    List<Flag> globalFlags = const [],
  }) async {
    Command targetCommand = this;
    String argument = "";

    for (String rawArgument in rawArguments) {
      if (rawArgument.startsWith("--")) {
        continue;
      }
      bool matchesSubCommand = false;
      for (Command subCommand in targetCommand.subCommands) {
        if (rawArgument == subCommand.use) {
          targetCommand = subCommand;
          matchesSubCommand = true;
          break;
        }
      }
      if (!matchesSubCommand) {
        argument = rawArgument;
        break;
      }
    }

    String mergeString = "";
    for (int i = 0; i < rawArguments.length - 1; i++) {
      if (rawArguments[i].contains("\"")) {
        mergeString = rawArguments[i].replaceAll("\"", "");
      }
      if ()
    }
    if (mergeString.isNotEmpty) {
      stderr.writeln("Do not put \" characters into a space seperated string.");
    }
    final List<Flag> flags = const [];
    for (String flagArgument
        in rawArguments
            .where((rawArgument) => rawArgument.startsWith("--"))
            .map((rawArgument) => rawArgument.substring(2))) {
      final Flag? flag = this.flags.firstWhereOrNull(
        (flag) => flag.name.contains(flagArgument.split("=").first)
      );


      if ((targetCommand.flags.map((flag) => flag.name).toList()
            ..addAll(globalFlags.map((flag) => flag.name)))
          .contains(flag.name)) {
        flags.add(flag);
      } else {
        stdout.writeln("${flag.name} is ignored in this context.");
      }
    }

    for (Flag flag
        in []
          ..addAll(globalFlags)
          ..addAll(targetCommand.flags)) {
      if (flag.value == "") continue;
      if (!flags.map((e) => e.name).contains(flag.name)) {
        flags.add(flag);
      }
    }

    Response response = await targetCommand.run(
      ExecutionContext(
        command: targetCommand,
        argument: argument,
        flags: flags,
      ),
    );
    if (response.syntax != null) {
      stdout.writeln(syntax(response.syntax!));
      if (globalFlags.isNotEmpty) {
        stdout.writeln(_flagSyntax(globalFlags, "Global"));
      }
    }

    if (response.error) {
      stderr.writeln(
        response.message.isNotEmpty
            ? "\nAn error occurred: ${response.message}"
            : "\nAn error occurred.",
      );
      return 1;
    }
    if (response.message.isNotEmpty) {
      stdout.writeln("\n${response.message}");
    }
    return 0;
  }
}

typedef CommandRunner = FutureOr<Response> Function(ExecutionContext data);

final class ExecutionContext {
  final Command command;
  final String argument;
  final List<Flag> flags;

  ExecutionContext({
    required this.command,
    required this.argument,
    required this.flags,
  });
}

/**
 * Formats a syntax message of a flag list.
 */
String _flagSyntax(List<Flag> flags, String prefix) {
  String syntax = "$prefix flags:";
  for (Flag flag in flags) {
    syntax = syntax + "\n--${flag.name}";
    final int space = 13 - flag.name.length;
    if (flag.description.isNotEmpty) {
      syntax = syntax + (" " * space) + "${flag.description}";
    }
    if (flag.value.isNotEmpty) {
      syntax = syntax + " (default: ${flag.value})";
    }
    if (flag.overview.isNotEmpty) {
      syntax = syntax + " (overview: ${flag.overview.toString()})";
    }
  }
  return syntax;
}

/**
 * Formats a syntax message as [String] of the command.
 */
String syntax(Command cmd) {
  String syntax = "${cmd.description}\n";
  if (cmd.subCommands.isNotEmpty) {
    syntax = syntax + "\nAvailable sub commands:\n";
    for (final Command sub in cmd.subCommands) {
      if (sub.hidden) continue;
      final int space = 20 - sub.use.length;
      syntax = syntax + sub.use + (" " * space) + sub.description + "\n";
    }
  }
  if (cmd.flags.isNotEmpty) {
    syntax = syntax + _flagSyntax(cmd.flags, "Avertable");
  }
  return syntax;
}

extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
