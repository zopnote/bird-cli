import 'dart:convert';
import 'dart:io';

import 'package:stepped_cli/config.dart';
import 'package:stepped_cli/environment.dart';
import 'package:stepped_cli/response.dart';
import 'package:stepped_cli/spinner.dart';
import 'package:stepped_cli/step.dart';

import 'package:path/path.dart' as path;

final class EnsurePrograms<T extends Environment> extends ConfigureStep {
  final List<String> programs;

  EnsurePrograms({
    required super.name,
    required super.description,
    required this.programs,
  });

  @override
  Step<Environment<Config>> configure(Config config) => Runnable(
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
}

final class Install<T extends Environment> extends ConfigureStep {
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
  Step<Environment<Config>> configure(Config config) {
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

class Conditional<T extends Step> extends ConfigureStep {
  final bool condition;
  final T child;
  Conditional({required this.condition, required this.child})
    : super(
        name: "Configure by condition",
        description:
            "Decide based on the condition if the returned Step is a SkippedStep or the child.",
      );

  @override
  Step configure(Config config) => condition ? child : Skipped();
}

final class Shell<T extends Environment> extends ConfigureStep<T> {
  final ProcessSpinner? spinner;
  final String? workingDirectory;
  final bool runAsAdministrator;
  final String program;
  final List<String> arguments;
  Shell({
    required super.name,
    required super.description,
    required this.program,
    required this.arguments,
    this.runAsAdministrator = false,
    this.workingDirectory,
    this.spinner,
  });

  @override
  Step<T> configure(Config config) =>
      Runnable(name: name, description: description, (environment) async {
        final String program = runAsAdministrator
            ? Platform.isWindows
                  ? "powershell.exe"
                  : "sudo ${this.program}"
            : this.program;

        final String doneFilePath = path.join(
          workingDirectory ?? "",
          ".${name.toLowerCase().replaceAll(" ", "_")}-process-done",
        );
        final List<String> arguments;
        if (runAsAdministrator && Platform.isWindows) {
          arguments = [
            "-Command",
            """
        # Set variables
        \$targetFolder = "${workingDirectory ?? ""}"
        \$command = "${program}"
        \$arguments = "${this.arguments.join(" ")}"
        
        # Relaunch as administrator
        Start-Process powershell -Verb runAs -wait -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy Bypass",
            "-Command `"Set-Location -Path '\$targetFolder'; & '\$command' \$arguments`""
        )
        
        New-Item -ItemType File -Path "$doneFilePath"
        """,
          ];
        } else {
          arguments = this.arguments;
        }
        final result = await Process.start(
          program,
          arguments,
          workingDirectory: workingDirectory ?? "",
          environment: {},
          includeParentEnvironment: true,
          mode: ProcessStartMode.normal,
          runInShell: false,
        );
        if (runAsAdministrator)
          await waitWhile(() {
            if (File(doneFilePath).existsSync()) {
              File(doneFilePath).deleteSync();
              return true;
            }
            return false;
          }, Duration(seconds: 1));

        if (spinner != null) {
          void Function(String) writeln = (data) {
            stdout.writeln(data.trim());
          };
          result.stdout.transform(utf8.decoder).listen(writeln);
          result.stderr.transform(utf8.decoder).listen(writeln);
        }
        return Response();
      });
}

final class Chain<T extends Environment> extends ConfigureStep<T> {
  final List<Step> _steps;

  Chain({required List<Step<T>> steps})
    : _steps = steps,
      super(
        name: "Execute chained steps",
        description:
            "A step containing chained subordinary steps. Steps may depend on each other.",
      );

  @override
  Step configure(Config config) {
    if (_steps.isEmpty) return Skipped();
    int i = 0;
    final Step main = _steps[i];
    Step iterable = main;
    for (i; i < _steps.length - 1; i++) {
      AtomicStep atomize(Step step) {
        while (!(step is AtomicStep)) {
          step = step.configure(config);
        }
        while ((step as AtomicStep).next != null) {
          step = step.next!;
        }
        return step;
      }

      final AtomicStep atomicIterable = atomize(iterable);
      atomicIterable.next = _steps[i] is AtomicStep
          ? _steps[i] as AtomicStep
          : atomize(_steps[i]);
      iterable = atomicIterable.next as Step;
    }
    return main;
  }
}