import 'package:flutter_test/flutter_test.dart';

import 'package:simorgh/app.dart';

void main() {
  testWidgets('renders the Simorgh desktop shell', (tester) async {
    await tester.pumpWidget(const SimorghApp());
    expect(find.textContaining('Simorgh'), findsOneWidget);
    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('تونل فعال'), findsOneWidget);
  });
}
