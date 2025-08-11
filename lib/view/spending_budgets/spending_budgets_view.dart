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
  List<Map<String, dynamic>> expensesArr = [];


  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    expensesArr = await StorageService.loadExpenses();
    setState(() {});
  }
  final TextEditingController _catNameController = TextEditingController();
  Color _selectedColor = TColor.secondaryG;
  List<Map<String, dynamic>> categoryArr = [];



  Future<void> _loadBudgets() async {
    categoryArr = await StorageService.loadBudgets();
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    await StorageService.saveBudgets(categoryArr);
  }

  void _addCategory() async {
    final name = _catNameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        categoryArr.add({
          "name": name,
          "color": _selectedColor.value
        });
        _catNameController.clear();
        _selectedColor = TColor.secondaryG;
      });
      await _saveBudgets();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category added!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a category name.')));
    }
  }

  void _deleteCategory(int idx) async {
    setState(() {
      categoryArr.removeAt(idx);
    });
    await _saveBudgets();
  }

  void _editCategory(int idx, Map<String, dynamic> newCategory) async {
    if (newCategory['color'] is Color) {
      newCategory['color'] = (newCategory['color'] as Color).value;
    }
    setState(() {
      categoryArr[idx] = newCategory;
    });
    await _saveBudgets();
  }

  @override
  Widget build(BuildContext context) {
  // var media = MediaQuery.sizeOf(context); // unused
    // Calculate total spent per category
    Map<String, double> spentPerCategory = {};
    double totalSpent = 0;
    for (var exp in expensesArr) {
      final cat = exp["category"];
      final amt = double.tryParse(exp["amount"].toString()) ?? 0;
      if (cat != null) {
        spentPerCategory[cat] = (spentPerCategory[cat] ?? 0) + amt;
        totalSpent += amt;
      }
    }
    // Prepare arc data
    List<Widget> arcWidgets = [];
    List<ArcValueModel> arcData = [];
    for (var cat in categoryArr) {
      final name = cat["name"];
      final color = cat["color"] is int ? Color(cat["color"]) : (cat["color"] ?? TColor.secondaryG);
      final spent = spentPerCategory[name] ?? 0;
      final percent = totalSpent > 0 ? spent / totalSpent : 0;
      arcData.add(ArcValueModel(color: color, value: percent * 180));
      arcWidgets.add(
        Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 7),
            SizedBox(width: 8),
            Text(name, style: TextStyle(color: TColor.white)),
            SizedBox(width: 8),
            Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(color: TColor.gray30)),
            SizedBox(width: 8),
            Text("${spent.toStringAsFixed(2)}", style: TextStyle(color: TColor.gray30)),
          ],
        ),
      );
    }
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
            SizedBox(height: 20),
            // Arc breakdown
            if (categoryArr.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: 120,
                    width: 240,
                    child: CustomPaint(
                      painter: CustomArc180Painter(drwArcs: arcData),
                    ),
                  ),
                  SizedBox(height: 10),
                  ...arcWidgets,
                  SizedBox(height: 10),
                  Text("Total spent: ${totalSpent.toStringAsFixed(2)}", style: TextStyle(color: TColor.white)),
                ],
              ),
            const SizedBox(height: 40),
            // List of categories
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categoryArr.length,
              itemBuilder: (context, index) {
                var cObj = categoryArr[index];
                final cObjWithColor = Map<String, dynamic>.from(cObj);
                if (cObjWithColor['color'] is int) {
                  cObjWithColor['color'] = Color(cObjWithColor['color']);
                }
                return ListTile(
                  leading: CircleAvatar(backgroundColor: cObjWithColor['color'], radius: 16),
                  title: Text(cObjWithColor['name'], style: TextStyle(color: TColor.white)),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: TColor.gray30),
                    onPressed: () {
                      final editCatController = TextEditingController(text: cObjWithColor['name']);
                      Color editColor = cObjWithColor['color'];
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: editCatController,
                                  decoration: InputDecoration(labelText: 'Category Name'),
                                ),
                                Row(
                                  children: [
                                    Text('Color: '),
                                    GestureDetector(
                                      onTap: () async {
                                        // Optionally implement color picker
                                      },
                                      child: CircleAvatar(backgroundColor: editColor, radius: 12),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      child: Text('Save'),
                                      onPressed: () {
                                        final newCategory = {
                                          "name": editCatController.text.trim(),
                                          "color": editColor.value
                                        };
                                        _editCategory(index, newCategory);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ElevatedButton(
                                      child: Text('Delete'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        _deleteCategory(index);
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
                  ),
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
                            Row(
                              children: [
                                Text('Color: '),
                                GestureDetector(
                                  onTap: () async {
                                    // Optionally implement color picker
                                  },
                                  child: CircleAvatar(backgroundColor: _selectedColor, radius: 12),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              child: Text('Add Category'),
                              onPressed: _addCategory,
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
