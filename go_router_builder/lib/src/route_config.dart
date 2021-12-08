// ignore_for_file: public_member_api_docs

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

class RouteConfig {
  RouteConfig({
    required this.path,
    required this.children,
    required this.routeDataClass,
  });

  factory RouteConfig.fromAnnotation(
    ConstantReader reader,
    ClassElement element,
  ) =>
      RouteConfig._fromAnnotation(reader, element)..parent = null;

  factory RouteConfig._fromAnnotation(
    ConstantReader reader,
    ClassElement element,
  ) {
    assert(!reader.isNull, 'reader should not be null');
    final pathValue = reader.read('path');
    if (pathValue.isNull) {
      throw InvalidGenerationSourceError(
        'Missing `path` value on annotation.',
        element: element,
      );
    }

    final path = pathValue.stringValue;

    final children = reader
        .read('children')
        .listValue
        .map((e) => RouteConfig._fromAnnotation(ConstantReader(e), element))
        .toList();

    final type = reader.objectValue.type! as InterfaceType;
    final typeParamType = type.typeArguments.single;

    if (typeParamType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        'The type parameter on one of the @RouteDef declarations could not be '
        'parsed.',
        element: element,
      );
    }

    // TODO: validate that this MUST be a subtype of `GoRouteData`
    final classElement = typeParamType.element;

    final value = RouteConfig(
      path: path,
      children: children,
      routeDataClass: classElement,
    );

    for (final val in value.children) {
      val.parent = value;
    }

    return value;
  }

  final String path;
  final List<RouteConfig> children;
  final ClassElement routeDataClass;
  late final RouteConfig? parent;

  String extensionDefinition() => '''
extension $_extensionName on $_className {
  static $_className _fromState(GoRouterState state) $_newFromState
  
  String get location => GoRouteData.\$location($_locationArgs,$_locationQueryParams);
  
  void go(BuildContext buildContext) => buildContext.go(location$_goExtraParameter);
} 
''';

  Iterable<RouteConfig> flatten() sync* {
    yield this;
    for (final child in children) {
      yield* child.flatten();
    }
  }

  String rootDefinition() {
    final routeGetterName =
        _className.substring(0, 1).toLowerCase() + _className.substring(1);

    return '''
GoRoute get $routeGetterName => ${_routeDefinition()};
''';
  }

  Iterable<String> enumDefinitions() sync* {
    final enumParamTypes = <InterfaceType>{};

    for (final routeDef in flatten()) {
      for (final ctorParam in [
        ...routeDef._ctorParams,
        ...routeDef._ctorQueryParams,
      ]) {
        if (ctorParam.type.isEnum) {
          enumParamTypes.add(ctorParam.type as InterfaceType);
        }
      }
    }

    for (final enumParamType in enumParamTypes) {
      yield _enumMapConst(enumParamType);
    }
  }

  String get _newFromState {
    final buffer = StringBuffer('=>');
    if (_ctor.isConst && _ctorParams.isEmpty && _ctorQueryParams.isEmpty) {
      buffer.writeln('const ');
    }

    final extraParam = _ctor.parameters
        .singleWhereOrNull((element) => element.name == _extraFieldName);

    buffer.writeln('$_className(');
    for (final param in [
      ..._ctorParams,
      ..._ctorQueryParams,
      if (extraParam != null) extraParam,
    ]) {
      buffer.write(_decodeFor(param));
    }
    buffer.writeln(');');

    return buffer.toString();
  }

  // construct path bits using parent bits
  // if there are any queryParam objects, add in the `queryParam` bits
  String get _locationArgs {
    final pathItems = parse(_fullPath).map((e) {
      if (e is ParameterToken) {
        return '\${Uri.encodeComponent(${_encodeFor(e.name)})}';
      }
      if (e is PathToken) {
        return e.value;
      }
      throw UnsupportedError(
        'Cannot party on a Token ($e) of type ${e.runtimeType}',
      );
    });
    return "'${pathItems.join('')}'";
  }

  late final _fullPath = (() {
    final bits = <String>[];

    RouteConfig? bit = this;
    while (bit != null) {
      bits.add(bit.path);
      bit = bit.parent;
    }

    return p.joinAll(bits.reversed);
  })();

  String get _className => routeDataClass.name;

  String get _extensionName => '\$${_className}Extension';

  String _routeDefinition() {
    final routesBit = children.isEmpty
        ? ''
        : '''
routes: [${children.map((e) => '${e._routeDefinition()},').join('')}],
''';

    return '''
GoRouteData.\$route(
      path: ${escapeDartString(path)},
      factory: $_extensionName._fromState,
      $routesBit
)
''';
  }

  String get _goExtraParameter {
    final extraField = _field(_extraFieldName);
    if (extraField == null) return '';

    return ', extra: $_extraFieldName';
  }

  String _decodeFor(ParameterElement element) {
    final paramType = element.type;

    final stateValueAccess = _stateValueAccess(element);
    String fromStateExpression;
    if (paramType.isDartCoreString) {
      fromStateExpression = 'state.$stateValueAccess';
    } else if (paramType.isDartCoreInt) {
      fromStateExpression = 'int.parse(state.$stateValueAccess)';
    } else if (paramType.isEnum) {
      fromStateExpression = '''
${_enumMapName(paramType as InterfaceType)}.entries
    .singleWhere((element) => element.value == state.$stateValueAccess)
    .key
''';
    } else {
      throw InvalidGenerationSourceError(
        'The parameter type `$paramType` is not supported.',
        element: element,
      );
    }

    if (element.isPositional) {
      return '$fromStateExpression,';
    }

    if (element.isNamed) {
      return '${element.name}: $fromStateExpression,';
    }

    throw InvalidGenerationSourceError(
      'Should never get here! File an issue! (param not named or positional)',
      element: element,
    );
  }

  String _stateValueAccess(ParameterElement element) {
    if (element.isRequiredPositional || element.isRequiredNamed) {
      return 'params[${escapeDartString(element.name)}]!';
    }

    if (element.name == _extraFieldName) {
      return 'extra as ${element.type.getDisplayString(withNullability: true)}';
    }

    if (element.isOptional) {
      return 'queryParams[${escapeDartString(element.name)}]';
    }

    throw InvalidGenerationSourceError(
      'Should never get here! File an issue! (param not required or optional)',
      element: element,
    );
  }

  String _encodeFor(String fieldName) {
    final field = _field(fieldName);
    if (field == null) {
      throw InvalidGenerationSourceError(
        'Could not find a field for the path parameter "$fieldName".',
        element: routeDataClass,
      );
    }

    final returnType = field.returnType;
    if (returnType.isDartCoreString) {
      return fieldName;
    } else if (returnType.isDartCoreInt) {
      return '$fieldName.toString()';
    } else if (returnType.isEnum) {
      return '${_enumMapName(returnType as InterfaceType)}[$fieldName]!';
    }

    throw InvalidGenerationSourceError(
      'The return type `$returnType` is not supported.',
      element: field,
    );
  }

  String get _locationQueryParams {
    if (_ctorQueryParams.isEmpty) return '';

    final buffer = StringBuffer('queryParams: {\n');

    for (final param in _ctorQueryParams.map((e) => e.name)) {
      buffer
          .writeln('if ($param != null) ${escapeDartString(param)}: $param!,');
    }

    buffer.writeln('},');

    return buffer.toString();
  }

  late final List<ParameterElement> _ctorParams = _ctor.parameters
      .where(
        (element) => element.isRequiredPositional || element.isRequiredNamed,
      )
      .toList();

  late final List<ParameterElement> _ctorQueryParams = _ctor.parameters
      .where((element) =>
          element.isOptionalNamed && element.name != _extraFieldName)
      .toList();

  ConstructorElement get _ctor {
    final ctor = routeDataClass.unnamedConstructor;

    if (ctor == null) {
      throw InvalidGenerationSourceError(
        'Missing default constructor',
        element: routeDataClass,
      );
    }
    return ctor;
  }

  PropertyAccessorElement? _field(String name) =>
      routeDataClass.getGetter(name);
}

String _enumMapName(InterfaceType type) => '_\$${type.element.name}EnumMap';

String _enumMapConst(InterfaceType type) {
  assert(type.isEnum);

  final enumName = type.element.name;

  final buffer = StringBuffer('const ${_enumMapName(type)} = {');

  for (final enumField
      in type.element.fields.where((element) => !element.isSynthetic)) {
    buffer.writeln(
      '$enumName.${enumField.name}: ${escapeDartString(enumField.name.kebab)},',
    );
  }

  buffer.writeln('};');

  return buffer.toString();
}

const _extraFieldName = r'$extra';
