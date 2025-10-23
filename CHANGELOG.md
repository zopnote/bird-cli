## 1.0.0

- Base workflow structure
- Essential steps
- Commands & flags structure (cmdline)
- CLI steps for toolchain development

## 1.0.1
- Added ``onFailure()`` & ``onSuccess()`` to the ``Check``-step.
- Fixed the output of ``Check`` when ``canStartProcesses`` is set to ``false``.
- Fixed directory look up of ``Check``.
- Added ``Check`` unit test.

## 2.0.0
From now on, the interface will be stable for a longer period. 
I apologize for the fast change of the last interface, 
you should be able to depend on Stepflow.

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