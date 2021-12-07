import 'dart:async';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

/// The logger for this package.
Logger log = Logger('GoRouter');

StreamSubscription? _subscription;

/// Forwards diagnostic messages to the dart:developer log() API.
void setLogging({bool enabled = false}) {
  _subscription?.cancel();
  if (!enabled) {
    return;
  }

  _subscription = Logger.root.onRecord.listen((e) {
    developer.log(
      e.message,
      time: e.time,
      sequenceNumber: e.sequenceNumber,
      level: e.level.value,
      name: e.loggerName,
      zone: e.zone,
      error: e.error,
      stackTrace: e.stackTrace,
    );
  });
}
