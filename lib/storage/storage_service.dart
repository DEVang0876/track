
  import 'package:hive/hive.dart';
  import 'package:trackizer/storage/sync_service.dart';

class StorageService {
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
    // Always save with newest first
    await box.put('expenses', List<Map<String, dynamic>>.from(expenses));
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
    // Insert at the start
    expenses.insert(0, expense);
    await box.put('expenses', expenses);
    // Queue single add for sync
    await SyncService().enqueue('expense.add', expense);
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final box = await Hive.openBox('expensesBox');
    final data = box.get('expenses', defaultValue: []);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
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
}
