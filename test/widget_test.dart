import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_mobile/main.dart';

void main() {
  testWidgets('starter app opens', (tester) async {
    await tester.pumpWidget(const StarterApp());
    expect(find.text('Alumni app setup'), findsOneWidget);
  });
}
