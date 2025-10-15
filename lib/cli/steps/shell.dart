import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/common.dart';
import 'package:uuid/uuid.dart';

/**
 * Executes a program in the systems command line.
 */
final class Shell extends ConfigureStep {
  /// Directory where the command line will be started from.
  final String? workingDirectory;

  /// If the program should be ran with elevated privileges.
  final bool runAsAdministrator;

  /// If the program should be run in the systems command shell.
  final bool runInShell;

  /**
   * The name of the executable that should be invoked.
   * Can be relative to the [workingDirectory] or available in the systems
   * path variable.
   */
  final String program;

  /// The command line arguments that should be applied to the command invocation.
  final List<String> arguments;

  /// Function that will be executed every time the process' stdout receives text.
  final FutureOr<void> Function(List<int> chars, FlowContext context)? onStdout;

  /// Function that will be executed every time the process' stderr receives text.
  final FutureOr<void> Function(List<int> chars, FlowContext context)? onStderr;

  const Shell({
    required super.name,
    required super.description,
    required this.program,
    required this.arguments,
    this.onStdout,
    this.onStderr,
    this.runAsAdministrator = false,
    this.runInShell = false,
    this.workingDirectory,
  });

  /// UUID for the placeholder file on windows.
  final Uuid uuid = const Uuid();
  File get _processFile => File(path.join(workingDirectory ?? "./", ".$uuid"));

  String getProgram() {
    if (runAsAdministrator) {
      return Platform.isWindows ? "powershell.exe" : "sudo";
    }
    return program;
  }

  /// On windows the powershell is required to acquire elevated privileges.
  List<String> getArguments() {
    if (runAsAdministrator) {
      return Platform.isWindows
          ? [
              "-Command",
              """
              # Set variables
              \$targetFolder = "${workingDirectory ?? "./"}"
              \$command = "$program"
              \$arguments = "${this.arguments.join(" ")}"
              
              # Relaunch as administrator
              Start-Process powershell -Verb runAs -wait -ArgumentList @(
                  "-NoProfile",
                  "-ExecutionPolicy Bypass",
                  "-Command `"Set-Location -Path '\$targetFolder'; & '\$command' \$arguments`""
              )
              
              New-Item -ItemType File -Path "${_processFile.path}"
              """,
            ]
          : [this.program] + this.arguments;
    }
    return this.arguments;
  }

  /**
   * It is necessary to detect the creation of a placeholder
   * file, to wait for the Powershell process to finish.
   */
  Future<void> _windowsWaitForPowershell() {
    final Completer completer = Completer();
    late final void Function() check;
    check = () {
      if (_processFile.existsSync()) {
        _processFile.deleteSync();
        completer.complete();
      }
      Timer(const Duration(seconds: 1), check);
    };
    check();
    return completer.future;
  }

  Future<Process> getProcess() => Process.start(
    getProgram(),
    getArguments(),
    workingDirectory: workingDirectory,
    environment: {},
    includeParentEnvironment: true,
    mode: ProcessStartMode.normal,
    runInShell: runInShell,
  );

  @override
  Step configure() => Runnable(name: name, description: description, (
    context,
  ) async {
    final process = await getProcess();

    final List<Future<void>> futures = [];
    process.stdout.listen((chars) {
      if (onStdout != null) {
        futures.add(Future.value(onStdout!(chars, context)));
      }
    });

    String fullStderr = "";
    process.stderr.listen((chars) {
      if (onStderr != null) {
        futures.add(Future.value(onStderr!(chars, context)));
      }
      fullStderr += "\n${String.fromCharCodes(chars)}";
    });

    await process.exitCode;
    await Future.wait(futures);

    if (runAsAdministrator && Platform.isWindows) {
      await _windowsWaitForPowershell();
    }

    if (fullStderr.isNotEmpty) {
      return Response(message: "An error occurred in the process: $fullStderr");
    }
    return Response(
      message: "Shell step executed without any issues.",
      level: ResponseLevel.status,
    );
  });

  @override
  Map<String, dynamic> toJson() => {
    "name": name,
    "description": description,
    "run_as_administrator": runAsAdministrator,
    "run_in_shell": runInShell,
    if (workingDirectory != null) "working_directory": workingDirectory,
    "program": program,
    "arguments": arguments,
  };
}
