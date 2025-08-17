import 'dart:async';
import 'dart:io';

import 'config.dart';

abstract class Environment {
  final Config config;
  final Map<String, dynamic> variables = const {};
  final List<Message> messages = const [];
  const Environment({required this.config});

  operator [](String key) => variables[key];

  void addMessage();

  FutureOr<void> dispose();
}

class ConsoleEnvironment extends Environment {}

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
  void init() {
    _counter = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      stdout.write('\r$content ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    stdout.write('\r');
    stdout.write(content + "\n");
  }
}

class TextMessage extends Message {
  const TextMessage(super.content);
  @override
  void init() {
    stdout.writeln(content);
  }
}

class Message {
  const Message(this.content);
  final String content;
  void init() {}
  void dispose() {}
}
