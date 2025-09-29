
  import 'package:hive/hive.dart';
  import 'package:trackizer/storage/sync_service.dart';
  import 'package:uuid/uuid.dart';

class StorageService {
  static const _uuid = Uuid();
  static Future<void> saveBudgets(List<Map<String, dynamic>> budgets) async {
    final box = await Hive.openBox('budgetsBox');
    await box.put('budgets', budgets);
    // Queue for cloud sync (batch)
    await SyncService().enqueue('budgets.save', {
      'items': budgets,
    });
  }

  static Future<List<Map<String, dynamic>>> loadBudgets() async {
    final box = await Hive.openBox('budgetsBox');
    final data = box.get('budgets', defaultValue: []);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    final box = await Hive.openBox('expensesBox');
    // Deduplicate before saving (prefer first occurrence, typically newest-first lists)
    final seen = <String>{};
    final cleaned = <Map<String, dynamic>>[];
    for (final e in expenses) {
      final id = (e['id']?.toString() ?? '').trim();
      final normAmt = () {
        final a = e['amount'];
        double v;
        if (a is num) v = a.toDouble(); else if (a is String) v = double.tryParse(a) ?? 0.0; else v = 0.0;
        return v.toStringAsFixed(2);
      }();
      final key = id.isNotEmpty
          ? 'id:$id'
          : 'k:${e['date']}|${e['desc']}|$normAmt|${e['category']}|${e['wallet']}';
      if (seen.add(key)) cleaned.add(e);
    }
    await box.put('expenses', cleaned);
  }

  static Future<void> addExpense(Map<String, dynamic> expense) async {
    final box = await Hive.openBox('expensesBox');
    final data = box.get('expenses', defaultValue: []);
    List<Map<String, dynamic>> expenses = [];
    if (data != null) {
      expenses = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(
          (item as Map).map((key, value) => MapEntry(key.toString(), value)),
        )),
      );
    }
    // Ensure a stable unique id for dedupe/delete
    if (!(expense.containsKey('id')) || (expense['id']?.toString().isEmpty ?? true)) {
      expense['id'] = _uuid.v4();
    }
    // Insert at the start
    expenses.insert(0, expense);
    await box.put('expenses', expenses);
    // Queue single add for sync
    await SyncService().enqueue('expense.add', expense);
  }

  static Future<void> deleteExpenseById(String id) async {
    final box = await Hive.openBox('expensesBox');
    final data = box.get('expenses', defaultValue: []);
    List<Map<String, dynamic>> expenses = [];
    if (data != null) {
      expenses = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(
          (item as Map).map((key, value) => MapEntry(key.toString(), value)),
        )),
      );
    }
    expenses.removeWhere((e) => (e['id']?.toString() ?? '') == id);
    await box.put('expenses', expenses);
    // Enqueue delete for remote
    if (id.isNotEmpty) {
      await SyncService().enqueue('expense.delete', { 'id': id });
    }
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final box = await Hive.openBox('expensesBox');
    final data = box.get('expenses', defaultValue: []);
    final List<Map<String, dynamic>> items = (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // Backfill missing IDs for legacy expenses so future deletes/dedupes work
    bool changed = false;
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      final id = (m['id']?.toString() ?? '').trim();
      if (id.isEmpty) {
        m['id'] = _uuid.v4();
        items[i] = m;
        changed = true;
      }
    }
    // Local dedupe: prefer first occurrence (assumes list already newest-first typically)
    final seen = <String>{};
    final cleaned = <Map<String, dynamic>>[];
    for (final e in items) {
      final id = (e['id']?.toString() ?? '').trim();
      final normAmt = () {
        final a = e['amount'];
        double v;
        if (a is num) v = a.toDouble(); else if (a is String) v = double.tryParse(a) ?? 0.0; else v = 0.0;
        return v.toStringAsFixed(2);
      }();
      final key = id.isNotEmpty
          ? 'id:$id'
          : 'k:${e['date']}|${e['desc']}|$normAmt|${e['category']}|${e['wallet']}';
      if (seen.add(key)) cleaned.add(e);
    }
    if (changed || cleaned.length != items.length) {
      await box.put('expenses', cleaned);
    }
    return cleaned;
  }

  static Future<void> saveSubscriptions(List<Map<String, dynamic>> subs) async {
    final box = await Hive.openBox('subsBox');
    await box.put('subs', subs);
    // Queue for cloud sync (batch)
    await SyncService().enqueue('subscriptions.save', {
      'items': subs,
    });
  }

  static Future<List<Map<String, dynamic>>> loadSubscriptions() async {
    final box = await Hive.openBox('subsBox');
    final data = box.get('subs', defaultValue: []);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Clears all local persisted data in Hive boxes.
  ///
  /// - budgetsBox
  /// - expensesBox
  /// - walletsBox
  /// - subsBox
  /// Optionally also clears the sync queue box via SyncService.
  static Future<void> clearAllLocal({bool includeQueue = true}) async {
    try { await Hive.openBox('budgetsBox').then((b) => b.clear()); } catch (_) {}
    try { await Hive.openBox('expensesBox').then((b) => b.clear()); } catch (_) {}
    try { await Hive.openBox('walletsBox').then((b) => b.clear()); } catch (_) {}
    try { await Hive.openBox('subsBox').then((b) => b.clear()); } catch (_) {}
    if (includeQueue) {
      try { await SyncService().clearQueue(); } catch (_) {}
    }
  }
}
