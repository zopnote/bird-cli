import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/common.dart';

final String _executableExtension = Platform.isWindows ? ".exe" : "";
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
  final void Function(List<String> notFound)? onFailure;

  /// Gets triggered if all programs were found.
  final void Function(void)? onSuccess;

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

  /// Returns a List with all links and files in the given directories.
  static List<String> listContentOf(List<String> directories) {
    final List<String> localAvailable = [];
    for (int i = 0; i < directories.length; i++) {
      for (final entity in Directory(directories[i]).listSync()) {
        if ([
          FileSystemEntityType.file,
          FileSystemEntityType.link,
        ].contains(entity.statSync().type))
          continue;
        localAvailable.add(path.basename(entity.path));
        break;
      }
    }
    return localAvailable;
  }

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
    List<String> skippable, [
    bool canStartProcesses = false,
  ]) {
    final List<String> notAvailable = [];
    for (final String program in programs) {
      if (skippable.contains(program)) continue;
      bool found = false;
      for (final String pathEntry in _pathEntries) {
        final File programFile = File(
          path.join(pathEntry, program + _executableExtension),
        );
        if (found = programFile.existsSync()) break;
      }
      if (found || !canStartProcesses) continue;

      final result = Process.runSync(
        program,
        [],
        runInShell: true,
        includeParentEnvironment: true,
      );
      if (result.exitCode == 0) continue;
      notAvailable.add(program);
    }
    return notAvailable;
  }

  @override
  Step configure() => Runnable(name: name, description: description, (_) {
    if (programs.isEmpty) {
      return Response(
        message: "No programs received to look out for.",
        level: ResponseLevel.status,
      );
    }

    final List<String> notAvailable = search(
      programs,
      listContentOf(directories),
      searchCanStartProcesses,
    );

    return Response(
      message: notAvailable.isEmpty
          ? "All programs were found."
          : "The following programs aren't available: ${notAvailable.join(", ")}.",
      level: notAvailable.isEmpty ? ResponseLevel.status : ResponseLevel.error,
    );
  });

  @override
  Map<String, dynamic> toJson() =>
      {"requirements": programs, "directories": directories}
        ..addAll(super.toJson());
}
