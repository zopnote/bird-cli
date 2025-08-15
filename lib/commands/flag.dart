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
   * Immutable reference to the description of the flag,
   * explaining the purpose of the property.
   *
   * It will be displayed as part of the help/syntax message.
   */
  final String description;

  /// The mutable reference to the flags value.
  T value;

  /**
   * Immutable reference to the flags example values,
   * provided only at the initialization.
   */
  final List<T> examples;

  /// Returns the flags value as a formatted string.
  String getFormatted() => format(value);

  /**
   * Returns the flag example values as formatted strings.
   * If the examples are empty an empty list is returned.
   */
  List<String> getExamplesFormatted() =>
      examples.map<String>((example) => format(example)).toList();

  /// Parse a raw immutable string reference into the flags value type.
  final T Function(String raw) parse;

  /// Formats the flags value type into a string.
  final String Function(T value) format;

  /// Sets the parsed raw value as the flags one.
  void setParsed(String raw) => value = parse(raw);

  @override
  bool operator ==(Object other) {
    if (!(other is Flag)) {
      throw Exception(
        "Can't compare to values of different types. ${other.runtimeType} and ${this.runtimeType}",
      );
    }
    return name == other.name;
  }

  @override
  String toString() => format(value);

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
 * A flag representing a text value.
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
 * A flag representing a truthness value.
 */
final class BoolFlag extends Flag<bool> {
  BoolFlag({required super.name, required super.value, super.description})
    : super(format: _format, parse: _parse);

  static String _format(bool value) => value.toString();

  static bool _parse(String raw) => raw == "true" ? true : false;
}
