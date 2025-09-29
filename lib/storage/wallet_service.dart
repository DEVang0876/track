import 'package:hive/hive.dart';
import 'package:trackizer/storage/sync_service.dart';
import 'package:uuid/uuid.dart';

class WalletService {
  static const _uuid = Uuid();
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
    Map<String, dynamic>? updated;
    for (var w in wallets) {
      if (w['name'] == name) {
        w['balance'] = newBalance;
        updated = Map<String, dynamic>.from(w);
        break;
      }
    }
    await box.put('wallets', wallets);
    if (updated != null) {
      await SyncService().enqueue('wallet.update', updated);
    }
  }
  static Future<void> saveWallets(List<Map<String, dynamic>> wallets) async {
    final box = await Hive.openBox('walletsBox');
    await box.put('wallets', wallets);
    // Intentionally no bulk enqueue here to avoid duplicates; incremental ops handle sync
  }
  static Future<void> addWallet(String name, double balance) async {
    final box = await Hive.openBox('walletsBox');
    List<Map<String, dynamic>> wallets = List<Map<String, dynamic>>.from(box.get('wallets', defaultValue: []));
    final newWallet = {
      'id': _uuid.v4(),
      'name': name,
      'balance': balance,
    };
    wallets.add(newWallet);
    await box.put('wallets', wallets);
    await SyncService().enqueue('wallet.add', newWallet);
  }

  static Future<void> deleteWalletById(String id, {String? name}) async {
    final box = await Hive.openBox('walletsBox');
    List<Map<String, dynamic>> wallets = List<Map<String, dynamic>>.from(box.get('wallets', defaultValue: []));
    wallets.removeWhere((w) => (w['id']?.toString() ?? '') == id || (id.isEmpty && name != null && w['name'] == name));
    await box.put('wallets', wallets);
    await SyncService().enqueue('wallet.delete', {'id': id, 'name': name});
  }

  static Future<List<Map<String, dynamic>>> loadWallets() async {
    final box = await Hive.openBox('walletsBox');
    final data = box.get('wallets', defaultValue: []);
    if (data == null) return [];
    // Ensure each item is Map<String, dynamic> with string keys
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(
        (item as Map).map((key, value) => MapEntry(key.toString(), value)),
      )),
    );

    // Backfill missing IDs for legacy wallets and normalize balance to number
    bool changed = false;
    for (var i = 0; i < items.length; i++) {
      final w = items[i];
      // Ensure stable id
      final wid = (w['id']?.toString() ?? '').trim();
      if (wid.isEmpty) {
        w['id'] = _uuid.v4();
        changed = true;
      }
      // Normalize balance to number (double)
      final bal = w['balance'];
      if (bal is String) {
        final parsed = double.tryParse(bal);
        if (parsed != null) {
          w['balance'] = parsed;
          changed = true;
        }
      } else if (bal is int) {
        w['balance'] = bal.toDouble();
        changed = true;
      }
      items[i] = w;
    }

    if (changed) {
      await box.put('wallets', items);
    }

    return items;
  }
}
