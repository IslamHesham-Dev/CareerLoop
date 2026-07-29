import 'package:careerloop/ui/core/content_ai_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('job-style overlay preserves draft text while minimized',
      (tester) async {
    final controller = ContentAiOverlayController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentAiOverlay(
            controller: controller,
            title: 'CareerLoop Copilot',
            subtitle: 'Software Engineer · Example',
            contextInstruction: 'Stay grounded in this job.',
            quickActions: const [],
            onSend: (_) async => null,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'How should I position my projects?',
    );

    await tester.tap(find.byTooltip('Minimize assistant'));
    await tester.pumpAndSettle();
    controller.open();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'How should I position my projects?',
    );
  });
}
