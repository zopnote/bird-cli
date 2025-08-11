/*
 * Copyright (c) 2025 Lenny Siebert
 *
 * This software is dual-licensed:
 *
 * 1. Open Source License:
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License version 3
 *    as published by the Free Software Foundation.
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY. See the GNU General Public
 *    License for more details: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * 2. Commercial License:
 *    A commercial license will be available at a later time for use in commercial products.
 *
 */

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:path/path.dart' as path;



final class StepCommand {
  final String program;
  final List<String> arguments;

  /// Should the parent environment variables be added to the access of the command.
  final bool includeParentEnvironment = true;

  /// On windows the command will be executed as powershell administrator,
  /// on linux and macOS a sudo will be added.
  final bool administrator;

  final String? workingDirectoryPath;

  /// Should run the command in an external shell.
  final bool shell;

  const StepCommand({
    required this.program,
    required this.arguments,
    this.shell = false,
    this.workingDirectoryPath,
    this.administrator = false,
  });

  String get string {
    return "${program} ${arguments.join(" ")}";
  }
}

/**
 * Representing the build type.
 *
 * [debug], [releaseDebug], [release]
 */
enum Config {
  /**
   * Referees to a build including assertions and debug symbols as well as no optimizations.
   */
  debug("debug"),

  /**
   * Referees to a build with assertions and debug symbols as well as all optimizations.
   */
  releaseDebug("debug_release"),

  /**
   * Referees to a build without debug symbols and assertions as well as all optimizations.
   */
  release("release");

  const Config(this.name);

  /**
   * The name of a build type, not corresponding to third parties.
   */
  final String name;
}

/**
 * Represents a build configuration with information of the environment, the file system as well as system and targets.
 *
 * Manages the build life cycle with [Step].
 */


bool install({
  List<String> installPath = const [],
  List<String> directoryNames = const [],
  List<String> fileNames = const [],
  List<String> rootDirectoryPath = const [],
  List<String> excludeEndings = const [],
  List<String> relativePath = const [],
}) {
  try {
    final io.Directory workDirectory = io.Directory(
      path.joinAll(rootDirectoryPath + relativePath),
    );
    for (final entity in workDirectory.listSync()) {
      if (entity is io.File) {
        if (!fileNames.contains(path.basenameWithoutExtension(entity.path))) {
          continue;
        }
        if (excludeEndings.contains(path.extension(entity.path))) {
          continue;
        }
        final String filePath = path.join(
          path.joinAll(installPath),
          path.relative(entity.path, from: path.joinAll(rootDirectoryPath)),
        );
        final fileDirectory = io.Directory(path.dirname(filePath));
        if (!fileDirectory.existsSync()) {
          fileDirectory.createSync(recursive: true);
        }
        entity.copySync(filePath);
      } else if (entity is io.Directory) {
        if (!directoryNames.contains(
          path.basenameWithoutExtension(entity.path),
        )) {
          continue;
        }
        final files = entity
            .listSync(recursive: true)
            .where((e) => (e is io.File))
            .cast<io.File>();
        for (final io.File file in files) {
          final String filePath = path.join(
            path.joinAll(installPath),
            path.relative(entity.path, from: path.joinAll(rootDirectoryPath)),
            path.relative(file.path, from: entity.path),
          );
          final fileDirectory = io.Directory(path.dirname(filePath));
          if (!fileDirectory.existsSync()) {
            fileDirectory.createSync(recursive: true);
          }
          file.copySync(filePath);
        }
      }
    }
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Representing a specific operating system.
 */
enum Platform { windows, macos, linux }

/**
 * Representing a specific processor architecture.
 */
enum Processor { x86_64, arm64 }

/**
 * Operating system, processor couple to determine the full platform in context.
 */

final class System {
  final Platform platform;
  final Processor processor;
  System(this.platform, this.processor);
  static System? parseString(String string) {
    Platform? platform = null;
    Processor? processor = null;

    for (Platform systemValue in Platform.values) {
      if (systemValue.name == string.split("_").first) {
        platform = systemValue;
      }
    }
    for (Processor processorValue in Processor.values) {
      if (processorValue.name == string.split("_").sublist(1).join("_")) {
        processor = processorValue;
      }
    }
    if (platform == null || processor == null) return null;
    return System(platform, processor);
  }

  factory System.current() {
    final String system = io.Platform.version.split("\"")[1];
    return System(
      Platform.values.firstWhere((i) => i.name == system.split("_").first),
      {"x64": Processor.x86_64, "arm64": Processor.arm64}[system
          .split("_")
          .last]!,
    );
  }

  /**
   *  A formatted version of System for use of representation.
   */
  String string() {
    return "${platform.name}_${processor.name}";
  }
}

