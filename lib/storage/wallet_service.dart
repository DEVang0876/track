
import 'package:hive/hive.dart';
import 'package:trackizer/storage/sync_service.dart';

class WalletService {
  static Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final box = await getBox();
    final data = box.get('transactions', defaultValue: []);
    List<Map<String, dynamic>> transactions = [];
    if (data != null) {
      transactions = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(
          (item as Map).map((key, value) => MapEntry(key.toString(), value)),
        )),
      );
    }
    transactions.insert(0, transaction);
    await box.put('transactions', transactions);
    await SyncService().enqueue('wallet.tx.add', transaction);
  }

  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    final box = await getBox();
    final data = box.get('transactions', defaultValue: []);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(
        (item as Map).map((key, value) => MapEntry(key.toString(), value)),
      )),
    );
  }
  static Future<Box> getBox() async {
    return await Hive.openBox('walletsBox');
  }
  static Future<void> updateWalletBalance(String name, double newBalance) async {
    final box = await Hive.openBox('walletsBox');
    List<Map<String, dynamic>> wallets = List<Map<String, dynamic>>.from(box.get('wallets', defaultValue: []));
    for (var w in wallets) {
      if (w['name'] == name) {
        w['balance'] = newBalance;
        break;
      }
    }
    await box.put('wallets', wallets);
    await SyncService().enqueue('wallet.balance.update', {
      'name': name,
      'balance': newBalance,
    });
  }
  static Future<void> saveWallets(List<Map<String, dynamic>> wallets) async {
    final box = await Hive.openBox('walletsBox');
    await box.put('wallets', wallets);
  }

  static Future<List<Map<String, dynamic>>> loadWallets() async {
    final box = await Hive.openBox('walletsBox');
    final data = box.get('wallets', defaultValue: []);
    if (data == null) return [];
    // Ensure each item is Map<String, dynamic> with string keys
    return List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(
        (item as Map).map((key, value) => MapEntry(key.toString(), value)),
      )),
    );
  }
}
