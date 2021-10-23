import 'package:flutter/foundation.dart';

const _debugLog2Diagnostics = false;
// const _debugLog2Diagnostics = kDebugMode;

// ignore: public_member_api_docs
void log2(String s) {
  if (_debugLog2Diagnostics) debugPrint('  $s');
}
