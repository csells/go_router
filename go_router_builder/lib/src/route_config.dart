import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'type_helpers.dart';

/// Custom [Iterable] implementation with extra info.
class InfoIterable extends IterableBase<String> {
  InfoIterable._({
    required this.members,
    required this.routeGetterName,
  });

  /// Name of the getter associated with `this`.
  final String routeGetterName;

  /// The generated elements associated with `this`.
  final List<String> members;

  @override
  Iterator<String> get iterator => members.iterator;
}

/// Represents a `TypedGoRoute` annotation to the builder.
class RouteConfig {
  RouteConfig._(
    this._path,
    this._routeDataClass,
    this._parent,
  );

  /// Creates a new [RouteConfig] represented the annotation data in [reader].
  factory RouteConfig.fromAnnotation(
    ConstantReader reader,
    ClassElement element,
  ) {
    final definition = RouteConfig._fromAnnotation(reader, element, null);

    if (element != definition._routeDataClass) {
      throw InvalidGenerationSourceError(
        'The @TypedGoRoute annotation must have a type parameter that matches '
        'the annotated element.',
        element: element,
      );
    }

    return definition;
  }

  factory RouteConfig._fromAnnotation(
    ConstantReader reader,
    ClassElement element,
    RouteConfig? parent,
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

    final type = reader.objectValue.type! as InterfaceType;
    final typeParamType = type.typeArguments.single;

    if (typeParamType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        'The type parameter on one of the @TypedGoRoute declarations could not '
        'be parsed.',
        element: element,
      );
    }

    // TODO: validate that this MUST be a subtype of `GoRouteData`
    final classElement = typeParamType.element;

    final value = RouteConfig._(path, classElement, parent);

    value._children.addAll(reader.read('routes').listValue.map(
        (e) => RouteConfig._fromAnnotation(ConstantReader(e), element, value)));

    return value;
  }

  final _children = <RouteConfig>[];
  final String _path;
  final ClassElement _routeDataClass;
  final RouteConfig? _parent;

  /// Generates all of the members that correspond to `this`.
  InfoIterable generateMembers() => InfoIterable._(
        members: _generateMembers().toList(),
        routeGetterName: _routeGetterName,
      );

  Iterable<String> _generateMembers() sync* {
    final items = <String>[
      _rootDefinition(),
    ];

    for (final def in _flatten()) {
      items.add(def._extensionDefinition());
    }

    _enumDefinitions().forEach(items.add);

    yield* items;

    yield* items
        .expand(
          (e) => helperNames.entries
              .where((element) => e.contains(element.key))
              .map((e) => e.value),
        )
        .toSet();
  }

  /// Returns `extension` code.
  String _extensionDefinition() => '''
extension $_extensionName on $_className {
  static $_className _fromState(GoRouterState state) $_newFromState
  
  String get location => GoRouteData.\$location($_locationArgs,$_locationQueryParams);
  
  void go(BuildContext buildContext) => buildContext.go(location, extra: this);
} 
''';

  /// Returns this [RouteConfig] and all child [RouteConfig] instances.
  Iterable<RouteConfig> _flatten() sync* {
    yield this;
    for (final child in _children) {
      yield* child._flatten();
    }
  }

  late final _routeGetterName =
      r'$' + _className.substring(0, 1).toLowerCase() + _className.substring(1);

  /// Returns the `GoRoute` code for the annotated class.
  String _rootDefinition() => '''
GoRoute get $_routeGetterName => ${_routeDefinition()};
''';

  /// Returns code representing the constant maps that contain the `enum` to
  /// [String] mapping for each referenced enum.
  Iterable<String> _enumDefinitions() sync* {
    final enumParamTypes = <InterfaceType>{};

    for (final routeDef in _flatten()) {
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

    final extraParam =
        _ctor.parameters.singleWhereOrNull((element) => element.isExtraField);

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
    final pathItems = _parsedPath.map((e) {
      if (e is ParameterToken) {
        return '\${Uri.encodeComponent(${_encodeFor(e.name)})}';
      }
      if (e is PathToken) {
        return e.value;
      }
      throw UnsupportedError(
        '$likelyIssueMessage '
        'Token ($e) of type ${e.runtimeType} is not supported.',
      );
    });
    return "'${pathItems.join('')}'";
  }

  late final _pathParams = Set.unmodifiable(
      _parsedPath.whereType<ParameterToken>().map((e) => e.name));

  late final _parsedPath = List<Token>.unmodifiable(parse(_rawJoinedPath));

  String get _rawJoinedPath {
    final pathSegments = <String>[];

    RouteConfig? config = this;
    while (config != null) {
      pathSegments.add(config._path);
      config = config._parent;
    }

    return p.joinAll(pathSegments.reversed);
  }

  String get _className => _routeDataClass.name;

  String get _extensionName => '\$${_className}Extension';

  String _routeDefinition() {
    final routesBit = _children.isEmpty
        ? ''
        : '''
routes: [${_children.map((e) => '${e._routeDefinition()},').join('')}],
''';

    return '''
GoRouteData.\$route(
      path: ${escapeDartString(_path)},
      factory: $_extensionName._fromState,
      $routesBit
)
''';
  }

  String _decodeFor(ParameterElement element) {
    if (element.isRequired) {
      if (element.type.nullabilitySuffix == NullabilitySuffix.question) {
        throw InvalidGenerationSourceError(
          'Required parameters cannot be nullable.',
          element: element,
        );
      }

      if (!_pathParams.contains(element.name)) {
        throw InvalidGenerationSourceError(
          'Missing param `${element.name}` in path.',
          element: element,
        );
      }
    }
    final fromStateExpression = decodeParameter(element);

    if (element.isPositional) {
      return '$fromStateExpression,';
    }

    if (element.isNamed) {
      return '${element.name}: $fromStateExpression,';
    }

    throw InvalidGenerationSourceError(
      '$likelyIssueMessage (param not named or positional)',
      element: element,
    );
  }

  String _encodeFor(String fieldName) {
    final field = _field(fieldName);
    if (field == null) {
      throw InvalidGenerationSourceError(
        'Could not find a field for the path parameter "$fieldName".',
        element: _routeDataClass,
      );
    }

    return encodeField(field);
  }

  String get _locationQueryParams {
    if (_ctorQueryParams.isEmpty) return '';

    final buffer = StringBuffer('queryParams: {\n');

    for (final param in _ctorQueryParams.map((e) => e.name)) {
      buffer.writeln(
        'if ($param != null) ${escapeDartString(param.kebab)}: '
        '${_encodeFor(param)},',
      );
    }

    buffer.writeln('},');

    return buffer.toString();
  }

  late final List<ParameterElement> _ctorParams =
      _ctor.parameters.where((element) {
    if (element.isRequired) {
      if (element.isExtraField) {
        throw InvalidGenerationSourceError(
          'Parameters named `$extraFieldName` cannot be required.',
          element: element,
        );
      }
      return true;
    }
    return false;
  }).toList();

  late final List<ParameterElement> _ctorQueryParams = _ctor.parameters
      .where((element) => element.isOptional && !element.isExtraField)
      .toList();

  ConstructorElement get _ctor {
    final ctor = _routeDataClass.unnamedConstructor;

    if (ctor == null) {
      throw InvalidGenerationSourceError(
        'Missing default constructor',
        element: _routeDataClass,
      );
    }
    return ctor;
  }

  PropertyAccessorElement? _field(String name) =>
      _routeDataClass.getGetter(name);
}

String _enumMapConst(InterfaceType type) {
  assert(type.isEnum);

  final enumName = type.element.name;

  final buffer = StringBuffer('const ${enumMapName(type)} = {');

  for (final enumField
      in type.element.fields.where((element) => !element.isSynthetic)) {
    buffer.writeln(
      '$enumName.${enumField.name}: ${escapeDartString(enumField.name.kebab)},',
    );
  }

  buffer.writeln('};');

  return buffer.toString();
}

/// [Map] from the name of a generated helper to its definition.
const helperNames = {
  convertMapValueHelperName: _convertMapValueHelper,
  boolConverterHelperName: _boolConverterHelper,
  enumExtensionHelperName: _enumConverterHelper,
};

const _convertMapValueHelper = '''
T? $convertMapValueHelperName<T>(
  String key,
  Map<String, String> map,
  T Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}
''';

const _boolConverterHelper = '''
bool $boolConverterHelperName(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "\$value" into a bool.');
  }
}
''';

const _enumConverterHelper = '''
extension<T extends Enum> on Map<T, String> {
  T $enumExtensionHelperName(String value) =>
      entries.singleWhere((element) => element.value == value).key;
}''';
