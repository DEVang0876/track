
  import 'package:hive/hive.dart';

class StorageService {
  static Future<void> saveBudgets(List<Map<String, dynamic>> budgets) async {
    final box = await Hive.openBox('budgetsBox');
    await box.put('budgets', budgets);
  }

  static Future<List<Map<String, dynamic>>> loadBudgets() async {
    final box = await Hive.openBox('budgetsBox');
    final data = box.get('budgets', defaultValue: []);
    return List<Map<String, dynamic>>.from(data ?? []);
  }
  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    final box = await Hive.openBox('expensesBox');
    await box.put('expenses', expenses);
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final box = await Hive.openBox('expensesBox');
    final data = box.get('expenses', defaultValue: []);
    return List<Map<String, dynamic>>.from(data ?? []);
  }

  static Future<void> saveSubscriptions(List<Map<String, dynamic>> subs) async {
    final box = await Hive.openBox('subsBox');
    await box.put('subs', subs);
  }

  static Future<List<Map<String, dynamic>>> loadSubscriptions() async {
    final box = await Hive.openBox('subsBox');
    final data = box.get('subs', defaultValue: []);
    return List<Map<String, dynamic>>.from(data ?? []);
  }
}
