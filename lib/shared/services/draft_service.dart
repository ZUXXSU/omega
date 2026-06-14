import '../database/omega_database.dart';

/// Result returned by [DraftService.getDraft].
class DraftResult {
  const DraftResult({
    required this.text,
    this.quotedMessageId,
    this.quotedText,
    this.savedAt,
  });

  final String text;
  final int? quotedMessageId;
  final String? quotedText;
  final DateTime? savedAt;

  bool get hasQuote => quotedMessageId != null;

  @override
  String toString() =>
      'DraftResult(text: "$text", quotedMessageId: $quotedMessageId)';
}

/// Pure-Dart service for persisting and retrieving per-chat message drafts.
///
/// All operations are async and isolate-safe (no BuildContext used).
///
/// Typical usage in the chat input bar:
/// ```dart
/// // On chat open:
/// final draft = await DraftService.instance.getDraft(accountId, chatId);
/// controller.text = draft?.text ?? '';
///
/// // On text change (debounced):
/// await DraftService.instance.saveDraft(accountId, chatId, controller.text);
///
/// // On message send:
/// await DraftService.instance.clearDraft(accountId, chatId);
/// ```
class DraftService {
  DraftService._();

  static final DraftService instance = DraftService._();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persist a draft for the given [accountId] / [chatId] pair.
  ///
  /// If [text] is empty and there is no quoted message, the existing draft
  /// is cleared instead of saving an empty record.
  Future<void> saveDraft(
    int accountId,
    int chatId,
    String text, {
    int? quotedMessageId,
    String? quotedText,
  }) async {
    final trimmed = text.trim();

    // If both the text and the quote are empty, just clear.
    if (trimmed.isEmpty && quotedMessageId == null) {
      await clearDraft(accountId, chatId);
      return;
    }

    final db = await OmegaDatabase.getInstance();
    await db.saveDraft(
      accountId,
      chatId,
      trimmed,
      quotedMessageId: quotedMessageId,
      quotedText: quotedText,
    );
  }

  /// Retrieve the stored draft for [accountId] / [chatId].
  ///
  /// Returns `null` if no draft exists.
  Future<DraftResult?> getDraft(int accountId, int chatId) async {
    final db = await OmegaDatabase.getInstance();
    final row = await db.getDraft(accountId, chatId);
    if (row == null) return null;

    return DraftResult(
      text: row['text'] as String,
      quotedMessageId: row['quoted_message_id'] as int?,
      quotedText: row['quoted_text'] as String?,
      savedAt: OmegaDatabase.msToDateTime(row['saved_at'] as int?),
    );
  }

  /// Delete any stored draft for [accountId] / [chatId].
  ///
  /// Should be called after a message is successfully sent.
  Future<void> clearDraft(int accountId, int chatId) async {
    final db = await OmegaDatabase.getInstance();
    await db.clearDraft(accountId, chatId);
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Returns `true` if a non-empty draft exists for the given chat.
  Future<bool> hasDraft(int accountId, int chatId) async {
    final draft = await getDraft(accountId, chatId);
    return draft != null && draft.text.isNotEmpty;
  }

  /// Updates only the quoted-message portion of an existing draft without
  /// changing the draft text. If no draft exists yet, a new one is created
  /// with empty text.
  Future<void> setQuote(
    int accountId,
    int chatId, {
    required int quotedMessageId,
    required String quotedText,
  }) async {
    final existing = await getDraft(accountId, chatId);
    await saveDraft(
      accountId,
      chatId,
      existing?.text ?? '',
      quotedMessageId: quotedMessageId,
      quotedText: quotedText,
    );
  }

  /// Remove only the quoted-message portion while preserving the draft text.
  Future<void> clearQuote(int accountId, int chatId) async {
    final existing = await getDraft(accountId, chatId);
    if (existing == null) return;

    await saveDraft(
      accountId,
      chatId,
      existing.text,
      quotedMessageId: null,
      quotedText: null,
    );
  }

  /// Clear all drafts for a given account (e.g. on logout).
  Future<void> clearAllDraftsForAccount(int accountId) async {
    final db = await OmegaDatabase.getInstance();
    await db.clearDraftsForAccount(accountId);
  }

  /// Returns the draft text (or empty string) — a convenience shorthand
  /// that avoids null checks at the call site.
  Future<String> getDraftText(int accountId, int chatId) async {
    final draft = await getDraft(accountId, chatId);
    return draft?.text ?? '';
  }
}
