import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:stepflow/common.dart';

final class Install extends ConfigureStep {
  /**
   * Path where files should be installed to relative to the environment root.
   * The path is seperated through items of the list.
   */
  final List<String> installPath;

  /**
   * The names of the directories that will
   * be installed with their name into the install location.
   */
  final List<String> directories;

  /**
   * The names of the files that will be installed with their full name
   * into the install location.
   */
  final List<String> files;

  /**
   * Path where the binaries are that should be copied to installPath.
   */
  final List<String> binariesPath;

  /**
   * File which contains these patterns will be excluded.
   * E. g. there are two files: test.exe & text.lib
   * With .lib the text.lib won't be installed.
   */
  final List<String> excludeFileWithPatterns;

  final String name;
  Install({
    required this.name,
    this.installPath = const [],
    this.binariesPath = const [],
    this.files = const [],
    this.directories = const [],
    this.excludeFileWithPatterns = const [],
  });

  void _forFile(File file) {
    final String fileName = path.basenameWithoutExtension(file.path);
    final String fileExtension = path.extension(file.path);
    if (!files.contains(fileName) ||
        excludeFileWithPatterns.contains(fileExtension)) {
      return;
    }
    final String fileInstallPath = path.join(
      path.joinAll(installPath),
      path.relative(file.path, from: path.joinAll(binariesPath)),
    );
    final fileInstallDirectory = Directory(path.dirname(fileInstallPath));
    if (!fileInstallDirectory.existsSync()) {
      fileInstallDirectory.createSync(recursive: true);
    }
    file.copySync(fileInstallPath);
  }

  void _forDirectory(Directory directory) {
    if (!directories.contains(path.basename(directory.path))) {
      return;
    }
    final files = directory
        .listSync(recursive: true)
        .where((entity) => (entity is File))
        .cast<File>();
    files.forEach((file) {
      final String fileInstallPath = path.join(
        path.joinAll(installPath),
        path.relative(directory.path, from: path.joinAll(binariesPath)),
        path.relative(file.path, from: directory.path),
      );
      final fileInstallDirectory = Directory(path.dirname(fileInstallPath));
      if (!fileInstallDirectory.existsSync()) {
        fileInstallDirectory.createSync(recursive: true);
      }
      file.copySync(fileInstallPath);
    });
  }

  @override
  Step configure() {
    return Runnable(name: name, (context) {
      try {
        final Directory workDirectory = Directory(path.joinAll(binariesPath));
        workDirectory.listSync().forEach((entity) {
          if (entity is File)
            _forFile(entity);
          else if (entity is Directory)
            _forDirectory(entity);
          else
            context.send(
              Response(
                "Only files and directories will be installed.",
                Level.verbose,
              ),
            );
        });
        return Response(
          "Installation complete successfully.",
          Level.verbose,
        );
      } catch (error) {
        return Response(error.toString(), Level.verbose);
      }
    });
  }
}
