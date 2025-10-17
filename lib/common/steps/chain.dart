import 'package:stepflow/common.dart';
import 'package:stepflow/common/steps/bubble.dart';



final class Chain extends Bubble {
  late final Step Function(int index) build;
  final int? length;

  Chain._internal({required this.build, required this.length});

  factory Chain({required List<Step> steps}) {
    return Chain._internal(
      build: (index) {
        return steps[index];
      },
      length: steps.length,
    );
  }

  factory Chain.builder(Step builder(int index), {final int? length}) {
    return Chain._internal(build: builder, length: length);
  }

  int index = 0;
  @override
  Step builder() {
    if (length == null) {
      return build(index++);
    }
    if (index == length! - 1) {
      leave = true;
      return build(index++);
    }
    return build(index++);
  }

  @override
  Map<String, dynamic> toJson() => {
    "type": "chain"
  };
}
