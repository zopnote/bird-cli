import 'dart:async';
import 'dart:io';

import 'package:stepflow/common.dart';
import 'package:stepflow/cli.dart';

/**
 * Merges raw arguments into a list of arguments, based if the raw arguments
 * were enclosed by quotes.
 */
List<String> _mergeArguments(List<String> rawArguments) {
  final List<String> mergedArguments = [];
  String mergeableArgument = "";
  bool isOpen = false;
  for (final String rawArgument in rawArguments) {
    mergeableArgument += mergeableArgument.isEmpty
        ? rawArgument
        : " " + rawArgument;
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
  return mergedArguments;
}

/**
 * Parses the flags from the arguments and sets the flags of list their values.
 */
void _parseAndSetFlags(
  final Iterable<String> flagArgs,
  final Iterable<Flag> flags,
) {
  for (final String flagArg in flagArgs) {
    final List<String> parts = flagArg.split("=");
    final String flagName = parts.first;
    String flagValue = "";
    if (parts.length == 1) {
      flagValue = "true";
    } else {
      flagValue = flagArg.substring(flagArg.indexOf("=") + 1);
    }
    Flag? flag;
    for (final iteratedFlag in flags) {
      if (iteratedFlag.name == flagName) {
        flag = iteratedFlag;
      }
    }

    if (flag == null) {
      stdout.writeln("${flagName} is ignored in this context.");
      continue;
    }
    flag.setParsed(flagValue);
  }
}

/**
 * Executes a [Command] with the arguments of the command line.
 *
 * [globalFlags] are available for every command, regardless of [inheritFlags].
 */
Future<int> runCommand(
  Command command, [
  final List<String> rawArguments = const [],
  final List<Flag> globalFlags = const [],
]) async {
  List<Flag> flags = command.flags;
  String argument = "";

  final List<String> mergedArgs = _mergeArguments(rawArguments);
  final Iterable<String> plainArgs = mergedArgs.where(
    (raw) => !raw.startsWith("--"),
  );
  final Iterable<String> flagArgs = mergedArgs
      .where((raw) => raw.startsWith("--"))
      .map((raw) => raw.substring(2));

  /*
   * Figures out, which argument is a prompt for
   * a sub command or the actual argument for a command.
   */
  for (final String plainArg in plainArgs) {
    bool isSubCmd = false;
    for (final Command subCmd in command.subCommands) {
      if (plainArg == subCmd.use) {
        flags = subCmd.inheritFlags ? subCmd.flags += flags : subCmd.flags;
        command = subCmd;
        isSubCmd = true;
        break;
      }
    }
    if (!isSubCmd) {
      argument = plainArg;
      break;
    }
  }

  /*
   * Adds the global flags the current's command flags.
   * Set's then the [flags] list with the parsed values of [flagArgs].
   */
  flags += globalFlags;
  _parseAndSetFlags(flagArgs, flags);

  Response? response;
  try {
    response = await command.run(CommandInformation(command, argument, flags));
  } catch (e) {
    stderr.writeln(e);
  }

  final bool isError = response?.level == Level.error || response?.level == Level.critical;
  final String responseMsg = response?.message ?? "";

  if (isError) {
    stderr.writeln(
      "An error occurred" + (responseMsg.isEmpty ? "." : ": $responseMsg"),
    );
    return 1;
  }
  stdout.writeln(responseMsg);
  return 0;
}

/**
 * An action, callable by a user of the command line environment.
 *
 * Whenever building a cli application, you need an entry point for
 * the functionality your app provides. To make an app more complex and
 * flexible you can nest commands into superordinary ones.
 * Therefore you command tree is the interface for the user of your
 * application to prompt it's features.
 *
 * Stepflow provides you this structure by it's [Command].
 */
class Command {
  /**
   * Instantiates a command with the given values.
   * A command is an action, callable inside the cli.
   */
  Command({
    required this.use,
    required this.description,
    required this.run,
    this.inheritFlags = false,
    this.hidden = false,
    this.flags = const [],
    this.subCommands = const [],
  }) {
    if (use.length > 15) {
      throw Exception(
        "The usage of a command shouldn't be longer than 15 characters.",
      );
    }
  }

  /**
   * The name of this command.
   * Will be the usage in command line
   * and get's parsed of the arguments.
   * Maximal length of 15 characters.
   */
  final String use;

  /**
   * A short description of the command and
   * it's functionality for guidance and documentation.
   */
  final String description;

  /**
   * Whether the command is hidden from help listings.
   */
  final bool hidden;

  /**
   * Flags available to the command.
   */
  List<Flag> flags;

  /**
   * Whether this command inherits flags from a parent.
   */
  final bool inheritFlags;

  /**
   * Subcommands under this command.
   */
  final List<Command> subCommands;

  /**
   * Execution function invoked with the parsed context.
   */
  final FutureOr<Response> Function(CommandInformation context) run;

  /**
   * Returns a help message describing the
   * usage of the command and it's available flags.
   *
   * [withFlags] will decide if the flags should
   * also be printed into the syntax.
   */
  String formatSyntax({final bool withFlags = true}) {
    String syntax = "$description\n";
    if (subCommands.isNotEmpty) {
      syntax = syntax + "\nAvailable commands:\n";
      int useLongest = 0;
      subCommands.forEach((cmd) {
        if (cmd.use.length > useLongest) {
          useLongest = cmd.use.length;
        }
      });
      for (final Command subCommand in subCommands) {
        if (subCommand.hidden) continue;
        final int space = useLongest + 3 - subCommand.use.length;
        syntax =
            syntax +
            subCommand.use +
            (" " * space) +
            subCommand.description +
            "\n";
      }
    }
    if (flags.isNotEmpty && withFlags) {
      syntax += "\nCommand avertable flags:\n";
      for (final Flag flag in flags) {
        syntax += flag.syntaxString() + "\n";
      }
    }
    if (flags.isEmpty && subCommands.isEmpty && !withFlags) {
      syntax += "\n";
    }
    return syntax;
  }
}

/**
 * Information about the context of execution of a command line prompt.
 */
final class CommandInformation {
  final Command command;
  final String argument;
  final List<Flag> flags;

  CommandInformation(this.command, this.argument, this.flags);

  /**
   * Returns a help message describing usage and available flags.
   */
  String formatSyntax() {
    String syntax = "";
    syntax += command.formatSyntax(withFlags: false);
    if (flags.isNotEmpty) {
      syntax += "Flags:\n";
      for (final Flag flag in flags) {
        syntax += flag.syntaxString() + "\n";
      }
    }
    return syntax;
  }

  /**
   * Retrieves a flag by name and casts it to type T.
   *
   * Throws [Exception] if flag is not found.
   */
  Flag<T> getFlag<T>(String name) => _getFlagOfList<T>(flags, name);

  /**
   * Retrieves a flag by name and casts it to type T.
   *
   * Throws [Exception] if flag is not found.
   */
  static Flag<T> _getFlagOfList<T>(final List<Flag> flags, final String name) {
    for (final Flag flag in flags) {
      if (flag.name == name) {
        return flag as Flag<T>;
      }
    }
    throw Exception(
      "There isn't a flag found with the name \"$name\" in the given list.",
    );
  }
}
