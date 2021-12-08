export 'src/route_data.dart';

abstract class BuildContext {
  /// Navigate to a location.
  void go(String location, {Object? extra}) => throw UnimplementedError();
}
