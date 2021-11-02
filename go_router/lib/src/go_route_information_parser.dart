import 'package:flutter/widgets.dart';

import 'logging.dart';

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    log2('GoRouteInformationParser.parseRouteInformation: '
        'routeInformation.location= ${routeInformation.location}');
    return Uri.parse(routeInformation.location!);
  }

  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    log2('GoRouteInformationParser.parseRouteInformation: '
        'configuration= $configuration');
    return RouteInformation(location: configuration.toString());
  }
}
