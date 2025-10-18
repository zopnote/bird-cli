import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/cli.dart';

final outputDirectory = Directory(path.join(Directory.current.path, "test", "install", "output"));
final inputDirectory = Directory(path.join(Directory.current.path, "test", "install", "input"));

int index = 0;
Future<void> runInstallTest({
  required List<String> directories,
  required List<String> files,
  required List<String> binariesPath,
  required List<String> excludeFilesWithPatterns
}) {

  final Install installTestStep = Install(
    name: "Tests the install step in isolated environment",
    installPath: [path.join(outputDirectory.path, index.toString())],
    binariesPath: binariesPath,
    directories: directories,
    excludeFileWithPatterns: excludeFilesWithPatterns,
    files: files
  );

  index++;
}



Future<void> main() async {
  for (FileSystemEntity entity in outputDirectory.listSync()) {
    if (entity is File) {
      entity.deleteSync();
      continue;
    }
    entity.deleteSync(recursive: true);
  }

}