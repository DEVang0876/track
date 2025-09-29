import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/storage/wallet_service.dart';
import 'package:trackizer/storage/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:trackizer/view/settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

List<Map<String, dynamic>> globalExpenses = [];

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> expenses = [];
  StreamSubscription? _walletsWatch;
  StreamSubscription? _expensesWatch;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _attachWatchers();
  }

  Future<void> _attachWatchers() async {
    try {
      final walletsBox = await Hive.openBox('walletsBox');
      _walletsWatch = walletsBox.watch().listen((event) {
        if (event.key == 'wallets' || event.key == 'transactions') {
          _loadAllData();
        }
      });
    } catch (_) {}
    try {
      final expensesBox = await Hive.openBox('expensesBox');
      _expensesWatch = expensesBox.watch().listen((event) {
        if (event.key == 'expenses') {
          _loadAllData();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _walletsWatch?.cancel();
    _expensesWatch?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final loadedWallets = await WalletService.loadWallets();
    final loadedTransactions = await WalletService.loadTransactions();
    final loadedExpenses = await StorageService.loadExpenses();
    setState(() {
      wallets = loadedWallets;
      transactions = loadedTransactions;
      expenses = loadedExpenses;
    });
  }

  void _removeExpense(int idx) async {
    if (idx < 0 || idx >= expenses.length) return;
    setState(() {
      expenses.removeAt(idx);
    });
    await StorageService.saveExpenses(expenses);
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return Center(child: Text('No history yet.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, idx) {
        final e = entries[idx];
        Color tileColor = TColor.gray80;
        IconData txIcon = Icons.account_balance_wallet;
        String entryType = '';
        String description = '';
        String category = '';
        String afterBalance = '';
        String dateTimeStr = '';
        String amountStr = '';
        String wallet = '';
        // Use intl DateFormat for consistent date/time display
        if (e["date"] != null && e["date"].toString().isNotEmpty) {
          try {
            final dt = DateTime.parse(e["date"]).toLocal();
            dateTimeStr = DateFormat('yyyy-MM-dd  HH:mm:ss').format(dt);
          } catch (_) {
            dateTimeStr = e["date"].toString();
          }
        } else {
          dateTimeStr = '';
        }
        if (e["_entryType"] == "expense") {
          tileColor = TColor.secondary0.withValues(alpha: 0.18);
          txIcon = Icons.shopping_bag_rounded;
          entryType = 'Expense';
          description = e['desc'] ?? '';
          category = e['category'] ?? '';
          amountStr = '₹${e['amount'] ?? ''}';
          afterBalance = e['afterBalance'] != null ? '₹${(e['afterBalance'] as num).toStringAsFixed(2)}' : '';
          wallet = e['wallet'] ?? '';
        } else {
          // transaction
          entryType = e['type'] ?? '';
          if (e["type"] == "Borrowed") {
            tileColor = Colors.green.withValues(alpha: 0.13);
            txIcon = Icons.arrow_downward_rounded;
          } else if (e["type"] == "Expense" || e["type"] == "Credit") {
            tileColor = Colors.red.withValues(alpha: 0.13);
            txIcon = Icons.arrow_upward_rounded;
          } else if (e["type"] == "Wallet Deleted") {
            txIcon = Icons.delete_forever_rounded;
          } else if (e["type"] == "Wallet Added") {
            txIcon = Icons.account_balance_wallet_rounded;
          }
          description = e['desc'] ?? '';
          category = e['category'] ?? '';
          amountStr = e['amount'] != null ? '₹${(e['amount'] as num).toStringAsFixed(2)}' : '';
          afterBalance = e["balance"] != null ? '₹${(e["balance"] as num).toStringAsFixed(2)}' : '';
          wallet = e['wallet'] ?? '';
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: tileColor.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (amountStr.isNotEmpty)
                  Text(amountStr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (entryType.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(entryType, style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      if (category.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category, style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      if (wallet.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(wallet, style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white38, size: 15),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateTimeStr,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (afterBalance.isNotEmpty) ...[
                      SizedBox(width: 12),
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.white38, size: 15),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'After: $afterBalance',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gather and sort all entries
    List<Map<String, dynamic>> allEntries = [
      ...expenses.map((e) => {
        ...e,
        "_entryType": "expense"
      }),
      ...transactions.map((t) => {
        ...t,
        "_entryType": "transaction"
      })
    ];
    allEntries = allEntries.asMap().entries.map((e) => {...e.value, "_insertion": e.key}).toList();
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
      int cmp = bDate.compareTo(aDate);
      if (cmp != 0) return cmp;
      return (a["_insertion"] as int).compareTo(b["_insertion"] as int);
    });
    // Deduplicate
    final seen = <String>{};
    allEntries = allEntries.where((e) {
      final key = '${e["date"]}|${e["desc"]}|${e["amount"]}|${e["category"]}|${e["wallet"]}|${e["_entryType"]}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    // Filtered lists for each tab
    final walletEntries = allEntries.where((e) => e["type"] == "Wallet Added" || e["type"] == "Wallet Deleted").toList();
    // Show both local expenses and transaction entries marked as Expense in the Expenses tab
    final expenseEntries = [
      ...allEntries.where((e) => e["_entryType"] == "expense"),
      ...allEntries.where((e) => e["_entryType"] == "transaction" && (e["type"] == "Expense"))
          .map((t) => {
                // Map transaction to expense-like structure for display
                "desc": t["desc"],
                "amount": (t["amount"] ?? '').toString(),
                "date": t["date"],
                "wallet": t["wallet"],
                // Some transaction payloads may carry a category; if not, leave empty
                "category": t["category"] ?? '',
                "afterBalance": t["balance"],
                "_entryType": "expense",
              })
    ];
    final creditBorrowEntries = allEntries.where((e) => e["type"] == "Credit" || e["type"] == "Borrowed").toList();

    // Compute totalWallets for header
    double totalWallets = 0.0;
    for (var w in wallets) {
      if (w["balance"] != null) {
        totalWallets += (w["balance"] as num).toDouble();
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: TColor.gray,
        appBar: AppBar(
          backgroundColor: TColor.gray,
          elevation: 0,
          title: Text('Home', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: TColor.gray30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsView()));
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Modern header with gradient and balance
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
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
                      color: TColor.primary20.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Available', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      '\₹${totalWallets.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                indicatorColor: TColor.primary20,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Wallets'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Credit/Borrow'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildHistoryList(walletEntries),
                    _buildHistoryList(expenseEntries),
                    _buildHistoryList(creditBorrowEntries),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
