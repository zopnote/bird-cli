import 'dart:async';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

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
   * Function that will be executed when the process' finishes.
   */
  final FutureOr<void> Function(int exitCode)? onFinish;

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
  const Shell(
      {required this.program,
      required this.arguments,
      this.options = const ProcessInterfaceOptions(),
      this.onStdout,
      this.onStderr,
      this.onFinish});

  @override
  Step configure() => Runnable(() async {
        final ProcessInterface process = await ProcessInterface.fromEnvironment(
            program, arguments,
            options: options,
            onStdout: (c) => onStdout?.call(c),
            onStderr: (c) => onStderr?.call(c));
        final int exitCode = await process.waitForExit();
        onFinish?.call(exitCode);
      });
}
