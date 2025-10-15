enum ResponseLevel { error, warning, info, status }

/**
 * Response that describes the final result of the operation.
 * In positive as well in error cases a message has to be provided.
 */
final class Response {
  const Response({
    this.message = "",
    this.level = ResponseLevel.info,
  });
  final ResponseLevel level;
  final String message;
}
