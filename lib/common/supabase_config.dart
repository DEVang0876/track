import 'dart:convert';

class SupabaseConfig {
  // Defaults are embedded so you don't need to pass anything manually.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oywinxmbquxjmzkivyvs.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95d2lueG1icXV4am16a2l2eXZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxMzYxODQsImV4cCI6MjA3NDcxMjE4NH0.JxxCLThyu0WT00LyQhsE7UBugSwqd_py9YkAnOJhtZs',
  );

  /// True if both URL and anon key are present (effectiveUrl must still be valid).
  static bool get isConfigured =>
      effectiveUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Normalized, effective URL. If the configured URL doesn't match the project ref
  /// from the anon key, this falls back to https://<ref>.supabase.co.
  static String get effectiveUrl {
    final configured = _normalizeUrl(supabaseUrl);
    final ref = projectRefFromKey;
    // Prefer the configured URL when provided to avoid accidental overrides.
    if (configured.isNotEmpty) return configured;
    // Otherwise, derive from anon key ref if available.
    if (ref != null && ref.isNotEmpty) {
      return 'https://$ref.supabase.co';
    }
    return configured;
  }

  /// Extracts the Supabase project ref from the anon key (JWT payload `ref`).
  static String? get projectRefFromKey {
    try {
      final parts = supabaseAnonKey.split('.');
      if (parts.length < 2) return null;
      final payloadRaw = parts[1];
      // Base64URL decode with padding handling
      String normalized = payloadRaw.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64.decode(normalized));
      final map = json.decode(decoded) as Map<String, dynamic>;
      final ref = map['ref'] as String?;
      return ref;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeUrl(String url) {
    final t = url.trim();
    if (t.isEmpty) return '';
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
