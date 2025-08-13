import 'package:flutter/material.dart';
import 'package:trackizer/storage/wallet_service.dart';
import 'package:trackizer/common/color_extension.dart';


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

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }


  Future<void> _loadWallets() async {
    wallets = await WalletService.loadWallets();
    setState(() {});
  }

  Future<void> _saveWallets() async {
    await WalletService.saveWallets(wallets);
  }

  void _addWallet() async {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    if (name.isNotEmpty) {
      setState(() {
        wallets.add({"name": name, "balance": balance});
        _nameController.clear();
        _balanceController.clear();
      });
      await _saveWallets();
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
    setState(() {
      wallets.removeAt(idx);
    });
    await _saveWallets();
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
                  final oldBalance = wallets[idx]['balance'] ?? 0.0;
                  final newBalance = oldBalance + amount;
                  print('Borrow: old balance = \\${oldBalance}, amount = \\${amount}, new balance = \\${newBalance}');
                  setState(() {
                    wallets[idx]['balance'] = newBalance;
                  });
                  await _saveWallets();
                  // Record transaction as positive for borrow
                  await WalletService.addTransaction({
                    "type": "Borrowed",
                    "wallet": wallets[idx]['name'],
                    "amount": amount,
                    "date": DateTime.now().toIso8601String(),
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
                      subtitle: Text('Balance: ₹${w['balance'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
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
