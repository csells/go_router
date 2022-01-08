import 'package:go_router_builder/src/go_router_generator.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen_test/source_gen_test.dart';

Future<void> main() async {
  initializeBuildLogTracking();
  final testReader = await initializeLibraryReaderForDirectory(
    p.join('test', 'test_inputs'),
    '_go_router_builder_test_input.dart',
  );

  testAnnotatedElements(
    testReader,
    const GoRouterGenerator(),
    expectedAnnotatedTests: _expectedAnnotatedTests,
  );
}

const _expectedAnnotatedTests = {
  'AppliedToWrongClassType',
  'BadPathParam',
  'ExtraMustBeOptional',
  'MissingPathParam',
  'MissingPathValue',
  'MissingTypeAnnotation',
  'NullableRequiredParam',
  'UnsupportedType',
  'theAnswer',
};
