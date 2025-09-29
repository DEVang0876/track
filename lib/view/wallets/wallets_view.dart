import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:trackizer/storage/wallet_service.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/view/settings/settings_view.dart';


typedef WalletsChangedCallback = void Function();

class WalletsView extends StatefulWidget {
  final WalletsChangedCallback? onWalletsChanged;
  const WalletsView({super.key, this.onWalletsChanged});

  @override
  State<WalletsView> createState() => _WalletsViewState();
}

class _WalletsViewState extends State<WalletsView> {
  List<Map<String, dynamic>> wallets = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  StreamSubscription? _walletsWatch;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _attachWatcher();
  }

  Future<void> _attachWatcher() async {
    try {
      final box = await Hive.openBox('walletsBox');
      _walletsWatch = box.watch().listen((_) => _loadWallets());
    } catch (_) {}
  }


  Future<void> _loadWallets() async {
    final loaded = await WalletService.loadWallets();
    // Dedupe by id or name (prefer id) to avoid duplicates in UI if history created multiple rows
    final seen = <String>{};
    final List<Map<String, dynamic>> unique = [];
    for (final w in loaded) {
      final key = (w['id']?.toString() ?? '').isNotEmpty
          ? 'id:${w['id']}'
          : ((w['name']?.toString() ?? '').isNotEmpty ? 'name:${w['name']}' : '');
      if (key.isEmpty || !seen.contains(key)) {
        if (key.isNotEmpty) seen.add(key);
        unique.add(w);
      }
    }
    wallets = unique;
    setState(() {});
  }

  @override
  void dispose() {
    _walletsWatch?.cancel();
    super.dispose();
  }


  void _addWallet() async {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    if (name.isNotEmpty) {
      await WalletService.addWallet(name, balance);
      await _loadWallets();
      _nameController.clear();
      _balanceController.clear();
      // Record transaction for wallet/account add
      await WalletService.addTransaction({
        "type": "Wallet Added",
        "wallet": name,
        "amount": balance,
        "desc": "Wallet/Account created",
        "date": DateTime.now().toIso8601String(),
      });
      if (widget.onWalletsChanged != null) widget.onWalletsChanged!();
      print('Wallet added: $name, $balance');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallet "$name" added!')),
        );
      }
    } else {
      print('Wallet name is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a wallet/account name.')),
        );
      }
    }
  }

  void _deleteWallet(int idx) async {
    final deletedWallet = wallets[idx];
    final String id = (deletedWallet['id']?.toString() ?? '');
    await WalletService.deleteWalletById(id, name: deletedWallet['name']);
    await _loadWallets();
    // Record transaction for wallet/account deletion
    await WalletService.addTransaction({
      "type": "Wallet Deleted",
      "wallet": deletedWallet['name'],
      "amount": deletedWallet['balance'],
      "desc": "Wallet/Account deleted",
      "date": DateTime.now().toIso8601String(),
    });
    if (widget.onWalletsChanged != null) widget.onWalletsChanged!();
  }

  void _showAddMoneyDialog(int idx) {
    final TextEditingController _amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Borrow Money (Add to \\${wallets[idx]['name']})'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount to Add'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                if (amount > 0.0) {
                  // Parse old balance robustly
                  final bal = wallets[idx]['balance'];
                  double oldBalance;
                  if (bal is num) {
                    oldBalance = bal.toDouble();
                  } else if (bal is String) {
                    oldBalance = double.tryParse(bal) ?? 0.0;
                  } else {
                    oldBalance = 0.0;
                  }
                  final newBalance = oldBalance + amount;
                  final walletId = (wallets[idx]['id']?.toString() ?? '');
                  print('Borrow: old balance = \\${oldBalance}, amount = \\${amount}, new balance = \\${newBalance}');
                  if (walletId.isNotEmpty) {
                    await WalletService.updateWalletBalanceById(walletId, newBalance);
                  } else {
                    await WalletService.updateWalletBalance(wallets[idx]['name'], newBalance);
                  }
                  await _loadWallets();
                  // Record transaction as positive for borrow
                  await WalletService.addTransaction({
                    "type": "Borrowed",
                    "wallet": wallets[idx]['name'],
                    "amount": amount,
                    "date": DateTime.now().toIso8601String(),
                    "balance": newBalance,
                  });
                  if (widget.onWalletsChanged != null) widget.onWalletsChanged!();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added amount: \\${amount.toStringAsFixed(2)} to \\${wallets[idx]['name']}')),
                    );
                  }
                  Navigator.of(context).pop();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a positive amount.')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Accounts'),
        backgroundColor: TColor.gray,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: TColor.gray30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsView()));
            },
          ),
        ],
      ),
      backgroundColor: TColor.gray,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Wallet/Account Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Balance',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addWallet,
              child: const Text('Add Wallet/Account'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, idx) {
                  final w = wallets[idx];
                  return Card(
                    color: TColor.gray60,
                    child: ListTile(
                      title: Text(w['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        () {
                          final bal = w['balance'];
                          double val;
                          if (bal is num) {
                            val = bal.toDouble();
                          } else if (bal is String) {
                            val = double.tryParse(bal) ?? 0.0;
                          } else {
                            val = 0.0;
                          }
                          return 'Balance: ₹${val.toStringAsFixed(2)}';
                        }(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            tooltip: 'Add/Borrow Money',
                            onPressed: () => _showAddMoneyDialog(idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWallet(idx),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
