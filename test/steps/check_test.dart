import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stepflow/cli/steps/check.dart';
import 'package:stepflow/common.dart';
import 'package:test/test.dart';

const successPattern = "TEST_CHECK_STEP_SUCCESS";
const failurePattern = "TEST_CHECK_STEP_FAILURE";

const checkStepName = "Test check step";
const checkStepDescription = "Part of isolated setup to unit test the step.";
const foundablePrograms = ["dart", "git"];
const unavailablePrograms = ["34hbr2asd", "sad3n43"];
final processablePrograms = [
  Directory.current.path + "/test/steps/check/testprogram",
];
final directories = [Directory.current.path + "/test/steps/check"];
const foundableInDirectoriesPrograms = ["testprogram"];

final onFailure = (FlowContext context, List<String> _) {
  context.send(
    const Response(message: failurePattern, level: ResponseLevel.status),
  );
};
final onSuccess = (FlowContext context) {
  context.send(
    const Response(message: successPattern, level: ResponseLevel.status),
  );
};

Future<void> runCheckTest({
  required List<String> programs,
  required List<String> directories,
  required bool searchCanStartProcesses,
  required bool expectedToFail,
}) async {
  final controller = StreamController<Response>();
  final context = FlowContext(responseSink: controller.sink, variables: {});
  String responseMessages = "";
  controller.stream.listen((r) => responseMessages += r.message);

  final checkStep = Check(
    name: checkStepName,
    description: checkStepDescription,
    programs: programs,
    searchCanStartProcesses: searchCanStartProcesses,
    directories: directories,
    onFailure: onFailure,
    onSuccess: onSuccess,
  );
  final JsonEncoder encoder = JsonEncoder.withIndent("   ");
  printOnFailure(encoder.convert(checkStep.toJson()));
  await checkStep.execute(context);
  await controller.close();

  expect(
    responseMessages.contains(expectedToFail ? failurePattern : successPattern),
    true,
    reason:
        "Expected ${expectedToFail ? 'failure' : 'success'} but got: $responseMessages",
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
    Process.runSync("dart", [
      "compile",
      "exe",
      "testprogram.dart",
      "-o", testprogram
    ], workingDirectory: assetDirectory);
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
