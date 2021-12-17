import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The logger for this package.
final log = Logger('GoRouter');

StreamSubscription? _subscription;

/// Forwards diagnostic messages to the dart:developer log() API.
void setLogging({bool enabled = false}) {
  _subscription?.cancel();
  if (!enabled) {
    return;
  }

  _subscription = Logger.root.onRecord.listen((e) {
    // Use `dumpErrorToConsole` for severe messages. This ensures that severe
    // exceptions are formatted consistently with other Flutter examples and
    // avoids printing duplicate exceptions.
    if (e.level >= Level.SEVERE) {
      final error = e.error;
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(
          exception: error is Exception ? error : Exception(error),
          stack: e.stackTrace,
          library: e.loggerName,
          context: ErrorDescription(e.message),
        ),
      );
      return;
    }

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
