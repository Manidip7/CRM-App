/// What the WhatsApp draft is about, which decides the middle sentence: a lead
/// is a first approach, an opportunity is a follow-up on something already
/// being discussed.
enum WhatsAppIntent { lead, opportunity }

/// Builds the message WhatsApp opens pre-filled with, so the rep starts from a
/// polite, on-brand draft instead of a blank chat.
///
/// Nothing here is mandatory: any part the CRM doesn't know about is left out
/// rather than sent as an empty gap, so the worst case is still a sensible
/// short greeting. The text is a *draft* — it lands in WhatsApp's input box
/// where it can be edited before sending, never sent automatically.
///
/// ```
/// Hi Ram,
///
/// This is Manidip from PeploCRM. Thank you for your interest in Website
/// Design — I'd be happy to share the details and answer any questions.
///
/// Would this be a good time to talk?
/// ```
String buildWhatsAppMessage({
  required WhatsAppIntent intent,
  String? contactName,
  String? senderName,
  String? senderCompany,
  String? topic,
}) {
  final buffer = StringBuffer('Hi ${_firstName(contactName) ?? 'there'},\n\n');

  final sender = _sender(senderName, senderCompany);
  final subject = _clean(topic);

  switch (intent) {
    case WhatsAppIntent.lead:
      if (sender != null) buffer.write('$sender. ');
      buffer.write(
        subject == null
            ? 'Thank you for getting in touch'
            : 'Thank you for your interest in $subject',
      );
      buffer.write(
        ' — I\'d be happy to share the details and answer any questions.',
      );
    case WhatsAppIntent.opportunity:
      if (sender != null) buffer.write('$sender. ');
      buffer.write(
        subject == null
            ? 'I\'m following up on our recent discussion'
            : 'I\'m following up on $subject',
      );
      buffer.write(
        ' — I\'d be happy to walk you through the details and answer any '
        'questions.',
      );
  }

  buffer.write('\n\nWould this be a good time to talk?');
  return buffer.toString();
}

/// "This is Manidip from PeploCRM" — trimmed down to whichever half is known.
String? _sender(String? name, String? company) {
  final who = _firstName(name) == null ? null : _clean(name);
  final where = _clean(company);
  if (who != null && where != null) return 'This is $who from $where';
  if (who != null) return 'This is $who';
  if (where != null) return 'I\'m reaching out from $where';
  return null;
}

/// Only the first word of a name: "Ram Kumar Sharma" → "Ram". A greeting reads
/// as canned the moment it uses somebody's full legal name.
String? _firstName(String? full) {
  final name = _clean(full);
  if (name == null) return null;
  final first = name.split(RegExp(r'\s+')).first;
  return first.isEmpty ? null : first;
}

String? _clean(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
