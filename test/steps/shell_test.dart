import 'dart:io';
import 'package:test/test.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

void main() {
  group('Shell Step', () {
    test('Shell step respects workingDirectory', () async {
      final tempDir = Directory.systemTemp.createTempSync('stepflow_test');
      try {
        final testFile = File('${tempDir.path}/test_file.txt');
        testFile.writeAsStringSync('hello');

        // On Windows 'dir', on others 'ls'
        final win = Platform.isWindows;

        bool foundFile = false;
        final shell = Shell(
          program: win ? 'cmd' : 'ls',
          arguments: <String>[]..addAllIf(win, ['/c', 'dir', 'test_file.txt']),
          options: ProcessInterfaceOptions(
            workingDirectory: tempDir.path,
            runInShell: win,
          ),
          onStdout: (data) {
            print(String.fromCharCodes(data));
            if (String.fromCharCodes(data).contains('test_file.txt')) {
              foundFile = true;
            }
          },
        );

        await runWorkflow(shell);
        expect(foundFile, isTrue,
            reason: 'Should find the test file in the working directory');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Shell step can be part of a Chain', () async {
      int completedSteps = 0;
      final isWindows = Platform.isWindows;
      final program = isWindows ? 'cmd' : 'sh';
      final args = isWindows ? ['/c', 'echo', 'test'] : ['-c', 'echo test'];

      final workflow = Chain(steps: [
        Runnable(() {
          completedSteps++;
        }),
        Shell(
          program: program,
          arguments: args,
        ),
        Runnable(() {
          completedSteps++;
        }),
      ]);

      await runWorkflow(workflow);
      expect(completedSteps, 2);
    });
  });
}
