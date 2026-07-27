import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'application_models.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'github_profile_repository.dart';

class ApplicationRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;

  bool gmailAvailable = false;
  bool gmailConnected = false;
  String? gmailEmail;
  String? configurationMessage;
  bool checkingGmail = false;
  bool analyzing = false;
  bool sending = false;
  String? error;
  ApplicationDraft? draft;
  ApplicationSendResult? sent;

  ApplicationRepository({
    required this.api,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
  });

  Future<bool> refreshGmailStatus() async {
    checkingGmail = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.get('/v1/integrations/gmail/status');
      gmailAvailable = json['available'] as bool? ?? false;
      gmailConnected = json['connected'] as bool? ?? false;
      gmailEmail = json['email'] as String?;
      configurationMessage = json['configuration_message'] as String?;
      return gmailConnected;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The Gmail connection could not be checked.';
      return false;
    } finally {
      checkingGmail = false;
      notifyListeners();
    }
  }

  Future<Uri?> beginGmailConnection({bool reconnect = false}) async {
    checkingGmail = true;
    error = null;
    notifyListeners();
    try {
      if (reconnect) {
        await api.post('/v1/integrations/gmail/disconnect');
        gmailConnected = false;
        gmailEmail = null;
      }
      final json = await api.post('/v1/integrations/gmail/connect');
      gmailConnected = json['connected'] as bool? ?? false;
      final value = json['authorization_url'] as String?;
      return value == null ? null : Uri.tryParse(value);
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Google authorization could not be started.';
      return null;
    } finally {
      checkingGmail = false;
      notifyListeners();
    }
  }

  Future<ApplicationDraft?> analyze({
    required String linkedInPostUrl,
    required String postText,
  }) async {
    if (analyzing) return null;
    analyzing = true;
    error = null;
    sent = null;
    notifyListeners();
    try {
      await Future.wait([
        careerProfileRepository.ensureSynced(),
        githubProfileRepository.ensureSynced(),
      ]);
      final json = await api.post(
        '/v1/career/applications/preview',
        body: {
          'linkedin_post_url': linkedInPostUrl.trim(),
          if (postText.trim().isNotEmpty) 'post_text': postText.trim(),
        },
      );
      draft = ApplicationDraft.fromJson(json);
      gmailConnected = draft!.gmailConnected;
      gmailEmail = draft!.senderEmail;
      return draft;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'CareerLoop could not prepare this application.';
      return null;
    } finally {
      analyzing = false;
      notifyListeners();
    }
  }

  Future<ApplicationSendResult?> send({
    required String subject,
    required String body,
  }) async {
    final activeDraft = draft;
    final cv = currentCvRepository.currentCv;
    if (activeDraft == null || cv == null || sending) return null;
    sending = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.uploadFile(
        '/v1/career/applications/send',
        fieldName: 'cv',
        filePath: cv.localPath,
        filename: cv.fileName,
        fields: {
          'application_id': activeDraft.id,
          'subject': subject.trim(),
          'body': body.trim(),
        },
      );
      sent = ApplicationSendResult.fromJson(json);
      return sent;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Gmail could not send this application.';
      return null;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    draft = null;
    sent = null;
    error = null;
    notifyListeners();
  }
}
