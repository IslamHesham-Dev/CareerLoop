import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'email_models.dart';
import 'github_profile_repository.dart';
import 'tone_profile_repository.dart';

class EmailRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;
  final ToneProfileRepository toneProfileRepository;

  bool drafting = false;
  bool sending = false;
  String? error;
  GeneralEmailDraft? draft;
  GeneralEmailSendResult? sent;

  EmailRepository({
    required this.api,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
    required this.toneProfileRepository,
  });

  void reviewDraft(GeneralEmailDraft value) {
    draft = value;
    sent = null;
    error = null;
    notifyListeners();
  }

  Future<GeneralEmailDraft?> preview({
    required String recipientEmail,
    required String senderName,
    required String purpose,
    String customInput = '',
  }) async {
    if (drafting) return null;
    drafting = true;
    error = null;
    sent = null;
    notifyListeners();
    try {
      await Future.wait([
        careerProfileRepository.ensureSynced(),
        githubProfileRepository.ensureSynced(),
        currentCvRepository.ensureSynced(),
        toneProfileRepository.ensureSynced(),
      ]);
      final json = await api.post(
        '/v1/career/emails/preview',
        body: {
          'recipient_email': recipientEmail.trim(),
          'sender_name': senderName.trim(),
          'purpose': purpose.trim(),
          'custom_input': customInput.trim(),
        },
      );
      draft = GeneralEmailDraft.fromJson(json);
      return draft;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'CareerLoop could not prepare this email.';
      return null;
    } finally {
      drafting = false;
      notifyListeners();
    }
  }

  Future<GeneralEmailSendResult?> send({
    required String subject,
    required String body,
    required bool attachResume,
  }) async {
    final activeDraft = draft;
    if (activeDraft == null || sending) return null;
    final cv = currentCvRepository.currentCv;
    if (attachResume && cv == null) {
      error = 'Import or generate a resume before attaching it.';
      notifyListeners();
      return null;
    }
    sending = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.uploadFiles(
        '/v1/career/emails/${activeDraft.id}/send',
        files: [
          if (attachResume && cv != null)
            UploadFilePart(
              fieldName: 'cv',
              filePath: cv.localPath,
              filename: cv.fileName,
            ),
        ],
        fields: {
          'subject': subject.trim(),
          'body': body.trim(),
        },
      );
      sent = GeneralEmailSendResult.fromJson(json);
      return sent;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Gmail could not send this email.';
      return null;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void reset() {
    draft = null;
    sent = null;
    error = null;
    notifyListeners();
  }
}
