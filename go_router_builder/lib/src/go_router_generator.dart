import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_config.dart';

/// A [Generator] for classes annotated with `RouteDef`.
class GoRouterGenerator extends GeneratorForAnnotation<void> {
  /// Creates a new instance of [GoRouterGenerator].
  const GoRouterGenerator();

  @override
  TypeChecker get typeChecker => const TypeChecker.fromUrl(
        'package:go_router/src/route_data.dart#RouteDef',
      );

  @override
  Iterable<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The @RouteDef annotation can only be applied to classes.',
        element: element,
      );
    }

    if (!element.allSupertypes
        .any((element) => _goRouteDataChecker.isExactlyType(element))) {
      throw InvalidGenerationSourceError(
        'The @RouteDef annotation can only be applied to classes that extend '
        'or implement `GoRouteData`.',
        element: element,
      );
    }

    final definition = RouteConfig.fromAnnotation(annotation, element);

    if (element != definition.routeDataClass) {
      throw InvalidGenerationSourceError(
        'The @RouteDef annotation must have a type parameter that matches the '
        'annotated element.',
        element: element,
      );
    }

    final items = <String>[
      definition.rootDefinition(),
    ];

    for (final def in definition.flatten()) {
      items.add(def.extensionDefinition());
    }

    definition.enumDefinitions().forEach(items.add);

    return items;
  }
}

const _goRouteDataChecker = TypeChecker.fromUrl(
  'package:go_router/src/route_data.dart#GoRouteData',
);
