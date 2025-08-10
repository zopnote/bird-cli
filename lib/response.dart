
/**
 * Response that describes the final result of the operation.
 * In positive as well in error cases a message has to be provided.
 */
final class Response {
  const Response({this.message = "", this.isError = false});
  final bool isError;
  final String message;
}
