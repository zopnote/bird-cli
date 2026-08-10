import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/**
 * Manages a command line process, initiated by this application.
 */

/**
 * Signature for callbacks that handle output (stdout/stderr) from a process.
 *
 * [chars] contains the raw byte data from the process output.
 */
typedef ProcessInterfaceOutputCallback = FutureOr<void> Function(
    List<int> chars);

/**
 * Configuration options for creating a [ProcessInterface].
 */
class ProcessInterfaceOptions {
  /**
   * Either start the process with elevated privileges or as default.
   *
   * Whenever errors occur, ensure your platform supports the behaviour of implementation the approach of
   * [ProcessInterface] takes.
   */
  final bool runAsAdministrator;

  final Map<String, String> environment;

  /**
   * If the program should be run in the systems command shell.
   */
  final bool runInShell;

  /**
   * The directory the process will be started in.
   */
  final String? workingDirectory;

  const ProcessInterfaceOptions(
      {this.runAsAdministrator = false,
      this.runInShell = false,
      this.workingDirectory,
      this.environment = const {}});
}

/**
 * Simple exception class, when the specified
 * working directory doesn't seem to exist.
 */
final class DirectoryNotExistsException implements Exception {
  static const String message = "The working directory doesn't exists.";
  final StackTrace stackTrace;
  const DirectoryNotExistsException(this.stackTrace);
  @override
  String toString() => message;
}

/**
 * A wrapper around [Process] that provides additional management capabilities.
 */
class ProcessInterface {
  /**
   * Path to the executable file that should be interfaced for.
   * Make sure the file exists; [ProcessInterface] doesn't
   * check for it explicitly in all constructors.
   *
   * Either an absolute path or relative to [ProcessInterfaceOptions.workingDirectory].
   */
  final String? executableFilePath;

  /**
   * The options used to start the process.
   */
  final ProcessInterfaceOptions? options;

  final Process _process;

  /**
   * Unique identifier for this process instance.
   */
  final Uuid uuid;

  /**
   * Indicates whether the process lifecycle is managed by this interface.
   */
  final bool isManaged;

  const ProcessInterface._internal(this._process, this.uuid,
      [this.options, this.executableFilePath, this.isManaged = false]);

  /**
   * Creates a [ProcessInterface] by searching for [programName] in the system PATH.
   *
   * - [programName]: The name of the executable to search for.
   * - [arguments]: Command line arguments for the invocation.
   * - [options]: Options for the process invocation.
   * - [onStdout] & [onStderr]: Optional callbacks to listen to output.
   *
   * Throws [ApplicationNotFoundException] if the program isn't found in PATH.
   */
  static Future<ProcessInterface> fromEnvironment(
      String programName, List<String> arguments,
      {final ProcessInterfaceOptions options = const ProcessInterfaceOptions(),
      final ProcessInterfaceOutputCallback? onStdout,
      final ProcessInterfaceOutputCallback? onStderr}) {
    final List<String> pathEntries =
        Platform.environment["PATH"]?.split(Platform.isWindows ? ";" : ":") ??
            [];
    final File? file = pathEntries
        .map((pathEntry) => File(
              path.join(
                pathEntry,
                programName + (Platform.isWindows ? ".exe" : ""),
              ),
            ))
        .firstWhereOrNull((file) => file.existsSync());
    return fromFilepath(file?.path ?? programName, arguments,
        options: options, onStdout: onStdout, onStderr: onStderr);
  }

  /**
   * Wraps an existing [Process] into a [ProcessInterface].
   *
   * This instance will be marked as [isManaged] = false.
   */
  static ProcessInterface fromProcess(final Process process,
          {final ProcessInterfaceOptions? options,
          final String? executableFilePath}) =>
      ProcessInterface._internal(
          process, const Uuid(), options, executableFilePath, false);

  /**
   * Creates a [ProcessInterface] by starting a process from a file path.
   *
   * - [path]: Absolute or relative path to the executable.
   * - [arguments]: Command line arguments for the invocation.
   * - [options]: Options for the process invocation.
   * - [onStdout] & [onStderr]: Optional callbacks to listen to output.
   *
   * Throws [ApplicationNotFoundException] if the file at [path] does not exist.
   */
  static Future<ProcessInterface> fromFilepath(
      String path, List<String> arguments,
      {final ProcessInterfaceOptions options = const ProcessInterfaceOptions(),
      final ProcessInterfaceOutputCallback? onStdout,
      final ProcessInterfaceOutputCallback? onStderr}) async {
    final Uuid uuid = const Uuid();

    if (options.runAsAdministrator) {
      if (Platform.isWindows) {
        path = "powershell.exe";
        arguments = [
          "-Command",
          """
              \$targetFolder = "${options.workingDirectory}"
              \$command = "$path"
              \$arguments = "${arguments.join(" ")}"
              
              # Relaunch as administrator
              Start-Process powershell -Verb runAs -wait -ArgumentList @(
                  "-NoProfile",
                  "-ExecutionPolicy Bypass",
                  "-Command `"Set-Location -Path '\$targetFolder'; & '\$command' \$arguments`""
              )
              
              New-Item -ItemType File -Path "${_validationFile(path, uuid).path}"
              """,
        ];
      } else {
        final String? user = Platform.environment['USER'];
        if (user != null && user.isNotEmpty && user != "root") {
          throw Exception(
              "The process needs root access to execute the desired commands. Ensure the permissions are provided.");
        }
      }
    }
    if (options.workingDirectory != null) {
      if (!Directory(options.workingDirectory!).existsSync()) {
        throw DirectoryNotExistsException(StackTrace.current);
      }
    }
    final Process process = await Process.start(path, arguments,
        workingDirectory: options.workingDirectory,
        environment: {"environment_stepflow": "1"}..addAll(options.environment),
        includeParentEnvironment: true,
        mode: ProcessStartMode.normal,
        runInShell: options.runInShell);

    if (onStdout != null) {
      process.stdout.listen((c) => onStdout(c));
    }
    if (onStderr != null) {
      process.stderr.listen((c) => onStderr(c));
    }

    return ProcessInterface._internal(process, uuid, options, path, true);
  }

  /**
   * Kills the underlying process.
   */
  void kill() => _process.kill();

  /**
   * Waits for the process to exit and returns the exit code.
   *
   * If the process was run as administrator on Windows, this method
   * implements a custom waiting mechanism using a validation file.
   *
   * Throws an [Exception] if the process is not managed.
   */
  Future<int> waitForExit() async {
    if (!isManaged) {
      throw Exception("Process isn't managed by ProcessInterface.");
    }
    if (options!.runAsAdministrator && Platform.isWindows) {
      await _waitForPowershell();
    }
    return _process.exitCode;
  }

  static File _validationFile(String executablePath, Uuid uuid) {
    return File(path.join(path.dirname(executablePath), ".$uuid"));
  }

  /**
   * It is necessary to detect the creation of a placeholder
   * file, to wait for the Powershell process to finish.
   *
   * Note, that this function only will work, when the process [isManaged].
   */
  Future<void> _waitForPowershell() {
    final Completer completer = Completer();
    late final void Function() check;
    check = () {
      if (_validationFile(executableFilePath!, uuid).existsSync()) {
        _validationFile(executableFilePath!, uuid).deleteSync();
        completer.complete();
      }
      Timer(const Duration(seconds: 1), check);
    };
    check();
    return completer.future;
  }
}

extension FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
