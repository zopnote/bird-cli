import 'config.dart';

class Environment<T extends Config> {
  /**
   * Name of the configuration to ensure no data conflicts between different build artifacts
   * a build configuration is used for. The name makes clear what is currently built with
   * the current configuration.
   */
  final String name;

  /**
   * How much spaces should appear for the stdout of this environment.
   * Provides structure in deeper executions.
   */
  final int prefixSpace;

  /**
   * Environment variables that get applied to process commands and are available in the entire configuration.
   */
  late final Map<String, dynamic> vars;

  final Config config;

  /**
   * Path relative to the output directory to install binaries at.
   */
  final List<String> _installPath;

  /**
   * The current Platform, determined by the Dart VM.
   */
  final System system = System.current();

  /**
   * Bare output directory of the project binaries.
   */
  String get outputDirectoryPath =>
      path.join(rootDirectoryPath, "out");

  /**
   * Root of the repository the dart scripts got executed.
   */
  String get rootDirectoryPath {
    io.Directory rootDirectory = io.Directory(scriptDirectoryPath);
    while (true) {
      if (io.Directory(path.join(rootDirectory.path, ".git")).existsSync()) {
        return rootDirectory.path;
      }
      rootDirectory = io.Directory(path.dirname(rootDirectory.path));
    }
  }

  String get installDirectoryPath => path.joinAll(
    [outputDirectoryPath] +
        [this.system.string(), this.config.name] +
        this._installPath,
  );

  /**
   * Temporal directory for files.
   */
  String get workDirectoryPath =>
      path.join(outputDirectoryPath, this.system.string(), this.name);

  /**
   * Directory of the script run in this isolate.
   */
  String get scriptDirectoryPath => io.Platform.isWindows
      ? path.dirname(io.Platform.script.path).substring(1)
      : path.dirname(io.Platform.script.path);

  Environment(
      this.name, {
        List<String> installPath = const [],
        final System? target,
        this.config = Config.debug,
        this.prefixSpace = 0,
        final Map<String, dynamic>? vars,
      }) : _installPath = installPath,
        this.vars = vars != null ? ({}..addAll(vars)) : {};

  Map<String, dynamic> toJson() {
    Map<String, dynamic> toJsonMap(Map<String, dynamic> map) {
      final Map<String, dynamic> jsonMap = {};
      map.forEach((key, val) {
        if (val is String) {
          jsonMap[key] = val;
        } else if (val is num) {
          jsonMap[key] = val;
        } else if (val is List<String>) {
          jsonMap[key] = val.join(" ");
        } else if (val is Platform) {
          jsonMap[key] = val.name;
        } else if (val is Processor) {
          jsonMap[key] = val.name;
        } else if (val is io.Directory) {
          jsonMap[key] = val.path;
        } else if (val is Map<String, dynamic>) {
          jsonMap[key] = toJsonMap(val);
        }
      });
      return jsonMap;
    }

    return toJsonMap(vars);
  }

  Future<bool> execute(
      final List<Step> steps, {
        final String suffix = "",
        final bool forced = false,
      }) async {
    if (!io.Directory(this.outputDirectoryPath).existsSync()) {
      io.Directory(this.outputDirectoryPath).createSync(recursive: true);
    }
    if (!io.Directory(this.installDirectoryPath).existsSync()) {
      io.Directory(this.installDirectoryPath).createSync(recursive: true);
    }
    if (!io.Directory(this.workDirectoryPath).existsSync()) {
      io.Directory(this.workDirectoryPath).createSync(recursive: true);
    }

    bool result;
    final io.File processFile = io.File(
      path.join(path.dirname(this.workDirectoryPath), ".${this.name}_build.steps"),
    );
    final String Function(String) format = (str) {
      return str
          .replaceAll(",", ",\n  ")
          .replaceAll("{", "\n  ")
          .replaceAll("}", "\n")
          .replaceAll(":", ": ");
    };

    final int bars = 80;
    final int dots = 10;

    final void Function(Map<String, dynamic>) addStep = (map) {
      processFile.writeAsStringSync(
        "\n${format(convert.jsonEncode(map))}\n${".." * dots}",
        mode: io.FileMode.append,
      );
    };

    processFile.writeAsStringSync(
      "${"-" * bars}\n${" " * 26}ENVIRONMENT CONSTANTS\n" +
          format(
            convert.jsonEncode({
              "name": this.name,
              "system": this.system.string(),
              "build_type": this.config.name,
              "work_directory": this.workDirectoryPath,
              "output_directory": this.outputDirectoryPath,
              "script_directory": this.scriptDirectoryPath,
              "install_directory": this.installDirectoryPath,
              "install_path": this._installPath.join("/"),
              "root_directory": this.rootDirectoryPath,
            }),
          ) +
          "\n\n${"-" * bars}\n${" " * 26}STEPS EXECUTION\n\n${"." * dots * 2}",
    );

    for (int i = 0; i < steps.length; i++) {
      final Step step = steps[i];
      try {
        const String spaceCharacter = " ";
        String targetName = "⟮" + this.name + "⟯" + spaceCharacter;
        String message =
            targetName + "⟮${i + 1}⁄${steps.length}⟯" + spaceCharacter;

        if (step.configure != null) {
          await step.configure!(this);
        }
        if (step.condition != null && !forced) {
          if (!await step.condition!(this)) {
            io.stdout.writeln(message + "Skipped");
            continue;
          }
        }
        result = await step.configure(this, message: message + step.name);
      } catch (e) {
        io.stderr.writeln(
          "\nError while executing step '${step.name}' (${i + 1} out of ${steps.length}).",
        );
        rethrow;
      }
      addStep(
        <String, dynamic>{
          "index": "${i + 1} of ${steps.length}",
          "result": result,
          "description": step.name,
          "wasCritical": step.exitOnException && !result,
          if (step.command != null)
            "command":
            step.command!(this).program +
                " " +
                step.command!(this).arguments.join(" "),
        }..addAll(toJson()),
      );

      if (!result && step.exitOnException) {
        return false;
      }
    }
    return true;
  }

  bool ensurePrograms(List<String> requiredPrograms) {
    final String executableExtension = io.Platform.isWindows ? ".exe" : "";
    final List<String> pathVariableEntries =
        io.Platform.environment["PATH"]?.split(
          io.Platform.isWindows ? ";" : ":",
        ) ??
            [];

    if (requiredPrograms.isEmpty) return true;

    bool isAllFound = true;
    for (String program in requiredPrograms) {
      bool found = false;
      for (String pathVariableEntry in pathVariableEntries) {
        final io.File programFile = io.File(
          path.join(pathVariableEntry, "$program$executableExtension"),
        );
        if (programFile.existsSync()) {
          found = true;
        }
      }

      if (!found) {
        final result = io.Process.runSync(
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
        io.stderr.writeln("$program" + " ✖  ");
        isAllFound = false;
      }
    }
    return isAllFound;
  }
}