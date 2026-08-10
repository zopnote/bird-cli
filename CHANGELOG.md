## 1.0.0

- Base workflow structure
- Essential steps
- Commands & flags structure (cmdline)
- CLI steps for toolchain development

## 1.0.1
- Added ``onFailure()`` & ``onSuccess()`` to the ``Check``-step.
- Fixed the output of ``Check`` when ``canStartProcesses`` is set to ``false``.
- Fixed directory look-up of ``Check``.
- Added ``Check`` unit test.

## 2.0.0

- Added ``runWorkflow()`` and ``runCommand()`` instead of class methods.
- Added ``Bubble`` & ``Loop``.
- Added documentation to all source files.
- Added examples to ``examples/``.
- Fixed errors with ``Check``.
- Removed ``AtomicStep``.
- Replaced configuration and atomization into one unified execution pipeline.
- Extracted several snippets into their own functions in multiple classes.
- Added ``critical`` Level to responses.
- An execution doesn't have to ``return`` a ``Response`` anymore.
- Added documentation to README.md

## 2.1.0
- Added ``Platform`` representation ``class`` for scripting with the purpose of targeting different platforms.
- Added ``drafts/`` for future ideas.

## 2.1.1
- Unified versioning of Apple platforms.
- Added wiki and documentation.
- Fixed Windows platform detection.
- Export attributes with ``platform.dart``.
- Added ``OperatingSystem.generic``.
- Added ``workflow_dispath`` to ``dart-project-quality.yml``.
- Updated ``dart-project-quality.yml`` to just run on ``lib/``, ``example/`` and ``test/``.
- Removed reference to _dart2embed_-project from ``README.md``.

## 2.2.0
- Moved sources to ``src/`` and updated library aliases.
- Deprecated all ``name``-members of the steps.
- Added ``ProcessInterface`` to interface with cli processes.
- Added ``Level.normal`` and deprecated ``Level.status``.
- Removed ``clang.dart`` from WIP.
- Added ``analysis_options.dart`` to the projects root.
- Added ``platform.dart`` with attributes for all supported operating systems.
- Changed ``Shell``'s usage, to extract the process invocation logic.
- Unit tests: ``process_interface_test.dart``, ``shell_test.dart`` & ``check_test.dart``.

## 2.2.1
- Removed responses in check.dart
- Removed responses in install.dart
- Added ``toString()`` and ``name()`` to platform.dart
- Added environment variables to ``options`` of ``PlatformInterface``
- Added ``Response.isError``
- Fixed the issue, that ``runWorkflow`` never really returned the last ``Response``

## 2.2.2
- Fixed that the process gets executed with sudo on unix if the process required elevated privileges but can't even provide the sudo passwd.

## 2.3.0
- Renamed ``FlowContextController`` to ``FlowController``
- Deprecated ``Bubble`` and moved its logic to ``FlowController``
- Moved steps to ``<sublib>/steps/``
- Implemented new logic of ``Bubble``s into ``chain.dart``
- Opened the default value of ``TextFlag``

## 2.3.1
- Added a default help flag to every command
- Updated cmd syntax formatting to support custom space

## 2.3.2
- Added ``printLast`` option to ``runCommand()``
- Added ``LogASCIIContext``-``Step`` to ``stepflow.io/steps``

## 3.0.0 (WIP)
- Removal of deprecated aliases.
- Improved workflow logic.
- Replaced ``Response``s with exceptions for error handling.
- Removed ``CollectionStep``, ``StepWiser`` & ``SingleStep``, because the generic type
struggle isn't worth the syntax sugar.
- Removed platform and cmdline entirely.
- Fixed a bug at ``PlatformInterface``, where an exception was thrown, if the
specified working directory had not existed.
- Added ``BuildListExtension`` on all Lists, with conditional add to list functions
for constructing arguments in shell when mapping.