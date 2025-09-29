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

  /// Number of pending items in local sync queue.
  Future<int> pendingCount() async {
    final box = await Hive.openBox(_queueBoxName);
    return box.length;
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
    // Attempt to sync right away (no-op if not logged in or offline)
    // This ensures the server has data before a potential sign-out, so recovery works.
    unawaited(syncNow());
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
              'user_id': userId,
              'data': payload,
            });
            break;
          case 'wallet.tx.add':
            await Supabase.instance.client.from('transactions').insert({
              'user_id': userId,
              'data': payload,
            });
            break;
          case 'wallet.balance.update':
            // Store the latest wallet snapshot as a row
            await Supabase.instance.client.from('wallets').insert({
              'user_id': userId,
              'data': payload,
            });
            break;
          case 'wallets.save':
            // Batch insert all wallets as separate rows
            final List list = payload['items'] as List? ?? [];
            if (list.isNotEmpty) {
              for (final w in list) {
                await Supabase.instance.client.from('wallets').insert({
                  'user_id': userId,
                  'data': Map<String, dynamic>.from(w as Map),
                });
              }
            }
            break;
          case 'budgets.save':
            // Batch insert budgets items as separate rows
            final List list = payload['items'] as List? ?? [];
            if (list.isNotEmpty) {
              for (final b in list) {
                await Supabase.instance.client.from('budgets').insert({
                  'user_id': userId,
                  'data': Map<String, dynamic>.from(b as Map),
                });
              }
            }
            break;
          case 'subscriptions.save':
            final List list = payload['items'] as List? ?? [];
            if (list.isNotEmpty) {
              for (final s in list) {
                await Supabase.instance.client.from('subscriptions').insert({
                  'user_id': userId,
                  'data': Map<String, dynamic>.from(s as Map),
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
    // Helper to unwrap JSON rows
    List<Map<String, dynamic>> _unwrap(List<dynamic> rows) {
      return rows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final data = m['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return <String, dynamic>{};
      }).toList();
    }

    // Helper to avoid wiping local data when remote is empty
    Future<void> _writeIfUseful(String boxName, String key, List<Map<String, dynamic>> remote) async {
      final box = await Hive.openBox(boxName);
      final current = box.get(key, defaultValue: []);
  final hasLocal = current is List && current.isNotEmpty;
      if (remote.isEmpty && hasLocal) {
        // Keep local copy; do not overwrite with empty remote
        return;
      }
      await box.put(key, remote);
    }

    // Pull expenses
    try {
      final expRows = await client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final exp = _unwrap(expRows);
      await _writeIfUseful('expensesBox', 'expenses', exp);
    } catch (_) {}

    // Pull transactions
    try {
      final txRows = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final tx = _unwrap(txRows);
      await _writeIfUseful('walletsBox', 'transactions', tx);
    } catch (_) {}

    // Pull wallets
    try {
      final walletRows = await client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final wallets = _unwrap(walletRows);
      await _writeIfUseful('walletsBox', 'wallets', wallets);
    } catch (_) {}

    // Pull budgets
    try {
      final budgetRows = await client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final budgets = _unwrap(budgetRows);
      await _writeIfUseful('budgetsBox', 'budgets', budgets);
    } catch (_) {}

    // Pull subscriptions
    try {
      final subRows = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final subs = _unwrap(subRows);
      await _writeIfUseful('subsBox', 'subs', subs);
    } catch (_) {}
  }
}
