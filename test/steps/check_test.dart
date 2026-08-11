import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:test/test.dart';

const checkStepName = "Test check step";
const checkStepDescription = "Part of isolated setup to unit test the step.";
const foundablePrograms = ["dart", "git"];
const unavailablePrograms = ["34hbr2asd", "sad3n43"];
final processablePrograms = [
  Directory.current.path + "/test/steps/check/testprogram",
];
final directories = [Directory.current.path + "/test/steps/check"];
const foundableInDirectoriesPrograms = ["testprogram"];

Future<void> runCheckTest({
  required List<String> programs,
  required List<String> directories,
  required bool searchCanStartProcesses,
  required bool expectedToFail,
}) async {
  late final bool value;
  final checkStep = Check(
      programs: programs,
      searchCanStartProcesses: searchCanStartProcesses,
      directories: directories,
      onFailure: (_) => value = false,
      onSuccess: () => value = true);
  await runWorkflow(checkStep);

  expect(
    value,
    !expectedToFail,
  );
}

void main() {
  final String assetDirectory = path.join(
    Directory.current.path,
    "test",
    "steps",
    "check",
  );
  final String testprogram = path.join(
    assetDirectory,
    "testprogram$executableExtension",
  );
  if (!File(testprogram).existsSync()) {
    print("Compiling $assetDirectory/testprogram.dart...");
    Process.runSync(
        "dart",
        [
          "compile",
          "exe",
          "testprogram.dart",
          "-o",
          testprogram,
        ],
        workingDirectory: assetDirectory);
  }

  group('CheckStep', () {
    test('finds available programs', () async {
      await runCheckTest(
        programs: foundablePrograms,
        directories: [],
        searchCanStartProcesses: false,
        expectedToFail: false,
      );
    });

    test('fails on unavailable programs', () async {
      await runCheckTest(
        programs: unavailablePrograms,
        directories: [],
        searchCanStartProcesses: false,
        expectedToFail: true,
      );
    });

    test('processes executable programs', () async {
      await runCheckTest(
        programs: processablePrograms,
        directories: [],
        searchCanStartProcesses: true,
        expectedToFail: false,
      );
    });

    test('finds programs in directories', () async {
      await runCheckTest(
        programs: foundableInDirectoriesPrograms,
        directories: directories,
        searchCanStartProcesses: false,
        expectedToFail: false,
      );
    });
  });
}
