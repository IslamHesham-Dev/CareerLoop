import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
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
  bool _isDark = false;
  int _step = 0;

  Color get _bg => _isDark ? const Color(0xFF090F21) : LensColors.canvas;
  Color get _card => _isDark ? const Color(0xFF121A30) : LensColors.card;
  Color get _cardBorder => _isDark ? const Color(0xFF29324D) : LensColors.line;
  Color get _fieldFill =>
      _isDark ? const Color(0xFF0D1428) : const Color(0xFFFBFCFD);
  Color get _textPrimary => _isDark ? Colors.white : LensColors.ink;
  Color get _textMuted => _isDark ? const Color(0xFF9AA4BF) : LensColors.muted;
  static const _accentA = LensColors.indigo;

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

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        Row(
                          children: [
                            Expanded(
                              child: LensLogo(
                                size: 46,
                                wordmarkColor: _textPrimary,
                              ),
                            ),
                            IconButton(
                              tooltip: _isDark
                                  ? 'Switch to light mode'
                                  : 'Switch to dark mode',
                              onPressed: () =>
                                  setState(() => _isDark = !_isDark),
                              icon: Icon(
                                _isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _step == 0
                              ? 'Sign in to your university'
                              : 'Complete your academic context',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: _textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == 0
                              ? 'Use the same account you use for the '
                                  '$university student portal.'
                              : 'Your enrollment year lets Career Loop load '
                                  'the correct transcript history.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _textMuted,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StepIndicator(
                                active: true,
                                label: 'University account',
                                dark: _isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StepIndicator(
                                active: _step == 1,
                                label: 'Enrollment year',
                                dark: _isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _step == 0
                                ? KeyedSubtree(
                                    key: const ValueKey('step-one'),
                                    child: _buildStepOne(auth, university),
                                  )
                                : KeyedSubtree(
                                    key: const ValueKey('step-two'),
                                    child: _buildStepTwo(auth),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: _textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Credentials establish a read-only portal '
                                'session and are never sent to the AI.',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
            _primaryButton(
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
          _primaryButton(
            label: 'Continue',
            busy: auth.isBusy,
            onPressed: auth.isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool busy,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: busy || onPressed != null ? _accentA : _fieldFill,
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
                    style: TextStyle(
                      color: onPressed == null ? _textMuted : Colors.white,
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

class _StepIndicator extends StatelessWidget {
  final bool active;
  final String label;
  final bool dark;

  const _StepIndicator({
    required this.active,
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: active
                ? LensColors.indigo
                : dark
                    ? const Color(0xFF29324D)
                    : LensColors.line,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: active
                ? (dark ? Colors.white : LensColors.ink)
                : (dark ? const Color(0xFF9AA4BF) : LensColors.muted),
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
