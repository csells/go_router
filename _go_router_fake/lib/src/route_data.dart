// ignore_for_file: public_member_api_docs

import 'package:meta/meta_meta.dart';

/// Baseclass for types that wish to play along her.
///
/// This looks like [StatelessWidget] – I don't think we want to subclass,
/// though.
abstract class GoRouteData {
  const GoRouteData();
}

/// The annotation we use! Annotating the source library seems to be a good
/// idea, but open to discuss.
@Target({TargetKind.library, TargetKind.classType})
class RouteDef<T extends GoRouteData> {
  const RouteDef({
    required this.path,
    this.children = const [],
  });

  final String path;
  final List<RouteDef> children;
}
