import 'dart:async';
import 'dart:io';

import 'package:stepflow/common.dart';
import 'package:stepflow/cli.dart';


/**
 * Represents a CLI command with optional subcommands and flags.
 */
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

  /// The command name used in CLI invocation.
  final String use;

  /// Short description of the command.
  final String description;

  /// Whether the command is hidden from help listings.
  final bool hidden;

  /// Flags available to the command.
  List<Flag> flags;

  /// Whether this command inherits flags from a parent.
  final bool inheritFlags;

  /// Subcommands under this command. */
  final List<Command> subCommands;

  /// Execution function invoked with the parsed context.
  final FutureOr<Response> Function(ExecutionContext context) run;

  /**
   * Executes the command with given arguments and global flags.
   *
   * @return 0 on success, 1 on failure.
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
    if (response?.level == Level.error) {
      stderr.writeln("An error occurred.");
      return 1;
    }
    return 0;
  }

  /// Returns a help message describing usage and available flags.
  String syntaxMessage({final bool addFlags = true}) {
    String syntax = "$description\n";
    if (subCommands.isNotEmpty) {
      syntax = syntax + "\nAvailable sub commands:\n";
      for (final Command subCommand in subCommands) {
        if (subCommand.hidden) continue;
        final int space = 20 - subCommand.use.length;
        syntax =
            syntax +
            subCommand.use +
            (" " * space) +
            subCommand.description +
            "\n";
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

  /// Returns a help message describing usage and available flags.
  String syntaxMessage() {
    String syntax = "";
    syntax += command.syntaxMessage(addFlags: false) + "\n";
    syntax += "Flags:\n";
    for (final Flag flag in flags) {
      syntax += flag.syntaxString() + "\n";
    }
    return syntax;
  }

  /**
   * Retrieves a flag by name and casts it to type T.
   *
   * Throws [Exception] if flag is not found.
   */
  Flag<T> getFlag<T>(String name) => getFlagOfList<T>(flags, name);

  /**
   * Retrieves a flag by name and casts it to type T.
   *
   * Throws [Exception] if flag is not found.
   */
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
      (syntax ? syntaxMessage() : "") + message,
      isError ? Level.error : Level.status,
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
