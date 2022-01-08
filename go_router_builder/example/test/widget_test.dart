import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_builder_example/main.dart';

void main() {
  testWidgets('Validate extra logic walkthrough', (tester) async {
    await tester.pumpWidget(App());

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sells'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chris'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('hobbies - coding'));
    await tester.pumpAndSettle();

    expect(find.text('No extra click!'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('With extra...').first);
    await tester.pumpAndSettle();

    expect(find.text('Extra click count: 1'), findsOneWidget);
  });
}
