import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifies that required tables exist and are accessible for the current user.
/// Returns a map from table name to a status string ('ok' or error message).
Future<Map<String, String>> checkSupabaseSetup() async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  final result = <String, String>{};
  if (uid == null) {
    return {'auth': 'No authenticated user'};
  }

  Future<void> probe(String table) async {
    try {
      await client.from(table).select().eq('user_id', uid).limit(1);
      result[table] = 'ok';
    } on PostgrestException catch (e) {
      result[table] = e.message;
    } catch (e) {
      result[table] = e.toString();
    }
  }

  await probe('expenses');
  await probe('transactions');
  await probe('wallets');
  await probe('budgets');
  await probe('subscriptions');

  return result;
}
