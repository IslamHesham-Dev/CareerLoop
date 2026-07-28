import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
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
  int _step = 0; // 0 = credentials, 1 = enrollment year

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
      context.read<AcademicRepository>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final university = _institution.toUpperCase();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
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
                        Text(
                          'Start your\nevidence loop.',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Connect verified $university academic evidence now. Career signals join the same private profile as you add them.',
                          style: TextStyle(
                            color: LensColors.muted,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: LensColors.line),
                            boxShadow: [
                              BoxShadow(
                                color: LensColors.ink.withValues(alpha: .045),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
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
                        const SizedBox(height: 20),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: LensColors.muted,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your credentials are used only to start a short-lived, read-only portal session. CareerLoop does not store your password.',
                                style: TextStyle(
                                  color: LensColors.muted,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: LensColors.line),
                        const SizedBox(height: 14),
                        Text(
                          'Your first CareerLoop evidence source is the $university Student Portal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: LensColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
                color: LensColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
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
                  : (selection) => setState(() => _institution = selection.first),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _username,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your $university username'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _goToStepTwo(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your $university password'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _goToStepTwo,
              child: const Text('Continue'),
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
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Text(
                'Enrollment year',
                style: TextStyle(
                  color: LensColors.ink,
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
            decoration: const InputDecoration(
              labelText: 'Enrollment year',
              helperText: 'Loads four academic transcript years from this date.',
              prefixIcon: Icon(Icons.school_outlined),
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
                color: LensColors.rose.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LensColors.rose.withValues(alpha: .18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFA53B52),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                        color: Color(0xFFA53B52),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: auth.isBusy ? null : _submit,
            child: auth.isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
