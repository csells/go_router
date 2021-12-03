import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  Future<Uri> parseRouteInformation(
    RouteInformation routeInformation,
  ) =>
      // Use [SynchronousFuture] so that the initial url is processed
      // synchronously and remove unwanted initial animations on deep-linking
      SynchronousFuture(Uri.parse(routeInformation.location!));

  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(location: configuration.toString());
}
