import 'dart:async';
import 'dart:io';

import 'package:bird_cli/response.dart';

import 'flag.dart';

final class Command {
  Command({
    required this.use,
    required this.description,
    required this.run,
    this.inheritFlags = false,
    this.hidden = false,
    this.flags = const [],
    this.subCommands = const [],
  });

  /// The use name of the command that has to be
  final String use;
  final String description;
  final bool hidden;
  List<Flag> flags;
  final bool inheritFlags;
  final List<Command> subCommands;
  final FutureOr<Response> Function(ExecutionContext context) run;

  /**
   * Runs a root command and applies the parsed arguments as
   * subcommands or flags to it. At the end one [Command].run() function is
   * determined and will be executed.
   */
  FutureOr<int> execute(
    List<String> rawArguments, {
    List<Flag> globalFlags = const [],
  }) async {
    Command command = this;
    List<Flag> flags = command.flags;
    String argument = "";

    final List<String> mergedArguments = [];
    String mergeableArgument = "";
    bool isOpen = false;
    for (final String rawArgument in rawArguments) {
      mergeableArgument += mergeableArgument.isEmpty
          ? rawArgument
          : " $rawArgument";
      for (int k = 0; k < rawArgument.length - 1; k++) {
        final bool isIgnorable = k > 0
            ? rawArgument[k - 1].contains("\\")
            : false;
        isOpen = (rawArgument[k].contains("\"") && !isIgnorable)
            ? !isOpen
            : isOpen;
      }
      if (!isOpen) {
        mergedArguments.add(mergeableArgument);
        mergeableArgument = "";
      }
    }

    for (String mergedArgument in mergedArguments) {
      if (mergedArgument.startsWith("--")) {
        continue;
      }
      bool isSubCommand = false;
      for (Command subCommand in command.subCommands) {
        if (mergedArgument == subCommand.use) {
          flags = subCommand.inheritFlags
              ? subCommand.flags += flags
              : subCommand.flags;
          command = subCommand;
          isSubCommand = true;
          break;
        }
      }
      if (!isSubCommand) {
        argument = mergedArgument;
        break;
      }
    }

    final Iterable<String> flagArguments = mergedArguments
        .where((rawArgument) => rawArgument.startsWith("--"))
        .map((rawArgument) => rawArgument.substring(2));

    flags += globalFlags;
    for (final String flagArgument in flagArguments) {
      final List<String> parts = flagArgument.split("=");
      final String flagName = parts.first;
      String flagValue = "";
      if (parts.length == 1) {
        flagValue = "true";
      } else {
        flagValue = flagArgument.substring(flagArgument.indexOf("=") + 1);
      }
      final Flag? flag = flags._firstWhereOrNull(
        (flag) => flag.name == flagName,
      );
      if (flag == null) {
        stdout.writeln("${flagName} is ignored in this context.");
        continue;
      }
      flag.setParsed(flagValue);
    }

    final ExecutionContext context = ExecutionContext(
      command: command,
      argument: argument,
      flags: flags,
    );
    Response? response;
    try {
      response = await command.run(context);
    } catch (e) {
      stderr.writeln(e);
    }

    if (response?.message.isNotEmpty ?? false) {
      stdout.writeln("\n${response!.message}");
    }
    if (response?.isError ?? true) {
      stderr.writeln("An error occurred.");
      return 1;
    }
    return 0;
  }

  String syntaxMessage({final bool addFlags = true}) {
    String syntax = "$description\n";
    if (subCommands.isNotEmpty) {
      syntax = syntax + "\nAvailable sub commands:\n";
      for (final Command subCommand in subCommands) {
        if (subCommand.hidden) continue;
        final int space = 20 - subCommand.use.length;
        syntax = syntax + subCommand.use + (" " * space) + subCommand.description + "\n";
      }
    }
    if (flags.isNotEmpty && addFlags) {
      syntax += "\nCommand avertable flags:\n";
      for (final Flag flag in flags) {
        syntax += flag.syntaxString() + "\n";
      }
    }
    if (flags.isEmpty && subCommands.isEmpty && !addFlags) {
      syntax += "\n";
    }
    return syntax;
  }
}

final class ExecutionContext {
  final Command command;
  final String argument;
  final List<Flag> flags;

  ExecutionContext({
    required this.command,
    required this.argument,
    required this.flags,
  });

  String syntaxMessage() {
    String syntax = "";
    syntax += command.syntaxMessage(addFlags: false) + "\n";
    syntax += "Flags:\n";
    for (final Flag flag in flags) {
      syntax += flag.syntaxString() + "\n";
    }
    return syntax;
  }

  Flag<T> getFlag<T>(String name) => getFlagOfList<T>(flags, name);

  static Flag<T> getFlagOfList<T>(final List<Flag> flags, final String name) {
    for (final Flag flag in flags) {
      if (flag.name == name) {
        return flag as Flag<T>;
      }
    }
    throw Exception(
      "There isn't a flag found with the name \"$name\" in the given list.",
    );
  }

  Response response({
    final String message = "",
    final bool syntax = false,
    final bool isError = false,
  }) {
    return Response(
      message: (syntax ? syntaxMessage() : "") + "$message",
      isError: isError
    );
  }
}

extension IterableExtensions<T> on Iterable<T> {
  T? _firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
