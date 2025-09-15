import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/runnable.dart';

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
  Install({
    required super.name,
    required super.description,
    this.installPath = const [],
    this.binariesPath = const [],
    this.files = const [],
    this.directories = const [],
    this.excludeFileWithPatterns = const [],
  });

  @override
  Step configure() {
    return Runnable(
      (environment) {
        try {
          final Directory workDirectory = Directory(path.joinAll(binariesPath));
          for (final entity in workDirectory.listSync()) {
            if (entity is File) {
              if (!files.contains(path.basenameWithoutExtension(entity.path))) {
                continue;
              }
              if (excludeFileWithPatterns.contains(
                path.extension(entity.path),
              )) {
                continue;
              }
              final String filePath = path.join(
                path.joinAll(installPath),
                path.relative(entity.path, from: path.joinAll(binariesPath)),
              );
              final fileDirectory = Directory(path.dirname(filePath));
              if (!fileDirectory.existsSync()) {
                fileDirectory.createSync(recursive: true);
              }
              entity.copySync(filePath);
            } else if (entity is Directory) {
              if (!directories.contains(
                path.basenameWithoutExtension(entity.path),
              )) {
                continue;
              }
              final files = entity
                  .listSync(recursive: true)
                  .where((e) => (e is File))
                  .cast<File>();
              for (final File file in files) {
                final String filePath = path.join(
                  path.joinAll(installPath),
                  path.relative(entity.path, from: path.joinAll(binariesPath)),
                  path.relative(file.path, from: entity.path),
                );
                final fileDirectory = Directory(path.dirname(filePath));
                if (!fileDirectory.existsSync()) {
                  fileDirectory.createSync(recursive: true);
                }
                file.copySync(filePath);
              }
            }
          }
          return Response();
        } catch (e) {
          return Response(isError: true, message: e.toString());
        }
      },
      name: name,
      description: description,
    );
  }
}
