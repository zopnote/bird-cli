/**
 * A command flag which is present in the run function indicates already a bool.
 *
 * If it is a [String] flag the value is set to a non-empty string.
 */
abstract class Flag {
  const Flag({
    required this.name,
    this.description = "",
    this.overview = const [],
  });


  Flag parseValue(String rawFlagArgument);

  final String name;
  final String description;

  /// Provides an overview by giving possible values to provide help to decide.
  final List<String> overview;
}

final class StringFlag extends Flag {
  String value;
  StringFlag({
    required super.name,
    super.description = "",
    super.overview = const [],
    this.value = "",
  });

  @override
  Flag parseValue(String rawFlagArgument) {
    if (rawFlagArgument.split("=").length <= 1) {
      value = "";
      return this;
    }
  }
}

final class BoolFlag extends Flag {
  final bool value;
  const BoolFlag({
    required super.name,
    super.description = "",
    super.overview = const [],
    this.value = false,
  });
}