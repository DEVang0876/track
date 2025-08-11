import 'package:flutter/material.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/storage/wallet_service.dart';
import 'package:trackizer/storage/storage_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

List<Map<String, dynamic>> globalExpenses = [];

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> transactions = [];

  Future<void> _loadTransactions() async {
    transactions = await WalletService.loadTransactions();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadExpenses();
    _loadTransactions();
  }

  Future<void> _loadWallets() async {
    wallets = await WalletService.loadWallets();
    setState(() {});
  }

  Future<void> _loadExpenses() async {
    globalExpenses = await StorageService.loadExpenses();
    setState(() {});
  }

  Future<void> _saveExpenses() async {
    await StorageService.saveExpenses(globalExpenses);
  }

  double get totalWallets => wallets.fold(0.0, (sum, w) => sum + (double.tryParse(w['balance'].toString()) ?? 0));

  void _removeExpense(int idx) async {
    setState(() {
      globalExpenses.removeAt(idx);
    });
    await _saveExpenses();
  }

  @override
  Widget build(BuildContext context) {
    // Merge all expenses and transactions into a single history list
    List<Map<String, dynamic>> allEntries = [
      ...globalExpenses.map((e) => {
        ...e,
        "_entryType": "expense"
      }),
      ...transactions.map((t) => {
        ...t,
        "_entryType": "transaction"
      })
    ];
    // Sort by date descending (most recent first)
    allEntries.sort((a, b) {
      final aDate = DateTime.tryParse(a["date"]?.toString() ?? "") ?? DateTime(1970);
      final bDate = DateTime.tryParse(b["date"]?.toString() ?? "") ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return Scaffold(
      backgroundColor: TColor.gray,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Available', style: TextStyle(color: TColor.gray30, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '\$${totalWallets.toStringAsFixed(2)}',
                  style: TextStyle(color: TColor.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 8),
            child: Text('History', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (allEntries.isEmpty)
            Center(child: Text('No history yet.', style: TextStyle(color: Colors.white54))),
          ...allEntries.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            Color tileColor = TColor.gray60;
            IconData txIcon = Icons.account_balance_wallet;
            String title = '';
            String subtitle = '';
            String trailing = '';
            String dateStr = '';
            if (e["date"] != null && e["date"].toString().isNotEmpty) {
              try {
                dateStr = DateTime.parse(e["date"]).toLocal().toString().split(' ')[0];
              } catch (_) {
                dateStr = e["date"].toString().split(' ')[0];
              }
            }
            if (e["_entryType"] == "expense") {
              tileColor = TColor.gray60;
              txIcon = Icons.attach_money;
              title = e['desc'] ?? '';
              subtitle = '${e['category'] ?? ''}\n$dateStr';
              trailing = '\$${e['amount'] ?? ''}';
            } else {
              // transaction
              if (e["type"] == "Borrowed") {
                tileColor = Colors.green.withOpacity(0.18);
                txIcon = Icons.arrow_downward;
              } else if (e["type"] == "Expense" || e["type"] == "Credit") {
                tileColor = Colors.red.withOpacity(0.18);
                txIcon = Icons.arrow_upward;
              } else if (e["type"] == "Wallet Deleted") {
                txIcon = Icons.delete;
              } else if (e["type"] == "Wallet Added") {
                txIcon = Icons.account_balance_wallet;
              }
              title = '${e['type']} - ${e['wallet'] ?? ''}';
              subtitle = '${e['desc'] ?? ''}\nAmount: \$${(e['amount'] as num?)?.toStringAsFixed(2) ?? ''}\n$dateStr';
              String balanceStr = e["balance"] != null ? 'Bal: \$${(e["balance"] as num).toStringAsFixed(2)}' : '';
              trailing = balanceStr;
            }
            return Card(
              color: tileColor,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Icon(txIcon, color: TColor.secondary),
                title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
                trailing: trailing.isNotEmpty ? Text(trailing, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                onLongPress: e["_entryType"] == "expense"
                    ? () => _removeExpense(idx)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
