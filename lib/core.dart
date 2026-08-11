export 'src/core/workflow.dart';

export 'src/core/atomics.dart';

export 'src/core/steps/chain.dart';
export 'src/core/steps/conditional.dart';
export 'src/core/steps/runnable.dart';
export 'src/core/steps/skipped.dart';

extension BuildListExtension<T> on List<T> {
  void addIf(bool condition, T value) {
    if (condition) add(value);
  }

  void addAllIf(bool condition, Iterable<T> value) {
    if (!condition) return;
    addAll(value);
  }

  void addNotNull(T? value) {
    if (value != null) add(value);
  }

  void addAllNotNull(Iterable<T?>? value) {
    if (value != null) addAll(value.where((e) => e != null).map((e) => e!));
  }

  void mapNotNull<E>(E? value, T Function(E) map) {
    if (value != null) add(map(value));
  }

  void mapAllNotNull<E>(E? value, Iterable<T> Function(E) map) {
    if (value != null) addAll(map(value));
  }

  void mapAllIf<E>(bool value, Iterable<T> Function(E) map) {
    if (value) addAll(map(value));
  }
}