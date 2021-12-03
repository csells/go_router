// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:go_router/go_router.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldThrow('The @RouteDef annotation can only be applied to classes.')
@RouteDef(path: 'bob') // ignore: invalid_annotation_target
const theAnswer = 42;

@ShouldThrow('Missing `path` value on annotation.')
@RouteDef()
class MissingPathValue extends GoRouteData {}

@ShouldThrow(
  'The @RouteDef annotation can only be applied to classes that extend or '
  'implement `GoRouteData`.',
)
@RouteDef(path: 'bob')
class AppliedToWrongClassType {}

@ShouldThrow(
  'The @RouteDef annotation must have a type parameter that matches the '
  'annotated element.',
)
@RouteDef(path: 'bob')
class MissingTypeAnnotation extends GoRouteData {}

@ShouldThrow(
  'Could not find a field for the path parameter "id".',
)
@RouteDef<BadPathParam>(path: 'bob/:id')
class BadPathParam extends GoRouteData {}

@ShouldThrow(
  'The parameter type `Stopwatch` is not supported.',
)
@RouteDef<UnsupportedType>(path: 'bob/:id')
class UnsupportedType extends GoRouteData {
  UnsupportedType({required this.id});
  final Stopwatch id;
}
