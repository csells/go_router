// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../go_router.dart';

class OverlayBuilder {
  final _overlayKey = GlobalKey<OverlayState>();

  // use the null value to know if this [OverlayEntry] as been created or not;
  // it will be created during the first [build]
  OverlayEntry? _entry;

  // Store the pages and state here otherwise the [entry] is not updated
  // ignore: use_late_for_private_fields_and_variables
  List<Page<dynamic>>? _pages;
  // ignore: use_late_for_private_fields_and_variables
  GoRouterState? _state;

  Widget build({
    required BuildContext context,
    required GoRouterState state,
    required List<Page<dynamic>> pages,
    required Widget Function(
      BuildContext context,
      GoRouterState state,
      List<Page<dynamic>> pages,
    )
        builder,
  }) {
    _pages = pages;
    _state = state;
    _entry ??= OverlayEntry(
      builder: (context) => builder(context, _state!, _pages!),
    );

    _entry!.markNeedsBuild();
    return Overlay(key: _overlayKey, initialEntries: [_entry!]);
    // return _entry!.builder(context);
  }
}
