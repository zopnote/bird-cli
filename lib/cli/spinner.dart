import 'dart:async';
import 'dart:io';

import 'package:stepflow/environment.dart';

class SpinnerMessage extends Message {
  final List<String> _frames;

  Timer? _timer;
  int _counter = 0;

  SpinnerMessage(
      super.content, {
        List<String> frames = const [
          '⠋',
          '⠙',
          '⠹',
          '⠸',
          '⠼',
          '⠴',
          '⠦',
          '⠧',
          '⠇',
          '⠏',
        ],
      }) : _frames = frames;

  @override
  bool get isOpen => _timer?.isActive ?? false;

  IOSink? sink;
  @override
  void open(IOSink sink) {
    this.sink = sink;
    _counter = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      sink.write('\r$content ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  @override
  void close() {
    _timer?.cancel();
    if (sink != null) {
      sink!.write('\r');
      sink!.write(content + "\n");
    }
  }
}

