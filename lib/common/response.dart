enum Level { critical, error, warning, status, verbose }

/**
 * Response that describes the final result of the operation.
 * In positive as well in error cases a message has to be provided.
 */
final class Response {
  const Response([
    this.message = "",
    this.level = Level.verbose,
  ]);
  final Level level;
  final String message;
}
