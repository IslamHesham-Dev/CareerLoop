import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lens_components.dart';

class CareerLoopStartupScreen extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const CareerLoopStartupScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<CareerLoopStartupScreen> createState() =>
      _CareerLoopStartupScreenState();
}

class _CareerLoopStartupScreenState extends State<CareerLoopStartupScreen> {
  static const _messages = [
    'Opening your secure workspace',
    'Restoring your profile',
    'Connecting your academic and career context',
  ];

  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.errorMessage != null) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0D14),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D14),
        body: Stack(
          children: [
            const Positioned.fill(child: _StartupBackdrop()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LensLogo(
                          size: 112,
                          showWordmark: false,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Career Loop',
                          style: TextStyle(
                            color: Color(0xFFF3F4F8),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Academic intelligence. Career momentum.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9298AA),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 38),
                        if (error == null) ...[
                          const _GradientSpinner(),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(
                              _messages[_messageIndex],
                              key: ValueKey(_messageIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB5BAC8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Color(0xFF4FD6C6),
                            size: 30,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB5BAC8),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: widget.onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF7C6CFF),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupBackdrop extends StatelessWidget {
  const _StartupBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17172B),
            Color(0xFF0B0D14),
            Color(0xFF102522),
          ],
          stops: [0, .52, 1],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            left: -110,
            child: _Glow(color: Color(0xFF7C6CFF), size: 300),
          ),
          Positioned(
            right: -130,
            bottom: -130,
            child: _Glow(color: Color(0xFF4FD6C6), size: 320),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .22), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GradientSpinner extends StatelessWidget {
  const _GradientSpinner();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF7C6CFF), Color(0xFF4FD6C6)],
      ).createShader(bounds),
      child: const SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.white,
        ),
      ),
    );
  }
}
