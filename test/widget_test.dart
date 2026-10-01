import 'package:flutter_test/flutter_test.dart';

import 'package:smart_healthcare_patient/main.dart';

void main() {
  testWidgets('Smart Healthcare Patient app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SmartHealthcarePatientApp(),
    );

    expect(find.text('Patient Login'), findsOneWidget);
  });
}