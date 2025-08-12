import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:stepped_cli/config.dart';
import 'package:stepped_cli/environment.dart';
import 'package:stepped_cli/response.dart';
import 'package:stepped_cli/step.dart';
import 'package:path/path.dart' as path;

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
            ? io.Platform.isWindows
                  ? "powershell.exe"
                  : "sudo ${this.program}"
            : this.program;

        final String doneFilePath = path.join(
          workingDirectory ?? environment.workDirectoryPath,
          ".${name.toLowerCase().replaceAll(" ", "_")}-process-done",
        );
        final List<String> arguments;
        if (runAsAdministrator && io.Platform.isWindows) {
          arguments = [
            "-Command",
            """
        # Set variables
        \$targetFolder = "${workingDirectory ?? environment.workDirectoryPath}"
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
        final result = await io.Process.start(
          program,
          arguments,
          workingDirectory: workingDirectory ?? environment.workDirectoryPath,
          environment: {},
          includeParentEnvironment: true,
          mode: io.ProcessStartMode.normal,
          runInShell: false,
        );
        if (runAsAdministrator)
          await waitWhile(() {
            if (io.File(doneFilePath).existsSync()) {
              io.File(doneFilePath).deleteSync();
              return true;
            }
            return false;
          }, Duration(seconds: 1));

        if (spinner != null) {
          void Function(String) writeln = (data) {
            io.stdout.writeln(data.trim());
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

  /**
   * CHANGE BACK TO ALLOW ConfigureSteps in the configured chain there
   *         |    |     |      |
   *         V    V     V      V
   */
  @override
  Step configure(Config config) {
    if (_steps.isEmpty) return Skipped();
    int i = 0;
    final Step main = _steps[i];
    Step iterable = main;
    do {
      i++;
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
    } while (i < _steps.length - 1);
    return main;
  }
}

Future<void> main() async {
  final response = runToolchain(
    CompileMainAppEnvironment("Test", "path/to/dart_sdk/"),
    CompileMainAppToolchain(),
  );
}

class CompileMainAppEnvironment extends Environment {
  CompileMainAppEnvironment(super.name, this.dartSDKPath);
  final String dartSDKPath;
}

class CompileMainAppToolchain extends ConfigureStep {
  const CompileMainAppToolchain()
    : super(
        name: "Compile main app",
        description: "Toolchain for the compilation of the main application.",
      );

  @override
  Step configure(Config config) {
    return Chain(
      steps: [
        Conditional(
          condition: (() => true)(),
          child: Runnable(
            name: "Delete folders",
            description: "Deletion of special folders",
            (environment) => Response(message: "Hello world"),
          ),
        ),
        Chain(
          steps: [

          ],
        ),
        Shell(
          name: "Build",
          description: "Build toolchain system",
          program: "cmake",
          arguments: ["--build", "../", "--config", "debug"],
        ),
      ],
    );
  }
}

class ProcessSpinner {
  final List<String> _frames;

  Timer? _timer;
  int _counter = 0;

  ProcessSpinner({
    List<String> frames = const [
      '⠋',
      '⠙',
      '⠹',
      '⠸',
      '⠼',
      '⠴',
      '⠦',
      '⠧',
      '⠇',
      '⠏',
    ],
  }) : _frames = frames;

  void start([String message = '']) {
    _counter = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      io.stdout.write('\r$message ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  void stop([String message = ""]) {
    _timer?.cancel();
    io.stdout.write('\r');
    io.stdout.write(message + "\n");
  }
}

Future waitWhile(bool test(), [Duration pollInterval = Duration.zero]) {
  var completer = Completer();
  check() {
    if (!test()) {
      completer.complete();
    } else {
      Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}
