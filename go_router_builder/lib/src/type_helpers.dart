import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

/// The property/parameter name used to represent the `extra` data that may
/// be passed to a route.
const extraFieldName = r'$extra';

/// Gets the name of the `const` map generated to help encode [Enum] types.
String enumMapName(InterfaceType type) => '_\$${type.element.name}EnumMap';

/// Returns the encoded [String] value for [element], if its type is supported.
///
/// Otherwise, throws an [InvalidGenerationSourceError].
String encodeField(PropertyAccessorElement element) {
  for (final helper in _helpers) {
    if (helper._matchesType(element.returnType)) {
      return helper._encode(element.name, element.returnType);
    }
  }

  throw InvalidGenerationSourceError(
    'The return type `${element.returnType}` is not supported.',
    element: element,
  );
}

/// Returns the decoded [String] value for [element], if its type is supported.
///
/// Otherwise, throws an [InvalidGenerationSourceError].
String decodeParameter(ParameterElement element) {
  final paramType = element.type;

  for (final helper in _helpers) {
    if (helper._matchesType(paramType)) {
      final stateValueAccess = _stateValueAccess(element);
      return helper._decode(stateValueAccess, paramType);
    }
  }

  throw InvalidGenerationSourceError(
    'The parameter type `$paramType` is not supported.',
    element: element,
  );
}

String _stateValueAccess(ParameterElement element) {
  if (element.isRequiredPositional || element.isRequiredNamed) {
    return 'params[${escapeDartString(element.name)}]!';
  }

  if (element.name == extraFieldName) {
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

const _helpers = [
  _TypeHelperString(),
  _TypeHelperInt(),
  _TypeHelperEnum(),
];

abstract class _TypeHelper {
  const _TypeHelper();

  bool _matchesType(DartType type);

  String _encode(String fieldName, DartType type);

  String _decode(String stateValueAccess, DartType paramType);
}

class _TypeHelperString extends _TypeHelper {
  const _TypeHelperString();

  @override
  bool _matchesType(DartType type) => type.isDartCoreString;

  @override
  String _encode(String fieldName, DartType type) => fieldName;

  @override
  String _decode(String stateValueAccess, DartType paramType) =>
      'state.$stateValueAccess';
}

class _TypeHelperInt extends _TypeHelper {
  const _TypeHelperInt();
  @override
  String _encode(String fieldName, DartType type) => '$fieldName.toString()';

  @override
  bool _matchesType(DartType type) => type.isDartCoreInt;

  @override
  String _decode(String stateValueAccess, DartType paramType) =>
      'int.parse(state.$stateValueAccess)';
}

class _TypeHelperEnum extends _TypeHelper {
  const _TypeHelperEnum();
  @override
  String _encode(String fieldName, DartType type) =>
      '${enumMapName(type as InterfaceType)}[$fieldName]!';

  @override
  bool _matchesType(DartType type) => type.isEnum;

  @override
  String _decode(String stateValueAccess, DartType paramType) => '''
${enumMapName(paramType as InterfaceType)}.entries
    .singleWhere((element) => element.value == state.$stateValueAccess)
    .key
''';
}
