import 'dart:convert';


Future<void> main() async {
  Step? step = Chain(
    steps: [
      Runnable(
        (environment) {
          return const Response();
        },
        name: "Test atomic step.",
        description:
            "Runnable is an atomic step, that can be used with conditionals to ensure logic.",
      ),



       Chain(
        steps: [
           Conditional(
            condition: (_) => true,
            child: Shell(
              program: "cmake",
              arguments: ["--help"],
              name: 'test command configure step',
              description:
                  'shell is an configure step and will be transformed to an actual atomic runnable step',
            ),
          ),
        ],
      ),
    ],
  ).configure(Config());

  if (step is AtomicStep?) {
    print(JsonEncoder.withIndent("   ").convert(step.toJson()));
  }
  while ((step as AtomicStep?) != null) {
    await step!.execute(const Environment());
    if (step!.next == null) break;
    step = step!.next;
  }
}
