
import 'dart:async';
import 'dart:io';

class ProcessSpinner {
  final List<String> _frames;

  Timer? _timer;
  int _counter = 0;

  ProcessSpinner({
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

  void start([String message = '']) {
    _counter = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      stdout.write('\r$message ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  void stop([String message = ""]) {
    _timer?.cancel();
    stdout.write('\r');
    stdout.write(message + "\n");
  }
}

Future waitWhile(bool test(), [Duration pollInterval = Duration.zero]) {
  var completer = Completer();
  check() {
    if (!test()) {
      completer.complete();
    } else {
      Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}
