import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models.dart';

class PracticeLaunchCard extends StatelessWidget {
  final PracticeSet practiceSet;

  const PracticeLaunchCard({
    super.key,
    required this.practiceSet,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LensColors.violet.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          '/practice/session',
          extra: practiceSet,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: LensColors.indigo,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice set ready',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${practiceSet.questions.length} MCQs · '
                      '${practiceSet.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Practice',
                style: TextStyle(
                  color: LensColors.indigo,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: LensColors.indigo,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
