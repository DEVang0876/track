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
    // Sort by millisecondsSinceEpoch if possible, else by date string
    allEntries.sort((a, b) {
      DateTime aDate, bDate;
      try {
        aDate = DateTime.parse(a["date"]?.toString() ?? "");
      } catch (_) {
        aDate = DateTime(1970);
      }
      try {
        bDate = DateTime.parse(b["date"]?.toString() ?? "");
      } catch (_) {
        bDate = DateTime(1970);
      }
      return bDate.millisecondsSinceEpoch.compareTo(aDate.millisecondsSinceEpoch);
    });

    return Scaffold(
      backgroundColor: TColor.gray,
      body: ListView(
        children: [
          // Modern header with gradient and balance
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [TColor.primary20, TColor.primary10, TColor.secondary50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: TColor.primary20.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Available', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '\$${totalWallets.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 24, right: 24, bottom: 8),
            child: Text('History', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5)),
          ),
          if (allEntries.isEmpty)
            Center(child: Text('No history yet.', style: TextStyle(color: Colors.white54))),
          ...allEntries.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            Color tileColor = TColor.gray80;
            IconData txIcon = Icons.account_balance_wallet;
            String entryType = '';
            String description = '';
            String category = '';
            String afterBalance = '';
            String dateTimeStr = '';
            String amountStr = '';
            String wallet = '';
            // Parse date and time
            if (e["date"] != null && e["date"].toString().isNotEmpty) {
              try {
                final dt = DateTime.parse(e["date"]).toLocal();
                final hour = dt.hour.toString().padLeft(2, '0');
                final minute = dt.minute.toString().padLeft(2, '0');
                final second = dt.second.toString().padLeft(2, '0');
                dateTimeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  $hour:$minute:$second';
              } catch (_) {
                dateTimeStr = e["date"].toString();
              }
            }
            if (e["_entryType"] == "expense") {
              tileColor = TColor.secondary0.withOpacity(0.18);
              txIcon = Icons.shopping_bag_rounded;
              entryType = 'Expense';
              description = e['desc'] ?? '';
              category = e['category'] ?? '';
              amountStr = '\$${e['amount'] ?? ''}';
              afterBalance = e['afterBalance'] != null ? '\$${(e['afterBalance'] as num).toStringAsFixed(2)}' : '';
              wallet = e['wallet'] ?? '';
            } else {
              // transaction
              entryType = e['type'] ?? '';
              if (e["type"] == "Borrowed") {
                tileColor = Colors.green.withOpacity(0.13);
                txIcon = Icons.arrow_downward_rounded;
              } else if (e["type"] == "Expense" || e["type"] == "Credit") {
                tileColor = Colors.red.withOpacity(0.13);
                txIcon = Icons.arrow_upward_rounded;
              } else if (e["type"] == "Wallet Deleted") {
                txIcon = Icons.delete_forever_rounded;
              } else if (e["type"] == "Wallet Added") {
                txIcon = Icons.account_balance_wallet_rounded;
              }
              description = e['desc'] ?? '';
              category = e['category'] ?? '';
              amountStr = e['amount'] != null ? '\$${(e['amount'] as num).toStringAsFixed(2)}' : '';
              afterBalance = e["balance"] != null ? '\$${(e["balance"] as num).toStringAsFixed(2)}' : '';
              wallet = e['wallet'] ?? '';
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: tileColor.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(txIcon, color: TColor.primary20),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (amountStr.isNotEmpty)
                      Text(amountStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (entryType.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(entryType, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(category, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          if (wallet.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(wallet, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white38, size: 15),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateTimeStr,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (afterBalance.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white38, size: 15),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'After: $afterBalance',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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
