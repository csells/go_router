/// Configuration for using `package:build`-compatible build systems.
///
/// See:
/// * [build_runner](https://pub.dev/packages/build_runner)
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline. See documentation for
/// details, and `build.yaml` for how these builders are configured by default.
library go_router_builder.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/go_router_generator.dart';

/// Supports `package:build_runner` creation and configuration of
/// `go_router`.
///
/// Not meant to be invoked by hand-authored code.
Builder goRouterBuilder(BuilderOptions options) => SharedPartBuilder(
      const [GoRouterGenerator()],
      'go_router',
    );
