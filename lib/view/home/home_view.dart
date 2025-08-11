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
    List<Widget> expenseCards = globalExpenses.asMap().entries.map((entry) {
      final idx = entry.key;
      final exp = entry.value;
      return Card(
        color: TColor.gray60,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: Icon(Icons.attach_money, color: TColor.secondary),
          title: Text(exp['desc'] ?? '', style: TextStyle(color: TColor.white)),
          subtitle: Text(exp['date'] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\$${exp['amount']}', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _removeExpense(idx)),
            ],
          ),
        ),
      );
    }).toList();

    List<Widget> historyCards = [
      Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 8),
        child: Text('History', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      if (transactions.isEmpty)
        Center(child: Text('No history yet.', style: TextStyle(color: Colors.white54))),
      ...transactions.map((t) {
        Color tileColor = TColor.gray60;
        if (t["type"] == "Borrowed") {
          tileColor = Colors.green.withOpacity(0.18);
        } else if (t["type"] == "Expense" || t["type"] == "Credit") {
          tileColor = Colors.red.withOpacity(0.18);
        }
        // Choose icon by type
        IconData txIcon = Icons.account_balance_wallet;
        if (t["type"] == "Expense") {
          txIcon = Icons.arrow_upward;
        } else if (t["type"] == "Credit") {
          txIcon = Icons.arrow_upward;
        } else if (t["type"] == "Borrowed") {
          txIcon = Icons.arrow_downward;
        } else if (t["type"] == "Wallet Deleted") {
          txIcon = Icons.delete;
        } else if (t["type"] == "Wallet Added") {
          txIcon = Icons.account_balance_wallet;
        }
        // Format date only (no time)
        String dateStr = '';
        if (t["date"] != null && t["date"].toString().isNotEmpty) {
          try {
            dateStr = DateTime.parse(t["date"]).toLocal().toString().split(' ')[0];
          } catch (_) {
            dateStr = t["date"].toString().split(' ')[0];
          }
        }
        // Show balance after transaction
        String balanceStr = t["balance"] != null ? 'Bal: \$${(t["balance"] as num).toStringAsFixed(2)}' : '';
        return Card(
          color: tileColor,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text('${t['type']} - ${t['wallet']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${t['desc'] ?? ''}\nAmount: \$${t['amount'].toStringAsFixed(2)}\n$dateStr', style: const TextStyle(color: Colors.white70)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (balanceStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(balanceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                Icon(txIcon, color: Colors.white),
              ],
            ),
          ),
        );
      }),
    ];

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
            child: Text('Expenses', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...expenseCards,
          ...historyCards,
        ],
      ),
    );
  }
}
