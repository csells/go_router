import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_examples/redirection.dart';
import 'package:go_router_examples/shared/data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'helpers/mock_go_router.dart';

void main() {
  late LoginInfo loginInfo;
  setUp(() {
    loginInfo = LoginInfo();
  });

  testWidgets('should render the default page', (tester) async {
    await tester.pumpWidget(
      App(),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('should redirect to home if logged in', (tester) async {
    loginInfo.login('Username');

    await tester.pumpWidget(ChangeNotifierProvider<LoginInfo>.value(
      value: loginInfo,
      child: Builder(builder: (context) {
        final router = routerBuilder(context, '/login');

        return MaterialApp.router(
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          debugShowCheckedModeBanner: false,
        );
      }),
    ));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('should redirect to family when clicking on tile',
      (tester) async {
    final loginInfo = LoginInfo()..login('Username');
    final mockGoRouter = MockGoRouter();

    await tester.pumpWidget(
      MaterialApp(
        home: MockGoRouterProvider(
          goRouter: mockGoRouter,
          child: ChangeNotifierProvider.value(
            value: loginInfo,
            child: HomeScreen(families: Families.data),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    verify(() => mockGoRouter.go('/family/f1')).called(1);
    verifyNever(() => mockGoRouter.go('/family/f2'));
  });

  testWidgets('should redirect to PersonScreen when clicking on tile',
      (tester) async {
    final loginInfo = LoginInfo()..login('Username');
    final mockGoRouter = MockGoRouter();

    await tester.pumpWidget(
      MaterialApp(
        home: MockGoRouterProvider(
          goRouter: mockGoRouter,
          child: ChangeNotifierProvider.value(
            value: loginInfo,
            child: FamilyScreen(family: Families.data[0]),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    verify(() => mockGoRouter.go('/family/f1/person/p1')).called(1);
    verifyNever(() => mockGoRouter.go('/family/f1/person/p2'));
  });

  testWidgets('should redirect to the PersonScreen if logged in',
      (tester) async {
    loginInfo.login('Username');

    await tester.pumpWidget(ChangeNotifierProvider<LoginInfo>.value(
      value: loginInfo,
      child: Builder(builder: (context) {
        final router = routerBuilder(context, '/family/f1/person/p1');

        return MaterialApp.router(
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          debugShowCheckedModeBanner: false,
        );
      }),
    ));

    expect(find.byType(PersonScreen), findsOneWidget);
  });
}
