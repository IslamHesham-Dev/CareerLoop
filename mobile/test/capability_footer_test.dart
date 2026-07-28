import 'package:careerloop/data/models.dart';
import 'package:careerloop/ui/core/capability_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the connectors and tools used in an answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CapabilityFooter(
            sources: ['GUC transcript'],
            tools: [
              ToolActivity(
                name: 'get_full_transcript',
                status: 'completed',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sources & tools (2)'), findsOneWidget);

    await tester.tap(find.text('Sources & tools (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Connector · GUC Transcript'), findsOneWidget);
    expect(find.text('Tool · Degree History'), findsOneWidget);
  });

  testWidgets('shows the reasoning skill when no connector was needed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CapabilityFooter(
            sources: [],
            tools: [],
          ),
        ),
      ),
    );

    expect(find.text('Sources & tools (1)'), findsOneWidget);

    await tester.tap(find.text('Sources & tools (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Skill · CareerLoop reasoning'), findsOneWidget);
  });
}
