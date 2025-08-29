import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/steps/runnable.dart';
import 'package:uuid/uuid.dart';

import 'package:stepflow/config.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/cli/spinner.dart';
import 'package:stepflow/steps/atomics.dart';

final class Shell extends ConfigureStep {
  final String? workingDirectory;
  final bool runAsAdministrator;
  final bool runInShell;
  final String program;
  final List<String> arguments;
  const Shell({
    required super.name,
    required super.description,
    required this.program,
    required this.arguments,
    this.runAsAdministrator = false,
    this.runInShell = false,
    this.workingDirectory,
  });

  final Uuid uuid = const Uuid();

  File get _processFile => File(path.join(workingDirectory ?? "./", ".$uuid"));

  String getProgram() {
    if (runAsAdministrator) {
      if (Platform.isWindows) {
        return "powershell.exe";
      }
      return "sudo";
    }
    return program;
  }

  List<String> getArguments() {
    if (runAsAdministrator) {
      if (Platform.isWindows) {
        return [
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
        ];
      }
      return [this.program] + this.arguments;
    }
    return this.arguments;
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
  Step configure(final Config config) =>
      Runnable(name: name, description: description, (environment) async {
        final result = await getProcess();

        if (runAsAdministrator && Platform.isWindows) {
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
          await completer.future;
        }
        return Response(isError: !(await result.stderr.isEmpty));
      });

  @override
  Map<String, dynamic> toJson() => {
    "program": program,
    "arguments": arguments,
    "run_as_administrator": runAsAdministrator,
    "run_in_shell": runInShell,
    if (workingDirectory != null) "working_directory": workingDirectory,
  }..addAll(super.toJson());
}
