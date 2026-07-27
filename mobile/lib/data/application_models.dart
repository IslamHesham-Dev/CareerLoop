class CurrentCv {
  final String fileName;
  final String localPath;
  final int sizeBytes;
  final DateTime importedAt;

  const CurrentCv({
    required this.fileName,
    required this.localPath,
    required this.sizeBytes,
    required this.importedAt,
  });

  factory CurrentCv.fromJson(
    Map<String, dynamic> json, {
    required String localPath,
  }) =>
      CurrentCv(
        fileName: json['file_name'] as String? ?? 'Current_CV.pdf',
        localPath: localPath,
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
        importedAt: DateTime.tryParse(json['imported_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'size_bytes': sizeBytes,
        'imported_at': importedAt.toUtc().toIso8601String(),
      };
}

class ApplicationDraft {
  final String id;
  final String linkedInPostUrl;
  final String contentSource;
  final String postExcerpt;
  final String role;
  final String? company;
  final String? contactName;
  final String? detectedContactEmail;
  final String recipient;
  final bool prototypeRecipientLocked;
  final String subject;
  final String body;
  final String? senderEmail;
  final bool gmailConnected;
  final List<String> warnings;

  const ApplicationDraft({
    required this.id,
    required this.linkedInPostUrl,
    required this.contentSource,
    required this.postExcerpt,
    required this.role,
    required this.company,
    required this.contactName,
    required this.detectedContactEmail,
    required this.recipient,
    required this.prototypeRecipientLocked,
    required this.subject,
    required this.body,
    required this.senderEmail,
    required this.gmailConnected,
    required this.warnings,
  });

  factory ApplicationDraft.fromJson(Map<String, dynamic> json) =>
      ApplicationDraft(
        id: json['id'] as String? ?? '',
        linkedInPostUrl: json['linkedin_post_url'] as String? ?? '',
        contentSource: json['content_source'] as String? ?? '',
        postExcerpt: json['post_excerpt'] as String? ?? '',
        role: json['role'] as String? ?? 'Advertised position',
        company: json['company'] as String?,
        contactName: json['contact_name'] as String?,
        detectedContactEmail: json['detected_contact_email'] as String?,
        recipient: json['recipient'] as String? ?? '',
        prototypeRecipientLocked:
            json['prototype_recipient_locked'] as bool? ?? true,
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        senderEmail: json['sender_email'] as String?,
        gmailConnected: json['gmail_connected'] as bool? ?? false,
        warnings: List<String>.from(json['warnings'] as List? ?? const []),
      );
}

class ApplicationSendResult {
  final String messageId;
  final String? threadId;
  final String sender;
  final String recipient;
  final String subject;
  final String attachmentName;
  final DateTime sentAt;

  const ApplicationSendResult({
    required this.messageId,
    required this.threadId,
    required this.sender,
    required this.recipient,
    required this.subject,
    required this.attachmentName,
    required this.sentAt,
  });

  factory ApplicationSendResult.fromJson(Map<String, dynamic> json) =>
      ApplicationSendResult(
        messageId: json['message_id'] as String? ?? '',
        threadId: json['thread_id'] as String?,
        sender: json['sender'] as String? ?? '',
        recipient: json['recipient'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        attachmentName: json['attachment_name'] as String? ?? '',
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
