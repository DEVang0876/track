import 'package:trackizer/storage/storage_service.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common_widget/budgets_row.dart';
import 'package:trackizer/common_widget/custom_arc_180_painter.dart';

import '../settings/settings_view.dart';

class SpendingBudgetsView extends StatefulWidget {
  const SpendingBudgetsView({super.key});

  @override
  State<SpendingBudgetsView> createState() => _SpendingBudgetsViewState();
}

class _SpendingBudgetsViewState extends State<SpendingBudgetsView> {
  final TextEditingController _catNameController = TextEditingController();
  final TextEditingController _spendAmountController = TextEditingController();
  final TextEditingController _totalBudgetController = TextEditingController();
  final TextEditingController _leftAmountController = TextEditingController();
  List<Map<String, dynamic>> budgetArr = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    budgetArr = await StorageService.loadBudgets();
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    await StorageService.saveBudgets(budgetArr);
  }

  void _addBudget() async {
    final name = _catNameController.text.trim();
    final spend = _spendAmountController.text.trim();
    final total = _totalBudgetController.text.trim();
    final left = _leftAmountController.text.trim();
    if (name.isNotEmpty && spend.isNotEmpty && total.isNotEmpty && left.isNotEmpty) {
      setState(() {
        budgetArr.add({
          "name": name,
          "icon": "assets/img/add.png", // default icon
          "spend_amount": spend,
          "total_budget": total,
          "left_amount": left,
          "color": TColor.secondaryG.value // store as int
        });
        _catNameController.clear();
        _spendAmountController.clear();
        _totalBudgetController.clear();
        _leftAmountController.clear();
      });
      await _saveBudgets();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category added!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields.')));
    }
  }

  void _deleteBudget(int idx) async {
    setState(() {
      budgetArr.removeAt(idx);
    });
    await _saveBudgets();
  }

  void _editBudget(int idx, Map<String, dynamic> newBudget) async {
    // Ensure color is stored as int
    if (newBudget['color'] is Color) {
      newBudget['color'] = (newBudget['color'] as Color).value;
    }
    setState(() {
      budgetArr[idx] = newBudget;
    });
    await _saveBudgets();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 35, right: 10),
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsView()));
                      },
                      icon: Image.asset("assets/img/settings.png",
                          width: 25, height: 25, color: TColor.gray30))
                ],
              ),
            ),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: media.width * 0.5,
                  height: media.width * 0.30,
                  child: CustomPaint(
                    painter: CustomArc180Painter(
                      drwArcs: [
                        ArcValueModel(color: TColor.secondaryG, value: 20),
                        ArcValueModel(color: TColor.secondary, value: 45),
                        ArcValueModel(color: TColor.primary10, value: 70),
                      ],
                      end: 50,
                      width: 12,
                      bgWidth: 8,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "\$82,90",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      "of \$2,0000 budget",
                      style: TextStyle(
                          color: TColor.gray30,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Budgets'),
                      content: Text('Your budgets are on track!'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                    ),
                  );
                },
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: TColor.border.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Your budgets are on tack 👍",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: budgetArr.length,
              itemBuilder: (context, index) {
                var bObj = budgetArr[index];
                // Convert color int to Color for UI
                final bObjWithColor = Map<String, dynamic>.from(bObj);
                if (bObjWithColor['color'] is int) {
                  bObjWithColor['color'] = Color(bObjWithColor['color']);
                }
                return BudgetsRow(
                  bObj: bObjWithColor,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        final editCatController = TextEditingController(text: bObjWithColor['name']);
                        final editSpendController = TextEditingController(text: bObjWithColor['spend_amount']);
                        final editTotalController = TextEditingController(text: bObjWithColor['total_budget']);
                        final editLeftController = TextEditingController(text: bObjWithColor['left_amount']);
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: editCatController,
                                decoration: InputDecoration(labelText: 'Category Name'),
                              ),
                              TextField(
                                controller: editSpendController,
                                decoration: InputDecoration(labelText: 'Spend Amount'),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: editTotalController,
                                decoration: InputDecoration(labelText: 'Total Budget'),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: editLeftController,
                                decoration: InputDecoration(labelText: 'Left Amount'),
                                keyboardType: TextInputType.number,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      final newBudget = {
                                        "name": editCatController.text.trim(),
                                        "icon": bObjWithColor['icon'],
                                        "spend_amount": editSpendController.text.trim(),
                                        "total_budget": editTotalController.text.trim(),
                                        "left_amount": editLeftController.text.trim(),
                                        "color": bObjWithColor['color'] is Color ? bObjWithColor['color'].value : bObjWithColor['color']
                                      };
                                      _editBudget(index, newBudget);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ElevatedButton(
                                    child: Text('Delete'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () {
                                      _deleteBudget(index);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _catNameController,
                              decoration: InputDecoration(labelText: 'Category Name'),
                            ),
                            TextField(
                              controller: _spendAmountController,
                              decoration: InputDecoration(labelText: 'Spend Amount'),
                              keyboardType: TextInputType.number,
                            ),
                            TextField(
                              controller: _totalBudgetController,
                              decoration: InputDecoration(labelText: 'Total Budget'),
                              keyboardType: TextInputType.number,
                            ),
                            TextField(
                              controller: _leftAmountController,
                              decoration: InputDecoration(labelText: 'Left Amount'),
                              keyboardType: TextInputType.number,
                            ),
                            ElevatedButton(
                              child: Text('Add Category'),
                              onPressed: _addBudget,
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
                child: DottedBorder(
                  dashPattern: const [5, 4],
                  strokeWidth: 1,
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  color: TColor.border.withOpacity(0.1),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add new category ",
                          style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Image.asset(
                          "assets/img/add.png",
                          width: 12,
                          height: 12,
                          color: TColor.gray30,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 110,
            ),
          ],
        ),
      ),
    );
  }
}
