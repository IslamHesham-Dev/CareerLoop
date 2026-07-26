import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'lens_components.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AuroraBackground(child: navigationShell),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: LensColors.ink.withValues(alpha: .08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                height: 68,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                indicatorColor: LensColors.indigo.withValues(alpha: 0.12),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.all_inclusive_outlined, size: 22),
                    selectedIcon: Icon(Icons.all_inclusive_rounded, size: 22, color: LensColors.indigo),
                    label: 'Loop',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined, size: 22),
                    selectedIcon: Icon(Icons.auto_stories_rounded, size: 22, color: LensColors.indigo),
                    label: 'Learn',
                  ),
                  NavigationDestination(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LensColors.indigo,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LensColors.indigo.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                    ),
                    label: 'Copilot',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.rocket_launch_outlined, size: 22),
                    selectedIcon: Icon(Icons.rocket_launch_rounded, size: 22, color: LensColors.violet),
                    label: 'Career',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded, size: 22),
                    selectedIcon: Icon(Icons.person_rounded, size: 22, color: LensColors.ink),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
