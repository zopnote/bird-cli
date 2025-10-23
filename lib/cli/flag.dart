/**
 * A flag is the base representation of a property given at the command line.
 *
 * It is intended to be extended for every special use case to deliver formatting
 * and parsing.
 *
 * **As example** you should extend the class [Flag], for a command line flag
 * representing a platform target formatted as [system_processor].
 * Then you can hide the Flag member variables and you have to
 * provide a formating and parsing function.
 *
 */
class Flag<T> {
  Flag({
    required this.name,
    required this.value,
    required this.format,
    required this.parse,
    this.examples = const [],
    this.description = "",
  });

  /**
   * The name of the flag, that have to be referenced
   * when typing in the command line.
   */
  final String name;

  /**
   * Description of the flag, explaining the purpose of the property.
   *
   * It will be displayed as part of the help/syntax message.
   */
  final String description;

  /**
   * The mutable reference to the flags value.
   */
  T value;

  /**
   * The flags example values done for guiding.
   */
  final List<T> examples;

  /**
   * Returns the flags value as a formatted string.
   */
  String getFormatted() => format(value);

  /**
   * Returns the flag example values as formatted strings.
   * If the examples are empty an empty list is returned.
   */
  List<String> getExamplesFormatted() =>
      examples.map<String>((example) => format(example)).toList();

  /**
   * Parses a string into the flags value type.
   * Returns the parsed value.
   */
  final T Function(String raw) parse;

  /**
   * Formats the flags value into a string,
   * that can be parsed by the Flag's [parse] function.
   */
  final String Function(T value) format;

  /**
   * Sets the parsed raw value as the flags one.
   */
  void setParsed(String raw) => value = parse(raw);

  @override
  int get hashCode => Object.hash(name, description, examples, parse, format);

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  String toString() => format(value);

  /**
   * Syntax message part describing the flag.
   *
   * Used as part of [Command.syntaxMessage()].
   */
  String syntaxString() {
    String syntax = "--${name}";
    final int space = 13 - name.length;
    if (description.isNotEmpty) {
      syntax = syntax + (" " * space) + "${description}";
    }
    if (examples.isNotEmpty) {
      syntax = syntax + " (examples: ${getExamplesFormatted().join(", ")})";
    }
    return syntax;
  }
}

/**
 * A flag that contains a [String] as it's value.
 */
final class TextFlag extends Flag<String> {
  TextFlag({required super.name, super.description})
    : super(value: "", format: _format, parse: _parse);

  static String _format(String value) => value;

  static String _parse(String raw) {
    final List<int> deletable = const [];
    for (int i = 0; i < raw.length - 1; i++) {
      if (raw.codeUnitAt(i) != '"') {
        continue;
      }
      if (i == 0) {
        deletable.add(i);
        continue;
      }
      if (raw.codeUnitAt(i - 1) != '\\') {
        deletable.add(i);
      }
      deletable.add(i - 1);
    }
    String parsed = raw;
    for (final int i in deletable) {
      parsed = parsed.substring(0, i) + parsed.substring(i);
    }
    return parsed;
  }
}

/**
 * A flag representing a boolean value.
 *
 * Whenever the flag is provided in command line,
 * it is interpreted as true, even without specifying it directly.
 */
final class BoolFlag extends Flag<bool> {
  BoolFlag({required super.name, required super.value, super.description})
    : super(format: _format, parse: _parse);

  static String _format(bool value) => value.toString();

  static bool _parse(String raw) => raw == "true" ? true : false;
}
