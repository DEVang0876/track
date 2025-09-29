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
  static const _metaBoxName = 'syncMetaBox';
  static const _expenseTableKey = 'expenseTableName';
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isSyncing = false;
  String? _lastError;

  Future<void> init() async {
    await Hive.openBox(_queueBoxName);
    await Hive.openBox(_metaBoxName);
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

  Future<String> _getExpenseTableName() async {
    // Cache lookup first
    final meta = await Hive.openBox(_metaBoxName);
    final cached = meta.get(_expenseTableKey) as String?;
    if (cached != null && cached.isNotEmpty) return cached;
    // Probe Supabase for available table: prefer 'expenses', fallback to 'expence'
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    String chosen = 'expenses';
    if (uid == null) return chosen;
    try {
      await client.from('expenses').select('id').eq('user_id', uid).limit(1);
      chosen = 'expenses';
    } catch (_) {
      try {
        await client.from('expence').select('id').eq('user_id', uid).limit(1);
        chosen = 'expence';
      } catch (_) {
        chosen = 'expenses';
      }
    }
    await meta.put(_expenseTableKey, chosen);
    return chosen;
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
      _lastError = null;
      _saveLastError();
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
            {
              final expensesTable = await _getExpenseTableName();
              final String rid = (payload['id']?.toString() ?? '');
              if (rid.isNotEmpty) {
                final exist = await Supabase.instance.client
                    .from(expensesTable)
                    .select('id')
                    .eq('user_id', userId)
                    .eq('data->>id', rid)
                    .maybeSingle();
                if (exist == null) {
                  await Supabase.instance.client.from(expensesTable).insert({
                    'user_id': userId,
                    'data': payload,
                  });
                }
              } else {
                await Supabase.instance.client.from(expensesTable).insert({
                  'user_id': userId,
                  'data': payload,
                });
              }
            }
            break;
          case 'expense.delete':
            {
              final expensesTable = await _getExpenseTableName();
              final String rid = (payload['id']?.toString() ?? '');
              if (rid.isNotEmpty) {
                await Supabase.instance.client
                    .from(expensesTable)
                    .delete()
                    .eq('user_id', userId)
                    .eq('data->>id', rid);
              }
            }
            break;
          case 'wallet.tx.add':
            await Supabase.instance.client.from('transactions').insert({
              'user_id': userId,
              'data': payload,
            });
            break;
          case 'wallet.add':
            {
              final String wid = (payload['id']?.toString() ?? '');
              if (wid.isNotEmpty) {
                final exist = await Supabase.instance.client
                    .from('wallets')
                    .select('id')
                    .eq('user_id', userId)
                    .eq('data->>id', wid)
                    .maybeSingle();
                if (exist == null) {
                  await Supabase.instance.client.from('wallets').insert({
                    'user_id': userId,
                    'data': payload,
                  });
                }
              } else {
                await Supabase.instance.client.from('wallets').insert({
                  'user_id': userId,
                  'data': payload,
                });
              }
            }
            break;
          case 'wallet.update':
            {
              final String wid = (payload['id']?.toString() ?? '');
              if (wid.isNotEmpty) {
                // Check if any rows exist for this wallet id (avoid maybeSingle to tolerate duplicates)
                final List existRows = await Supabase.instance.client
                    .from('wallets')
                    .select('id')
                    .eq('user_id', userId)
                    .eq('data->>id', wid);
                if (existRows.isEmpty) {
                  await Supabase.instance.client.from('wallets').insert({
                    'user_id': userId,
                    'data': payload,
                  });
                } else {
                  // Update all matching rows to keep server consistent if duplicates exist
                  await Supabase.instance.client
                      .from('wallets')
                      .update({'data': payload})
                      .eq('user_id', userId)
                      .eq('data->>id', wid);
                }
              } else {
                await Supabase.instance.client.from('wallets').insert({
                  'user_id': userId,
                  'data': payload,
                });
              }
            }
            break;
          case 'wallet.delete':
            {
              final String wid = (payload['id']?.toString() ?? '');
              final String? name = payload['name'] as String?;
              if (wid.isNotEmpty) {
                await Supabase.instance.client
                    .from('wallets')
                    .delete()
                    .eq('user_id', userId)
                    .eq('data->>id', wid);
              } else if (name != null && name.isNotEmpty) {
                // Fetch ids of rows with matching name (case-insensitive) and delete them
                final nm = name.trim();
                final List rows = await Supabase.instance.client
                    .from('wallets')
                    .select('id')
                    .eq('user_id', userId)
                    .ilike('data->>name', nm);
                if (rows.isNotEmpty) {
                  final ids = rows.map((r) => (r as Map)['id']).toList();
          // Build an IN filter via CSV string because in_ may not be available
          final csv = ids.join(',');
          await Supabase.instance.client
            .from('wallets')
            .delete()
            .filter('id', 'in', '($csv)');
                }
              }
            }
            break;
          case 'budgets.save':
            {
              final List list = payload['items'] as List? ?? [];
              for (final b in list) {
                await Supabase.instance.client.from('budgets').insert({
                  'user_id': userId,
                  'data': Map<String, dynamic>.from(b as Map),
                });
              }
            }
            break;
          case 'subscriptions.save':
            {
              final List list = payload['items'] as List? ?? [];
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
      } catch (e) {
        // Leave in queue to retry later
        _lastError = e.toString();
        _saveLastError();
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
      final expensesTable = await _getExpenseTableName();
      final expRows = await client
          .from(expensesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final raw = _unwrap(expRows);
      // Dedupe by id (preferred) or composite descriptor to avoid duplicates, keep newest
      final seen = <String>{};
      final exp = <Map<String, dynamic>>[];
      for (final e in raw) {
        final id = (e['id']?.toString() ?? '').trim();
        final key = id.isNotEmpty
            ? 'id:$id'
            : 'k:${e['date']}|${e['desc']}|${e['amount']}|${e['category']}|${e['wallet']}';
        if (seen.add(key)) exp.add(e);
      }
      await _writeIfUseful('expensesBox', 'expenses', exp);
  } catch (e) { _lastError = e.toString(); _saveLastError(); }

    // Pull transactions
    try {
      final txRows = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final tx = _unwrap(txRows);
      await _writeIfUseful('walletsBox', 'transactions', tx);
  } catch (e) { _lastError = e.toString(); _saveLastError(); }

    // Pull wallets
    try {
      final walletRows = await client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final rawWallets = _unwrap(walletRows);
      // Dedupe by id (preferred) or normalized name; keep the most recently updated using updatedAt
      Map<String, Map<String, dynamic>> rmap = {};
      for (final w in rawWallets) {
        final id = (w['id']?.toString() ?? '');
        final nm = (w['name']?.toString() ?? '').trim().toLowerCase();
        final key = id.isNotEmpty ? 'id:$id' : (nm.isNotEmpty ? 'name:$nm' : _uuid.v4());
        final existing = rmap[key];
        if (existing == null) {
          rmap[key] = w;
        } else {
          final a = DateTime.tryParse((w['updatedAt']?.toString() ?? ''));
          final b = DateTime.tryParse((existing['updatedAt']?.toString() ?? ''));
          if (a != null && b != null) {
            if (a.isAfter(b)) rmap[key] = w;
          } else {
            // fallback to list order (server returned desc by created_at)
            rmap[key] = existing; // keep first
          }
        }
      }
      final List<Map<String, dynamic>> wallets = rmap.values.toList();
      // If there are pending local wallet ops, prefer merging to avoid overwriting fresh local changes
      final qbox = await Hive.openBox(_queueBoxName);
      final hasPendingWalletOps = qbox.values.any((raw) {
        try {
          final m = Map<String, dynamic>.from(raw as Map);
          final t = (m['type']?.toString() ?? '');
          return t.startsWith('wallet.');
        } catch (_) { return false; }
      });

      // Always merge with local using updatedAt to avoid overwriting fresher local edits
      final lbox = await Hive.openBox('walletsBox');
      final current = lbox.get('wallets', defaultValue: []) as List? ?? [];
      final local = current.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, Map<String, dynamic>> byKey(List<Map<String, dynamic>> list) {
        final m = <String, Map<String, dynamic>>{};
        for (final w in list) {
          final id = (w['id']?.toString() ?? '').trim();
          final nm = (w['name']?.toString() ?? '').trim().toLowerCase();
          final k = id.isNotEmpty ? 'id:$id' : (nm.isNotEmpty ? 'name:$nm' : _uuid.v4());
          m[k] = w;
        }
        return m;
      }
      final rmap2 = byKey(wallets);
      final lmap2 = byKey(local);
      final mergedKeys2 = {...rmap2.keys, ...lmap2.keys};
      final merged2 = <Map<String, dynamic>>[];
      for (final k in mergedKeys2) {
        if (lmap2.containsKey(k) && rmap2.containsKey(k)) {
          final la = DateTime.tryParse((lmap2[k]!['updatedAt']?.toString() ?? ''));
          final ra = DateTime.tryParse((rmap2[k]!['updatedAt']?.toString() ?? ''));
          if (la != null && ra != null) {
            merged2.add(la.isAfter(ra) ? lmap2[k]! : rmap2[k]!);
          } else if (la != null && ra == null) {
            merged2.add(lmap2[k]!);
          } else if (ra != null && la == null) {
            merged2.add(rmap2[k]!);
          } else {
            // No timestamps: prefer remote if no pending wallet ops; else prefer local
            merged2.add(hasPendingWalletOps ? lmap2[k]! : rmap2[k]!);
          }
        } else if (lmap2.containsKey(k)) {
          merged2.add(lmap2[k]!);
        } else if (rmap2.containsKey(k)) {
          merged2.add(rmap2[k]!);
        }
      }
      await _writeIfUseful('walletsBox', 'wallets', merged2);
  } catch (e) { _lastError = e.toString(); _saveLastError(); }

    // Pull budgets
    try {
      final budgetRows = await client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final budgets = _unwrap(budgetRows);
      await _writeIfUseful('budgetsBox', 'budgets', budgets);
  } catch (e) { _lastError = e.toString(); _saveLastError(); }

    // Pull subscriptions
    try {
      final subRows = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final subs = _unwrap(subRows);
      await _writeIfUseful('subsBox', 'subs', subs);
    } catch (e) { _lastError = e.toString(); _saveLastError(); }
  }

  Future<void> _saveLastError() async {
    try {
      final box = await Hive.openBox('syncMetaBox');
      await box.put('lastError', _lastError);
    } catch (_) {}
  }

  static Future<String?> getLastSyncError() async {
    try {
      final box = await Hive.openBox('syncMetaBox');
      return box.get('lastError') as String?;
    } catch (_) { return null; }
  }
}
