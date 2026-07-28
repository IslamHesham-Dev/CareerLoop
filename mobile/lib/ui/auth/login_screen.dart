import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/tone_profile_repository.dart';
import '../core/lens_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  int? _enrollmentYear;
  String _institution = 'giu';
  bool _obscure = true;
  int _step = 0;
  bool _isDark = true;

  // Dark palette
  static const _bgDark = Color(0xFF0B0D14);
  static const _cardDark = Color(0xFF14171F);
  static const _cardBorderDark = Color(0xFF262B38);
  static const _fieldFillDark = Color(0xFF1B1F29);
  static const _textPrimaryDark = Color(0xFFF3F4F8);
  static const _textMutedDark = Color(0xFF9298AA);

  // Light palette (same accent family, brightened surfaces)
  static const _bgLight = Color(0xFFF6F7FC);
  static const _cardLight = Color(0xFFFFFFFF);
  static const _cardBorderLight = Color(0xFFE3E5EF);
  static const _fieldFillLight = Color(0xFFF2F3F9);
  static const _textPrimaryLight = Color(0xFF14171F);
  static const _textMutedLight = Color(0xFF6B7080);

  // Shared accents (work on both backgrounds)
  static const _accentA = Color(0xFF7C6CFF);
  static const _accentB = Color(0xFF4FD6C6);

  Color get _bg => _isDark ? _bgDark : _bgLight;
  Color get _card => _isDark ? _cardDark : _cardLight;
  Color get _cardBorder => _isDark ? _cardBorderDark : _cardBorderLight;
  Color get _fieldFill => _isDark ? _fieldFillDark : _fieldFillLight;
  Color get _textPrimary => _isDark ? _textPrimaryDark : _textPrimaryLight;
  Color get _textMuted => _isDark ? _textMutedDark : _textMutedLight;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goToStepTwo() {
    if (!_stepOneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  void _backToStepOne() {
    setState(() => _step = 0);
  }

  Future<void> _submit() async {
    if (!_stepTwoFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthRepository>();
    final signedIn = await auth.signIn(
      _username.text,
      _password.text,
      _enrollmentYear!,
      _institution,
    );
    if (signedIn && mounted) {
      context.read<CareerProfileRepository>().markSessionChanged();
      context.read<GithubProfileRepository>().markSessionChanged();
      context.read<CurrentCvRepository>().markSessionChanged();
      context.read<ToneProfileRepository>().markSessionChanged();
      context.read<AcademicRepository>().loadDashboard();
      context.read<ToneProfileRepository>().ensureSynced();
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _cardBorder),
    );
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperStyle: TextStyle(color: _textMuted, fontSize: 12),
      labelStyle: TextStyle(color: _textMuted),
      prefixIcon: Icon(icon, color: _textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldFill,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentA, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0607A)),
      ),
    );
  }

  // String _subtitleFor(String university) {
  //   return 'Every $university course and career move you add builds toward the same private profile.';
  // }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final university = _institution.toUpperCase();

    return Theme(
      data: (_isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _accentA,
          selectionColor: Color(0x557C6CFF),
          selectionHandleColor: _accentA,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
          Builder(
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  final glowSize = size.shortestSide * 0.55;
                  return Positioned(
                    top: -glowSize * 0.35,
                    left: -glowSize * 0.3,
                    child: _glow(_accentA, glowSize),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  final glowSize = size.shortestSide * 0.6;
                  return Positioned(
                    bottom: -glowSize * 0.4,
                    right: -glowSize * 0.35,
                    child: _glow(_accentB, glowSize),
                  );
                },
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Crop LensLogo down to just its icon
                                    // mark — its built-in wordmark text is
                                    // hardcoded and doesn't adapt to dark
                                    // mode, so we hide it and use our own
                                    // theme-aware label instead.
                                    ClipRect(
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: LensLogo(size: 52),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Career Loop',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),
                              ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(
                                  colors: [_accentA, _accentB],
                                ).createShader(rect),
                                child: const Text(
                                  'Your Work \n Tells Your Story.',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // const SizedBox(height: 16),
                              // Text(
                              //   _subtitleFor(university),
                              //   style: TextStyle(
                              //     color: _textMuted,
                              //     fontSize: 15,
                              //     height: 1.6,
                              //     letterSpacing: 0.1,
                              //   ),
                              // ),
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentA.withValues(
                                        alpha: _isDark ? .12 : .10,
                                      ),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _step == 0
                                      ? KeyedSubtree(
                                          key: const ValueKey('step-one'),
                                          child:
                                              _buildStepOne(auth, university),
                                        )
                                      : KeyedSubtree(
                                          key: const ValueKey('step-two'),
                                          child: _buildStepTwo(auth),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 18, color: _textMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your credentials are used only to start a read only portal session. Career Loop does not store your password.',
                                      style: TextStyle(
                                        color: _textMuted,
                                        fontSize: 12.5,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(color: _cardBorder),
                              const SizedBox(height: 14),
                              Text(
                                'Your Career Loop journey begins with your university Student Portal.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: _textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Kept as the LAST Stack child so it renders on top and
              // actually receives taps — it was being covered by the
              // scroll view before.
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip:
                      _isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  onPressed: () => setState(() => _isDark = !_isDark),
                  icon: Icon(
                    _isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: _isDark ? .30 : .12),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne(AuthRepository auth, String university) {
    return AutofillGroup(
      child: Form(
        key: _stepOneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'University login',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _accentA.withValues(alpha: .18);
                  }
                  return _fieldFill;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _accentA;
                  }
                  return _textMuted;
                }),
                side: WidgetStateProperty.all(BorderSide(color: _cardBorder)),
              ),
              segments: const [
                ButtonSegment(
                  value: 'giu',
                  label: Text('GIU'),
                  icon: Icon(Icons.school_outlined, size: 18),
                ),
                ButtonSegment(
                  value: 'guc',
                  label: Text('GUC'),
                  icon: Icon(Icons.account_balance_outlined, size: 18),
                ),
              ],
              selected: {_institution},
              showSelectedIcon: false,
              onSelectionChanged: auth.isBusy
                  ? null
                  : (selection) =>
                      setState(() => _institution = selection.first),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _username,
              style: TextStyle(color: _textPrimary),
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                label: 'Username',
                icon: Icons.person_outline_rounded,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your $university username'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              style: TextStyle(color: _textPrimary),
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _goToStepTwo(),
              decoration: _fieldDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _textMuted,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your $university password'
                  : null,
            ),
            const SizedBox(height: 20),
            _gradientButton(
                label: 'Continue', busy: false, onPressed: _goToStepTwo),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo(AuthRepository auth) {
    return Form(
      key: _stepTwoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: auth.isBusy ? null : _backToStepOne,
                icon: Icon(Icons.arrow_back_rounded, color: _textPrimary),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Text(
                'Enrollment year',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _enrollmentYear,
            isExpanded: true,
            dropdownColor: _card,
            style: TextStyle(color: _textPrimary),
            decoration: _fieldDecoration(
              label: 'Enrollment year',
              icon: Icons.school_outlined,
              helperText:
                  'Loads four academic transcript years from this date.',
            ),
            items: [
              for (var year = DateTime.now().year; year >= 2000; year--)
                DropdownMenuItem(value: year, child: Text('$year')),
            ],
            onChanged: auth.isBusy
                ? null
                : (year) => setState(() => _enrollmentYear = year),
            validator: (value) =>
                value == null ? 'Select the year you enrolled' : null,
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFE0607A).withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0607A).withValues(alpha: .3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFE0607A), size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                        color: Color(0xFFE0607A),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _gradientButton(
            label: 'Continue',
            busy: auth.isBusy,
            onPressed: auth.isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool busy,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: onPressed == null
            ? null
            : const LinearGradient(colors: [_accentA, _accentB]),
        color: onPressed == null ? _fieldFill : null,
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: _accentA.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
