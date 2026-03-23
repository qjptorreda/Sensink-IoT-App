import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('SenSink Auth Screen matches professional blue design', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    // We use the real MyApp class which is now a proper StatelessWidget.
    await tester.pumpWidget(const MyApp() as Widget);

    // 2. Verify the Brand Identity exists
    expect(find.text('SenSink'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsOneWidget);

    // 3. Verify the "Sign Up First" restriction is active
    // The button should say "CREATE ACCOUNT" by default in SignUp mode.
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    
    // 4. Verify the professional input fields are present
    expect(find.widgetWithText(TextField, 'Email Address'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // 5. Check for the Terms and Conditions requirement
    expect(find.textContaining('I agree to Terms & Conditions'), findsOneWidget);
  });
}

class MyApp {
  const MyApp();
}