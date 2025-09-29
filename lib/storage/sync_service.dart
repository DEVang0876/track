import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const _queueBoxName = 'syncQueue';
  static const _uuid = Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isSyncing = false;

  Future<void> init() async {
    await Hive.openBox(_queueBoxName);
    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      final online = event.any((e) => e != ConnectivityResult.none);
      if (online) {
        unawaited(syncNow());
      }
    });
  }

  void dispose() {
    _connSub?.cancel();
  }

  /// Clear pending sync operations from the local queue.
  Future<void> clearQueue() async {
    final box = await Hive.openBox(_queueBoxName);
    await box.clear();
  }

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final box = await Hive.openBox(_queueBoxName);
    final item = {
      'id': _uuid.v4(),
      'type': type, // e.g., 'expense.add', 'wallet.update'
      'payload': payload,
      'ts': DateTime.now().toIso8601String(),
    };
    await box.add(item);
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await _pushQueue(userId);
      await _pullLatest(userId);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushQueue(String userId) async {
    final box = await Hive.openBox(_queueBoxName);
    // Iterate using keys to delete deterministically
    final keys = box.keys.toList();
    for (final key in keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw as Map);
      final type = map['type'] as String?;
      final payload = Map<String, dynamic>.from(map['payload'] as Map);
      try {
        switch (type) {
          case 'expense.add':
            await Supabase.instance.client.from('expenses').insert({
              ...payload,
              'user_id': userId,
            });
            break;
          case 'wallet.tx.add':
            await Supabase.instance.client.from('transactions').insert({
              ...payload,
              'user_id': userId,
            });
            break;
          case 'wallet.balance.update':
            await Supabase.instance.client.from('wallets').upsert({
              ...payload,
              'user_id': userId,
            });
            break;
          case 'budgets.save':
            // Upsert budgets list; assumes payload contains an array of budgets
            final List list = payload['items'] as List? ?? [];
            if (list.isNotEmpty) {
              for (final b in list) {
                await Supabase.instance.client.from('budgets').upsert({
                  ...Map<String, dynamic>.from(b as Map),
                  'user_id': userId,
                });
              }
            }
            break;
          case 'subscriptions.save':
            final List list = payload['items'] as List? ?? [];
            if (list.isNotEmpty) {
              for (final s in list) {
                await Supabase.instance.client.from('subscriptions').upsert({
                  ...Map<String, dynamic>.from(s as Map),
                  'user_id': userId,
                });
              }
            }
            break;
        }
        // Remove from queue on success
        await box.delete(key);
      } catch (_) {
        // Leave in queue to retry later
      }
    }
  }

  Future<void> _pullLatest(String userId) async {
    final client = Supabase.instance.client;
    // Pull expenses
    try {
      final exp = await client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      await Hive.openBox('expensesBox')
          .then((b) => b.put('expenses', List<Map<String, dynamic>>.from(exp)));
    } catch (_) {}

    // Pull transactions
    try {
      final tx = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      await Hive.openBox('walletsBox')
          .then((b) => b.put('transactions', List<Map<String, dynamic>>.from(tx)));
    } catch (_) {}

    // Pull wallets
    try {
      final wallets = await client
          .from('wallets')
          .select()
          .eq('user_id', userId);
      await Hive.openBox('walletsBox')
          .then((b) => b.put('wallets', List<Map<String, dynamic>>.from(wallets)));
    } catch (_) {}

    // Pull budgets
    try {
      final budgets = await client
          .from('budgets')
          .select()
          .eq('user_id', userId);
      await Hive.openBox('budgetsBox')
          .then((b) => b.put('budgets', List<Map<String, dynamic>>.from(budgets)));
    } catch (_) {}

    // Pull subscriptions
    try {
      final subs = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId);
      await Hive.openBox('subsBox')
          .then((b) => b.put('subs', List<Map<String, dynamic>>.from(subs)));
    } catch (_) {}
  }
}
