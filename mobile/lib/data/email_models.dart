class GeneralEmailDraft {
  final String id;
  final String recipientEmail;
  final String purpose;
  final String subject;
  final String body;
  final List<String> sourcesUsed;
  final bool toneApplied;
  final DateTime createdAt;

  const GeneralEmailDraft({
    required this.id,
    required this.recipientEmail,
    required this.purpose,
    required this.subject,
    required this.body,
    required this.sourcesUsed,
    required this.toneApplied,
    required this.createdAt,
  });

  factory GeneralEmailDraft.fromJson(Map<String, dynamic> json) =>
      GeneralEmailDraft(
        id: json['id'] as String? ?? '',
        recipientEmail: json['recipient_email'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        sourcesUsed:
            List<String>.from(json['sources_used'] as List? ?? const []),
        toneApplied: json['tone_applied'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class GeneralEmailSendResult {
  final String messageId;
  final String? threadId;
  final String sender;
  final String recipient;
  final String subject;
  final String? attachmentName;
  final DateTime sentAt;

  const GeneralEmailSendResult({
    required this.messageId,
    required this.threadId,
    required this.sender,
    required this.recipient,
    required this.subject,
    required this.attachmentName,
    required this.sentAt,
  });

  factory GeneralEmailSendResult.fromJson(Map<String, dynamic> json) =>
      GeneralEmailSendResult(
        messageId: json['message_id'] as String? ?? '',
        threadId: json['thread_id'] as String?,
        sender: json['sender'] as String? ?? '',
        recipient: json['recipient'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        attachmentName: json['attachment_name'] as String?,
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
