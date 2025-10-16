import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/common.dart';

final String executableExtension = Platform.isWindows ? ".exe" : "";
final List<String> _pathEntries =
    Platform.environment["PATH"]?.split(Platform.isWindows ? ";" : ":") ?? [];

/**
 * Ensures the availability of the received programs.
 * It searches in the file system, the systems path variable and in the command line.
 */
final class Check extends ConfigureStep {
  /// Name (without extension) of the executables or links you are searching for.
  final List<String> programs;

  /// Directories where the executables could be found.
  final List<String> directories;

  /// Gets triggered if one or multiple programs were not found.
  final void Function(FlowContext context, List<String> notFound)? onFailure;

  /// Gets triggered if all programs were found.
  final void Function(FlowContext context)? onSuccess;

  /// Decide if the search procedure can start processes to
  /// found programs if they aren't in the systems path.
  final bool searchCanStartProcesses;

  const Check({
    required super.name,
    required super.description,
    required this.programs,
    this.directories = const [],
    this.onFailure,
    this.onSuccess,
    this.searchCanStartProcesses = false,
  });

  /**
   * Looks for the programs in the systems path variable.
   * If there isn't a match, it will be tried to start up a
   * process of the program in the command line if [canStartProcesses] is set to false.
   *
   * Ignores all programs in [skippable].
   * Returns a [List] with programs that were not found.
   */
  static List<String> search(
    List<String> programs,
    List<String> directories, [
    bool canStartProcesses = false,
  ]) {
    final List<String> notAvailable = [];
    for (final String program in programs) {
      bool found = false;

      for (final String directory in directories) {
        final File programFile = File(
          path.join(directory, program + executableExtension),
        );
        if (programFile.existsSync()) {
          found = true;
          break;
        }
      }

      if (found) continue;

      for (final String pathEntry in _pathEntries) {
        final File programFile = File(
          path.join(pathEntry, program + executableExtension),
        );
        found = programFile.existsSync();
        if (found) break;
      }

      if (found) continue;
      if (!canStartProcesses) {
        notAvailable.add(program);
        continue;
      }

      final ProcessResult result = Process.runSync(
        path.basename(program),
        [],
        workingDirectory: path.dirname(program),
        runInShell: true,
        includeParentEnvironment: true,
      );
      if (result.stderr.isEmpty) continue;
      notAvailable.add(program);
    }
    return notAvailable;
  }

  @override
  Step configure() => Runnable(name: name, description: description, (context) {
    if (programs.isEmpty) {
      return Response(
        message: "No programs received to look out for.",
        level: ResponseLevel.status,
      );
    }

    final List<String> notAvailable = search(
      programs,
      directories,
      searchCanStartProcesses,
    );

    if (notAvailable.isEmpty) {
      if (onSuccess != null) {
        onSuccess!(context);
      }
      return Response(
        message: "All programs were found without issues.",
        level: ResponseLevel.status,
      );
    } else {
      if (onFailure != null) {
        onFailure!(context, notAvailable);
      }
      return Response(
        message:
            "Not all programs were found. Missing are ${notAvailable.join(", ")}.",
      );
    }
  });

  @override
  Map<String, dynamic> toJson() =>
      super.toJson().remove("subordinate")..addAll({
        "programs_required": programs,
        "directories_to_search_inside": directories,
        "can_search_start_processes": searchCanStartProcesses,
      });
}
