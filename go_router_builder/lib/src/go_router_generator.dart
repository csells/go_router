import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_config.dart';

/// A [Generator] for classes annotated with `TypedGoRoute`.
class GoRouterGenerator extends GeneratorForAnnotation<void> {
  /// Creates a new instance of [GoRouterGenerator].
  const GoRouterGenerator();

  @override
  TypeChecker get typeChecker => const TypeChecker.fromUrl(
        'package:go_router/src/route_data.dart#TypedGoRoute',
      );

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    final getters = <String>{};

    for (final annotatedElement in library.annotatedWith(typeChecker)) {
      final generatedValue = generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      getters.add(generatedValue.routeGetterName);
      for (final value in generatedValue) {
        assert(value.length == value.trim().length);
        values.add(value);
      }
    }

    if (values.isEmpty) return '';

    return [
      '''
List<GoRoute> get \$appRoutes => [
${getters.map((e) => "$e,").join('\n')}
    ];
''',
      ...values,
    ].join('\n\n');
  }

  @override
  InfoIterable generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The @TypedGoRoute annotation can only be applied to classes.',
        element: element,
      );
    }

    if (!element.allSupertypes
        .any((element) => _goRouteDataChecker.isExactlyType(element))) {
      throw InvalidGenerationSourceError(
        'The @TypedGoRoute annotation can only be applied to classes that '
        'extend or implement `GoRouteData`.',
        element: element,
      );
    }

    return RouteConfig.fromAnnotation(annotation, element).generateMembers();
  }
}

const _goRouteDataChecker = TypeChecker.fromUrl(
  'package:go_router/src/route_data.dart#GoRouteData',
);
