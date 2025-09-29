import 'package:trackizer/storage/wallet_service.dart';
import 'package:trackizer/storage/storage_service.dart';
import '../wallets/wallets_view.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> categories = [];

  Future<void> _loadCategories() async {
    categories = await StorageService.loadBudgets();
    setState(() {});
  }
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
  _loadCategories();
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
                                // Wait for SpendingBudgetsView to pop, then reload categories
                                Future.delayed(Duration(milliseconds: 300), () async {
                                  await _loadCategories();
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
                            String? selectedCategory = categories.isNotEmpty ? categories[0]['name'] : null;
                            return StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: Text('Add Entry', style: TextStyle(color: Colors.white)),
                                backgroundColor: null, // Remove solid color to allow custom background
                                content: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF23243a), Color(0xFF2c2e4a)], // dark blue gradient
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.13),
                                        blurRadius: 16,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                    padding: EdgeInsets.all(18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Build unique option lists and guard selected values
                                        Builder(builder: (context) {
                                          final categoryNames = categories
                                              .map((c) => (c['name'] as String?)?.trim())
                                              .where((e) => (e != null && e.isNotEmpty))
                                              .cast<String>()
                                              .toSet()
                                              .toList();
                                          final walletNames = wallets
                                              .map((w) => (w['name'] as String?)?.trim())
                                              .where((e) => (e != null && e.isNotEmpty))
                                              .cast<String>()
                                              .toSet()
                                              .toList();
                                          if (selectedCategory != null && !categoryNames.contains(selectedCategory)) {
                                            selectedCategory = null;
                                          }
                                          if (selectedWallet != null && !walletNames.contains(selectedWallet)) {
                                            selectedWallet = null;
                                          }
                                          // Initialize sensible defaults if nothing is chosen yet
                                          selectedCategory ??= categoryNames.isNotEmpty ? categoryNames.first : null;
                                          selectedWallet ??= walletNames.isNotEmpty ? walletNames.first : null;
                                          return const SizedBox.shrink();
                                        }),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: type == 'expense'
                                                  ? Color(0xFF8E2DE2)
                                                  : type == 'credit'
                                                      ? Color(0xFF56ab2f)
                                                      : Color(0xFFFF512F),
                                              radius: 24,
                                              child: Icon(
                                                type == 'expense'
                                                    ? Icons.shopping_bag_rounded
                                                    : type == 'credit'
                                                        ? Icons.trending_up_rounded
                                                        : Icons.trending_down_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Text(
                                              type == 'expense'
                                                  ? 'Expense'
                                                  : type == 'credit'
                                                      ? 'Credit to Friend'
                                                      : 'Borrowed from Friend',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 18),
                                        TextField(
                                          controller: _descController,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.description, color: TColor.primary20),
                                            labelText: 'Description',
                                            labelStyle: TextStyle(color: Colors.white),
                                            filled: true,
                                            fillColor: TColor.gray60,
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white24),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: TColor.primary20),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 14),
                                        TextField(
                                          controller: _amountController,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.currency_rupee, color: TColor.secondaryG50),
                                            labelText: 'Amount',
                                            labelStyle: TextStyle(color: Colors.white),
                                            filled: true,
                                            fillColor: TColor.gray60,
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white24),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: TColor.secondaryG50),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 14),
                                        TextField(
                                          controller: _dateController,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.calendar_today, color: TColor.primary10),
                                            labelText: 'Date',
                                            labelStyle: TextStyle(color: Colors.white),
                                            filled: true,
                                            fillColor: TColor.gray60,
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white24),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: TColor.primary10),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 14),
                                        DropdownButtonFormField<String>(
                                          value: type,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.category, color: TColor.secondaryG50),
                                            filled: true,
                                            fillColor: Color(0xFF2c2e4a),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white24),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: TColor.secondaryG50),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          dropdownColor: Color(0xFF23243a),
                                          items: [
                                            DropdownMenuItem(value: 'expense', child: Text('Expense', style: TextStyle(color: Colors.white))),
                                            DropdownMenuItem(value: 'credit', child: Text('Credit to friend', style: TextStyle(color: Colors.white))),
                                            DropdownMenuItem(value: 'debit', child: Text('Borrowed from friend', style: TextStyle(color: Colors.white))),
                                          ],
                                          onChanged: (val) => setState(() => type = val ?? 'expense'),
                                        ),
                                        SizedBox(height: 14),
                                        if (type == 'expense')
                                          ((categories.map((c) => c['name']).toSet().length) > 0)
                                              ? DropdownButtonFormField<String>(
                                                  value: selectedCategory,
                                                  decoration: InputDecoration(
                                                    prefixIcon: Icon(Icons.label, color: TColor.primary20),
                                                    filled: true,
                                                    fillColor: Color(0xFF2c2e4a),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.white24),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: TColor.primary20),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  dropdownColor: Color(0xFF23243a),
                                                  items: categories
                                                      .map((c) => (c['name'] as String?)?.trim())
                                                      .where((e) => (e != null && e.isNotEmpty))
                                                      .cast<String>()
                                                      .toSet()
                                                      .map<DropdownMenuItem<String>>((name) => DropdownMenuItem<String>(value: name, child: Text(name, style: TextStyle(color: Colors.white))))
                                                      .toList(),
                                                  onChanged: (val) => setState(() => selectedCategory = val),
                                                )
                                              : Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text('No categories found. Add one first!', style: TextStyle(color: Colors.red)),
                                                ),
                                        if (wallets.isNotEmpty)
                                          DropdownButtonFormField<String>(
                                            value: selectedWallet,
                                            decoration: InputDecoration(
                                              prefixIcon: Icon(Icons.account_balance_wallet, color: TColor.secondaryG50),
                                              filled: true,
                                              fillColor: Color(0xFF2c2e4a),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.white24),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: TColor.secondaryG50),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            dropdownColor: Color(0xFF23243a),
                                            items: wallets
                                                .map((w) => (w['name'] as String?)?.trim())
                                                .where((e) => (e != null && e.isNotEmpty))
                                                .cast<String>()
                                                .toSet()
                                                .map<DropdownMenuItem<String>>((name) => DropdownMenuItem<String>(value: name, child: Text(name, style: TextStyle(color: Colors.white))))
                                                .toList(),
                                            onChanged: (val) => setState(() => selectedWallet = val),
                                          )
                                        else
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text('No wallets/accounts found. Add one first!', style: TextStyle(color: Colors.red)),
                                          ),
                                        SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                                            ),
                                            SizedBox(width: 12),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: TColor.primary20,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: () {
                                                final desc = _descController.text.trim();
                                                final amt = _amountController.text.trim();
                                                final date = _dateController.text.trim();
                                                if (desc.isNotEmpty && amt.isNotEmpty && date.isNotEmpty && selectedWallet != null && (type != 'expense' || selectedCategory != null)) {
                                                  Navigator.pop(context, {"desc": desc, "amount": amt, "date": date, "type": type, "wallet": selectedWallet, "category": selectedCategory});
                                                }
                                              },
                                              child: Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                elevation: 16,
                              ),
                            );
                          },
                        );
                        if (result != null && result["desc"] != null && result["amount"] != null && result["wallet"] != null) {
                          // If expense, save to persistent expenses with category
                          if (result["type"] == "expense" && result["category"] != null) {
                            // Persist to local and enqueue a single expense add for cloud sync
                            await StorageService.addExpense({
                              "desc": result["desc"],
                              "amount": result["amount"],
                              "date": DateTime.now().toIso8601String(),
                              "wallet": result["wallet"],
                              "category": result["category"],
                            });
                          }
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
                            "date": DateTime.now().toIso8601String(),
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
                              color: TColor.secondary.withValues(alpha: 0.25),
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
