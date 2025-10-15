# ``stepflow``
A Dart package for building modular workflows. 
It introduces step-based composition, where each step is a self-contained unit of logic or interaction. 
The structure makes it easier to break down processes to into more reusable steps. Improving clarity, 
testability, and maintainability of toolchains or workflows. It's like Flutter but for workflows or cli.

To add it to your dart project, just run:
````bash
dart pub add stepflow
````
> Below is a brief overview of the package. For actual documentation head over into the repositories' wiki.
## Common
Stepflow has common components, suitable for whatever scenario you can fit
workflows in. To take a look:
`````dart
final class ExampleWorkflow extends ConfigureStep {
  const ExampleWorkflow() : super(
    name: "example_workflow",
    description:
    "Example workflow with the purpose to provide a brief overview.",
  );
  @override
  Step configure() {
    return Runnable(
      name: "Says hello",
      description: "Respond with a basic hello-world-message.", 
      (context) {
        return Response(
            message: "Hello World!",
            level: ResponseLevel.info
        );
      },
    );
  }
}

void main() => Workflow.from(const ExampleWorkflow()).run();
`````

## CLI
Stepflow also comes with a framework-like system for CLI commands and flags.
````dart
Future<int> main(List<String> rawArguments) async => await Command(
  use: "my_cli",
  description: "Example command for showcase",
  run: (context) {
    String text = context.getFlag("text").value;
    if (text.isNotEmpty) {
      stdout.writeln(text);
    }
    return context.response(message: "Everything is fine!");
  },
  flags: [
    TextFlag(
        name: "text", 
        description: "A text flag contains a string as value."
            "A flag has always an initial value, whereas the text"
            "flag would just be an empty string."
    )
  ]
).execute(rawArguments, globalFlags: []);
````
