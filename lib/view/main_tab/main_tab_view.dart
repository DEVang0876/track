import 'package:trackizer/storage/wallet_service.dart';
import '../wallets/wallets_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:trackizer/view/add_subscription/add_subscription_view.dart';

import '../../common/color_extension.dart';
import '../calender/calender_view.dart';
// import '../card/cards_view.dart';
import '../home/home_view.dart';
import '../spending_budgets/spending_budgets_view.dart';
import '../breakdown/breakdown_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  List<Map<String, dynamic>> wallets = [];
  Key homeViewKey = UniqueKey();
  int selectTab = 0;
  PageStorageBucket pageStorageBucket = PageStorageBucket();
  Widget currentTabView = HomeView(key: UniqueKey());
  void _handleWalletsChanged() {
    _loadWallets();
    // If HomeView or other views need to be refreshed, you can also trigger setState or reload them here.
  }

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    wallets = await WalletService.loadWallets();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.gray,
      body: Stack(children: [
        PageStorage(bucket: pageStorageBucket, child: currentTabView),
        SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset("assets/img/bottom_bar_bg.png"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectTab = 0;
                                  homeViewKey = UniqueKey();
                                  currentTabView = HomeView(key: homeViewKey);
                                });
                              },
                              icon: Image.asset(
                                "assets/img/home.png",
                                width: 20,
                                height: 20,
                                color: selectTab == 0
                                    ? TColor.white
                                    : TColor.gray30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectTab = 1;
                                  currentTabView = const SpendingBudgetsView();
                                });
                              },
                              icon: Image.asset(
                                "assets/img/budgets.png",
                                width: 20,
                                height: 20,
                                color: selectTab == 1
                                    ? TColor.white
                                    : TColor.gray30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectTab = 2;
                                  currentTabView = const BreakdownView();
                                });
                              },
                              icon: Icon(Icons.bar_chart, color: selectTab == 2 ? TColor.white : TColor.gray30, size: 28),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectTab = 3;
                                  currentTabView = CalenderView();
                                });
                              },
                              icon: Image.asset(
                                "assets/img/calendar.png",
                                width: 20,
                                height: 20,
                                color: selectTab == 3
                                    ? TColor.white
                                    : TColor.gray30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectTab = 4;
                                  currentTabView = WalletsView(onWalletsChanged: _handleWalletsChanged);
                                });
                              },
                              icon: Icon(Icons.account_balance_wallet, color: selectTab == 4 ? TColor.white : TColor.gray30, size: 28),
                            ),
                          ],
                        )
                      ],
                    ),
                    InkWell(
                      onTap: () async {
                        // Show add expense dialog with wallet selection
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) {
                            final TextEditingController _descController = TextEditingController();
                            final TextEditingController _amountController = TextEditingController();
                            final TextEditingController _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
                            String type = 'expense';
                            String? selectedWallet = wallets.isNotEmpty ? wallets[0]['name'] : null;
                            return StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: Text('Add Entry'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _descController,
                                      decoration: InputDecoration(labelText: 'Description'),
                                    ),
                                    TextField(
                                      controller: _amountController,
                                      decoration: InputDecoration(labelText: 'Amount'),
                                      keyboardType: TextInputType.number,
                                    ),
                                    TextField(
                                      controller: _dateController,
                                      decoration: InputDecoration(labelText: 'Date'),
                                    ),
                                    DropdownButton<String>(
                                      value: type,
                                      items: [
                                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                                        DropdownMenuItem(value: 'credit', child: Text('Credit to friend')),
                                        DropdownMenuItem(value: 'debit', child: Text('Borrowed from friend')),
                                      ],
                                      onChanged: (val) => setState(() => type = val ?? 'expense'),
                                    ),
                                    if (wallets.isNotEmpty)
                                      DropdownButton<String>(
                                        value: selectedWallet,
                                        items: wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w['name'] as String, child: Text(w['name']))).toList(),
                                        onChanged: (val) => setState(() => selectedWallet = val),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('No wallets/accounts found. Add one first!', style: TextStyle(color: Colors.red)),
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      final desc = _descController.text.trim();
                                      final amt = _amountController.text.trim();
                                      final date = _dateController.text.trim();
                                      if (desc.isNotEmpty && amt.isNotEmpty && date.isNotEmpty && selectedWallet != null) {
                                        Navigator.pop(context, {"desc": desc, "amount": amt, "date": date, "type": type, "wallet": selectedWallet});
                                      }
                                    },
                                    child: Text('Add'),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                        if (result != null && result["desc"] != null && result["amount"] != null && result["wallet"] != null) {
                          // Update wallet balance
                          final walletName = result["wallet"];
                          final amt = double.tryParse(result["amount"] ?? '0') ?? 0.0;
                          final type = result["type"];
                          int walletIdx = wallets.indexWhere((w) => w['name'] == walletName);
                          double? newBalance;
                          if (walletIdx != -1) {
                            double oldBalance = double.tryParse(wallets[walletIdx]['balance'].toString()) ?? 0.0;
                            newBalance = oldBalance;
                            if (type == 'debit') {
                              // Borrow: add to wallet
                              newBalance += amt;
                            } else if (type == 'credit' || type == 'expense') {
                              // Credit to friend or Expense: subtract from wallet
                              newBalance -= amt;
                            }
                            wallets[walletIdx]['balance'] = newBalance;
                            await WalletService.saveWallets(wallets);
                          }
                          globalExpenses.add(result);
                          // Record transaction for all actions
                          String txType = '';
                          Color txColor = Colors.grey;
                          if (type == 'expense') {
                            txType = 'Expense';
                            txColor = Colors.red;
                          } else if (type == 'debit') {
                            txType = 'Borrowed';
                            txColor = Colors.red;
                          } else if (type == 'credit') {
                            txType = 'Credit';
                            txColor = Colors.green;
                          }
                          await WalletService.addTransaction({
                            "type": txType,
                            "wallet": walletName,
                            "amount": amt,
                            "desc": result["desc"],
                            "date": result["date"],
                            "color": txColor.value,
                            "balance": newBalance,
                          });
                          setState(() {
                            homeViewKey = UniqueKey();
                            if (selectTab == 0) {
                              currentTabView = HomeView(key: homeViewKey);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entry added!')));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: TColor.secondary.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ], borderRadius: BorderRadius.circular(50)),
                        child: Image.asset(
                          "assets/img/center_btn.png",
                          width: 55,
                          height: 55,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ]),
    );
  }
}
