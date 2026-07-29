import 'package:careerloop/ui/core/content_ai_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('controller prompts are prepared as drafts without sending',
      (tester) async {
    final controller = ContentAiOverlayController();
    var sendCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentAiOverlay(
            controller: controller,
            title: 'Ask CareerLoop',
            subtitle: 'Software Engineer · Example',
            contextInstruction: 'Stay grounded in this job.',
            quickActions: const [],
            onSend: (_) async {
              sendCount += 1;
              return null;
            },
            showLauncher: false,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    controller.open(prompt: 'Challenge my readiness for this role.');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Challenge my readiness for this role.',
    );
    expect(sendCount, 0);
  });

  testWidgets('job-style overlay preserves draft text while minimized',
      (tester) async {
    final controller = ContentAiOverlayController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentAiOverlay(
            controller: controller,
            title: 'Ask CareerLoop',
            subtitle: 'Software Engineer · Example',
            contextInstruction: 'Stay grounded in this job.',
            quickActions: const [],
            onSend: (_) async => null,
            showLauncher: false,
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
    expect(find.bySemanticsLabel('Open Ask CareerLoop'), findsNothing);

    controller.open();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'How should I position my projects?',
    );
  });
}
