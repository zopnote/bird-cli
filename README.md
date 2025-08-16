# ``stepped_cli``
A Dart framework for building modular, object-oriented CLI applications using a command–environment architecture. 
It introduces a step-based execution model, where each step is a self-contained unit of logic or interaction. 
This structure allows complex processes to be broken down into reusable, composable steps, improving clarity, 
testability, and maintainability of CLI workflows.

To add it to your dart project, just run:
````bash
dart pub add stepped_cli
````

## First command
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
