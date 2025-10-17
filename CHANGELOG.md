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

## 1.0.2
- Added ``FlowContext.stopWorkflow(Response message)`` to end a workflow on critical errors.