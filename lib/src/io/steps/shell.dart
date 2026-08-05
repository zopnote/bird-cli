import 'dart:async';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

final class ListBuilder {
  factory ListBuilder.plain(List<String> list) {
    return ListBuilder._internal(list);
  }

  ListBuilder._internal([List<String>? list]) : _arguments = list ?? List.empty(growable: true);

  factory ListBuilder() => ListBuilder._internal();

  final List<String> _arguments;

  String operator [](int i) {
    return _arguments[i];
  }

  void addIf(bool condition, String value) {
    if (condition) _arguments.add(value);
  }

  void addNotNull(String? value) {
    if (value != null) _arguments.add(value);
  }

  void add(String value) =>
      _arguments.add(value);


  List<String> toList() => _arguments;
}

/**
 * Executes a program in the systems command line.
 */
final class Shell extends ConfigureStep {
  /**
   * The name of the executable that should be invoked.
   * Can be relative to the [workingDirectory] or available in the systems
   * path variable.
   */
  final String program;

  /**
   * Function that will be executed every time the process' stdout receives text.
   */
  final FutureOr<void> Function(List<int> chars)? onStdout;

  /**
   * Function that will be executed every time the process' stderr receives text.
   */
  final FutureOr<void> Function(List<int> chars)? onStderr;

  /**
   * The command line arguments that should be applied to the command invocation.
   */
  final List<String> arguments;

  /**
   * Configuration options for the process invocation.
   */
  final ProcessInterfaceOptions options;

  /**
   * Default const constructor.
   *
   * The default values of [runAsAdministrator] and [runInShell] are [false].
   */
  const Shell({
    required this.program,
    required this.arguments,
    this.options = const ProcessInterfaceOptions(),
    this.onStdout,
    this.onStderr,
  });

  @override
  Step configure() => Runnable(() async {
        final ProcessInterface process = await ProcessInterface.fromEnvironment(
            program, arguments,
            options: options,
            onStdout: (c) => onStdout?.call(c),
            onStderr: (c) => onStderr?.call(c));
        await process.waitForExit();
      });
}
