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

  static const _bg = Color(0xFF0B0D14);
  static const _card = Color(0xFF14171F);
  static const _cardBorder = Color(0xFF262B38);
  static const _accentA = Color(0xFF7C6CFF);
  static const _accentB = Color(0xFF4FD6C6);
  static const _textPrimary = Color(0xFFF3F4F8);
  static const _textMuted = Color(0xFF9298AA);
  static const _fieldFill = Color(0xFF1B1F29);

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
      borderSide: const BorderSide(color: _cardBorder),
    );
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperStyle: const TextStyle(color: _textMuted, fontSize: 12),
      labelStyle: const TextStyle(color: _textMuted),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final university = _institution.toUpperCase();

    return Theme(
      data: ThemeData.dark().copyWith(
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
              // Ambient glow blobs
              Positioned(
                top: -120,
                left: -80,
                child: _glow(_accentA, 320),
              ),
              Positioned(
                bottom: -140,
                right: -100,
                child: _glow(_accentB, 360),
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
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: LensLogo(size: 52),
                              ),
                              const SizedBox(height: 48),
                              ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(
                                  colors: [_accentA, _accentB],
                                ).createShader(rect),
                                child: const Text(
                                  'Start your\nevidence loop.',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Connect verified $university academic evidence now. Career signals join the same private profile as you add them.',
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentA.withValues(alpha: .12),
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
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 18, color: _textMuted),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your credentials are used only to start a short-lived, read-only portal session. CareerLoop does not store your password.',
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
                              const Divider(color: _cardBorder),
                              const SizedBox(height: 14),
                              Text(
                                'Your first CareerLoop evidence source is the $university Student Portal.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: _textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
            colors: [color.withValues(alpha: .35), color.withValues(alpha: 0)],
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
            const Text(
              'University connection',
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
                side: WidgetStateProperty.all(
                  const BorderSide(color: _cardBorder),
                ),
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
              style: const TextStyle(color: _textPrimary),
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
              style: const TextStyle(color: _textPrimary),
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
              label: 'Continue',
              busy: false,
              onPressed: _goToStepTwo,
            ),
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
                icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Text(
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
            style: const TextStyle(color: _textPrimary),
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
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../app/theme.dart';
// import '../../data/repositories.dart';
// import '../../data/career_profile_repository.dart';
// import '../../data/current_cv_repository.dart';
// import '../../data/github_profile_repository.dart';
// import '../core/lens_components.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _stepOneFormKey = GlobalKey<FormState>();
//   final _stepTwoFormKey = GlobalKey<FormState>();
//   final _username = TextEditingController();
//   final _password = TextEditingController();
//   int? _enrollmentYear;
//   String _institution = 'giu';
//   bool _obscure = true;
//   int _step = 0; // 0 = credentials, 1 = enrollment year

//   @override
//   void dispose() {
//     _username.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   void _goToStepTwo() {
//     if (!_stepOneFormKey.currentState!.validate()) return;
//     FocusScope.of(context).unfocus();
//     setState(() => _step = 1);
//   }

//   void _backToStepOne() {
//     setState(() => _step = 0);
//   }

//   Future<void> _submit() async {
//     if (!_stepTwoFormKey.currentState!.validate()) return;
//     FocusScope.of(context).unfocus();
//     final auth = context.read<AuthRepository>();
//     final signedIn = await auth.signIn(
//       _username.text,
//       _password.text,
//       _enrollmentYear!,
//       _institution,
//     );
//     if (signedIn && mounted) {
//       context.read<CareerProfileRepository>().markSessionChanged();
//       context.read<GithubProfileRepository>().markSessionChanged();
//       context.read<CurrentCvRepository>().markSessionChanged();
//       context.read<AcademicRepository>().loadDashboard();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthRepository>();
//     final university = _institution.toUpperCase();
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FC),
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minHeight: constraints.maxHeight - 48,
//                 ),
//                 child: Center(
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 420),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Align(
//                           alignment: Alignment.centerLeft,
//                           child: LensLogo(size: 52),
//                         ),
//                         const SizedBox(height: 48),
//                         Text(
//                           'Start your\nevidence loop.',
//                           style: Theme.of(context)
//                               .textTheme
//                               .displaySmall
//                               ?.copyWith(fontSize: 34),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Connect verified $university academic evidence now. Career signals join the same private profile as you add them.',
//                           style: TextStyle(
//                             color: LensColors.muted,
//                             fontSize: 15,
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 28),
//                         Container(
//                           padding: const EdgeInsets.all(24),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: LensColors.line),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: LensColors.ink.withValues(alpha: .045),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                           ),
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 220),
//                             child: _step == 0
//                                 ? KeyedSubtree(
//                                     key: const ValueKey('step-one'),
//                                     child: _buildStepOne(auth, university),
//                                   )
//                                 : KeyedSubtree(
//                                     key: const ValueKey('step-two'),
//                                     child: _buildStepTwo(auth),
//                                   ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(
//                               Icons.lock_outline_rounded,
//                               size: 18,
//                               color: LensColors.muted,
//                             ),
//                             SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 'Your credentials are used only to start a short-lived, read-only portal session. CareerLoop does not store your password.',
//                                 style: TextStyle(
//                                   color: LensColors.muted,
//                                   fontSize: 12.5,
//                                   height: 1.45,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         const Divider(color: LensColors.line),
//                         const SizedBox(height: 14),
//                         Text(
//                           'Your first CareerLoop evidence source is the $university Student Portal.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: LensColors.muted,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildStepOne(AuthRepository auth, String university) {
//     return AutofillGroup(
//       child: Form(
//         key: _stepOneFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'University connection',
//               style: TextStyle(
//                 color: LensColors.ink,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SegmentedButton<String>(
//               segments: const [
//                 ButtonSegment(
//                   value: 'giu',
//                   label: Text('GIU'),
//                   icon: Icon(Icons.school_outlined, size: 18),
//                 ),
//                 ButtonSegment(
//                   value: 'guc',
//                   label: Text('GUC'),
//                   icon: Icon(Icons.account_balance_outlined, size: 18),
//                 ),
//               ],
//               selected: {_institution},
//               showSelectedIcon: false,
//               onSelectionChanged: auth.isBusy
//                   ? null
//                   : (selection) => setState(() => _institution = selection.first),
//             ),
//             const SizedBox(height: 18),
//             TextFormField(
//               controller: _username,
//               autofillHints: const [AutofillHints.username],
//               textInputAction: TextInputAction.next,
//               decoration: const InputDecoration(
//                 labelText: 'Username',
//                 prefixIcon: Icon(Icons.person_outline_rounded),
//               ),
//               validator: (value) => value == null || value.trim().isEmpty
//                   ? 'Enter your $university username'
//                   : null,
//             ),
//             const SizedBox(height: 14),
//             TextFormField(
//               controller: _password,
//               obscureText: _obscure,
//               autofillHints: const [AutofillHints.password],
//               textInputAction: TextInputAction.done,
//               onFieldSubmitted: (_) => _goToStepTwo(),
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 prefixIcon: const Icon(Icons.lock_outline_rounded),
//                 suffixIcon: IconButton(
//                   tooltip: _obscure ? 'Show password' : 'Hide password',
//                   onPressed: () => setState(() => _obscure = !_obscure),
//                   icon: Icon(
//                     _obscure
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                   ),
//                 ),
//               ),
//               validator: (value) => value == null || value.isEmpty
//                   ? 'Enter your $university password'
//                   : null,
//             ),
//             const SizedBox(height: 18),
//             FilledButton(
//               onPressed: _goToStepTwo,
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStepTwo(AuthRepository auth) {
//     return Form(
//       key: _stepTwoFormKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 onPressed: auth.isBusy ? null : _backToStepOne,
//                 icon: const Icon(Icons.arrow_back_rounded),
//                 tooltip: 'Back',
//               ),
//               const SizedBox(width: 4),
//               const Text(
//                 'Enrollment year',
//                 style: TextStyle(
//                   color: LensColors.ink,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           DropdownButtonFormField<int>(
//             value: _enrollmentYear,
//             isExpanded: true,
//             decoration: const InputDecoration(
//               labelText: 'Enrollment year',
//               helperText: 'Loads four academic transcript years from this date.',
//               prefixIcon: Icon(Icons.school_outlined),
//             ),
//             items: [
//               for (var year = DateTime.now().year; year >= 2000; year--)
//                 DropdownMenuItem(value: year, child: Text('$year')),
//             ],
//             onChanged: auth.isBusy
//                 ? null
//                 : (year) => setState(() => _enrollmentYear = year),
//             validator: (value) =>
//                 value == null ? 'Select the year you enrolled' : null,
//           ),
//           if (auth.error != null) ...[
//             const SizedBox(height: 14),
//             Container(
//               padding: const EdgeInsets.all(13),
//               decoration: BoxDecoration(
//                 color: LensColors.rose.withValues(alpha: .08),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: LensColors.rose.withValues(alpha: .18)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(
//                     Icons.error_outline_rounded,
//                     color: Color(0xFFA53B52),
//                     size: 19,
//                   ),
//                   const SizedBox(width: 9),
//                   Expanded(
//                     child: Text(
//                       auth.error!,
//                       style: const TextStyle(
//                         color: Color(0xFFA53B52),
//                         fontSize: 13,
//                         height: 1.35,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           const SizedBox(height: 18),
//           FilledButton(
//             onPressed: auth.isBusy ? null : _submit,
//             child: auth.isBusy
//                 ? const SizedBox(
//                     width: 22,
//                     height: 22,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.4,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text('Continue'),
//           ),
//         ],
//       ),
//     );
//   }
// }
