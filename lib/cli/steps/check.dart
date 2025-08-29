
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/config.dart';
import 'package:stepflow/response.dart';
import 'package:stepflow/steps/atomics.dart';
import 'package:stepflow/steps/runnable.dart';

final class Check extends ConfigureStep {
  final List<String> programs;

  Check({
    required super.name,
    required super.description,
    required this.programs,
  });

  @override
  Step configure(final Config config) => Runnable(
        (environment) {
      final String executableExtension = Platform.isWindows ? ".exe" : "";
      final List<String> pathVariableEntries =
          Platform.environment["PATH"]?.split(Platform.isWindows ? ";" : ":") ??
              [];

      if (programs.isEmpty) return Response();

      bool isAllFound = true;
      for (String program in programs) {
        bool found = false;
        for (String pathVariableEntry in pathVariableEntries) {
          final File programFile = File(
            path.join(pathVariableEntry, "$program$executableExtension"),
          );
          if (programFile.existsSync()) {
            found = true;
          }
        }

        if (!found) {
          final result = Process.runSync(
            program,
            [],
            runInShell: true,
            includeParentEnvironment: true,
          );
          if (result.exitCode == 0) {
            found = true;
          }
        }

        if (!found) {
          stderr.writeln("$program" + " ✖  ");
          isAllFound = false;
        }
      }
      return Response(isError: isAllFound);
    },
    name: name,
    description: description,
  );

  @override
  Map<String, dynamic> toJson() =>
      {"requirements": programs}..addAll(super.toJson());
}