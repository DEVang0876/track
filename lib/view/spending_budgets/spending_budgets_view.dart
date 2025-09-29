import 'package:trackizer/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common_widget/custom_arc_180_painter.dart';
import '../settings/settings_view.dart';

class SpendingBudgetsView extends StatefulWidget {
  const SpendingBudgetsView({super.key});

  @override
  State<SpendingBudgetsView> createState() => _SpendingBudgetsViewState();
}

class _SpendingBudgetsViewState extends State<SpendingBudgetsView> {
  List<Map<String, dynamic>> categoryArr = [];
  List<Map<String, dynamic>> expensesArr = [];

  final List<Color> _categoryColors = [
    TColor.primary20,
    TColor.primary10,
    TColor.secondary50,
    TColor.secondary0,
    TColor.secondaryG50,
    TColor.primary5,
    TColor.primary0,
    TColor.gray60,
    TColor.gray40,
    TColor.gray30
  ];


  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadCategories();
  }

  Future<void> _loadExpenses() async {
    expensesArr = await StorageService.loadExpenses();
    setState(() {});
  }

  Future<void> _loadCategories() async {
    final loaded = await StorageService.loadBudgets();
    // Deduplicate by normalized name (trim/lower), keep first occurrence
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final c in loaded) {
      final name = (c["name"]?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) {
        unique.add({
          "name": name,
          "color": c["color"],
        });
      }
    }
    categoryArr = unique;
    setState(() {});
  }

  Future<void> _saveCategories() async {
    // Deduplicate before save
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final c in categoryArr) {
      final name = (c["name"]?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) unique.add({"name": name, "color": c["color"]});
    }
    categoryArr = unique;
    await StorageService.saveBudgets(categoryArr);
    await _loadCategories(); // reload after save to ensure persistence
  }

  void _editCategory(int idx, Map<String, dynamic> newCategory) async {
    final newName = (newCategory["name"]?.toString() ?? '').trim();
    if (newName.isEmpty) return;
    final newKey = newName.toLowerCase();
    final existsAt = categoryArr.indexWhere((c) => (c["name"]?.toString() ?? '').trim().toLowerCase() == newKey);
    if (existsAt != -1 && existsAt != idx) {
      // Duplicate name; notify and bail
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category with same name already exists.')),
        );
      }
      return;
    }
    categoryArr[idx]["name"] = newName;
    categoryArr[idx]["color"] = newCategory["color"];
    await _saveCategories();
  }

  void _deleteCategory(int idx) async {
    categoryArr.removeAt(idx);
    await _saveCategories();
  }
  // Removed misplaced code blocks outside build method
  @override
  Widget build(BuildContext context) {
    // Calculate spend per normalized category
    final Map<String, double> spentPerCategory = {};
    final Map<String, String> displayNameFor = {};
    final Map<String, Color> colorFor = {};
    double totalSpent = 0;
    for (var exp in expensesArr) {
      final rawCat = (exp["category"]?.toString() ?? '').trim();
      if (rawCat.isEmpty) continue;
      final key = rawCat.toLowerCase();
      final amt = double.tryParse(exp["amount"].toString()) ?? 0.0;
      spentPerCategory[key] = (spentPerCategory[key] ?? 0.0) + amt;
      totalSpent += amt;
      // default display name if not present in categories
      displayNameFor.putIfAbsent(key, () => rawCat);
    }
    // Seed display names and colors from category list (deduped)
    for (int i = 0; i < categoryArr.length; i++) {
      final name = (categoryArr[i]["name"]?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final color = categoryArr[i]["color"] is int
          ? Color(categoryArr[i]["color"])
          : _categoryColors[i % _categoryColors.length];
      displayNameFor[key] = name; // prefer configured case
      colorFor[key] = color;
    }
    // Build arc data only for categories with spend > 0
    final keysWithSpend = spentPerCategory.keys.toList();
    keysWithSpend.sort();
    final List<ArcValueModel> arcData = [];
    int colorIdx = 0;
    for (final key in keysWithSpend) {
      final spent = spentPerCategory[key] ?? 0.0;
      if (spent <= 0) continue;
      final color = colorFor[key] ?? _categoryColors[colorIdx++ % _categoryColors.length];
      final percent = totalSpent > 0 ? spent / totalSpent : 0.0;
      arcData.add(ArcValueModel(color: color, value: percent * 180));
      colorFor.putIfAbsent(key, () => color); // ensure legend matches color
    }
    return Scaffold(
      backgroundColor: TColor.gray,
      appBar: AppBar(
        backgroundColor: TColor.gray,
        elevation: 0,
        title: null,
        actions: [
          IconButton(
            icon: Image.asset("assets/img/settings.png", width: 25, height: 25, color: TColor.gray30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColor.gray, TColor.gray80],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, color: TColor.primary20, size: 28),
                  SizedBox(width: 8),
                  Text('Spend Analysis', style: TextStyle(color: TColor.primaryText, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ],
              ),
              SizedBox(height: 12),
              if (spentPerCategory.isNotEmpty && totalSpent > 0)
                Card(
                  color: TColor.gray80,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 120,
                          width: 240,
                          child: CustomPaint(
                            painter: CustomArc180Painter(drwArcs: arcData),
                          ),
                        ),
                        SizedBox(height: 14),
                        ...keysWithSpend.map((key) {
                          final name = displayNameFor[key] ?? key;
                          final color = colorFor[key] ?? TColor.primary20;
                          final spent = spentPerCategory[key] ?? 0.0;
                          final percent = totalSpent > 0 ? spent / totalSpent : 0.0;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                CircleAvatar(backgroundColor: color, radius: 8),
                                SizedBox(width: 10),
                                Expanded(child: Text(name, style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w500))),
                                Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(color: TColor.secondaryG, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Text("₹${spent.toStringAsFixed(2)}", style: TextStyle(color: TColor.gray30)),
                              ],
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 12),
                        Divider(color: TColor.gray30, thickness: 1),
                        SizedBox(height: 6),
                        Text("Total spent: ₹${totalSpent.toStringAsFixed(2)}", style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: TextStyle(color: TColor.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary20,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text('Add', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onPressed: () {
                      final controller = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: TColor.gray80,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Add Category', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Category Name',
                                labelStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: TColor.gray60,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final name = controller.text.trim();
                                  if (name.isEmpty) return;
                                  final key = name.toLowerCase();
                                  final exists = categoryArr.any((c) => (c['name']?.toString() ?? '').trim().toLowerCase() == key);
                                  if (exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category already exists.')));
                                    return;
                                  }
                                  final color = _categoryColors[categoryArr.length % _categoryColors.length];
                                  setState(() {
                                    categoryArr.add({
                                      "name": name,
                                      "color": color.value,
                                    });
                                  });
                                  _saveCategories();
                                  Navigator.pop(context);
                                },
                                child: Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
              Expanded(
                child: categoryArr.isEmpty
                    ? Center(child: Text('No categories yet.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: categoryArr.length,
                        itemBuilder: (context, idx) {
                          final cat = categoryArr[idx];
                          final color = Color(cat['color']);
                          return Card(
                            color: TColor.gray80,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: color, radius: 16),
                              title: Text(cat['name'], style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w600)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.white70),
                                    onPressed: () {
                                      final editController = TextEditingController(text: cat['name']);
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: TColor.gray80,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: Text('Edit Category', style: TextStyle(color: Colors.white)),
                                            content: TextField(
                                              controller: editController,
                                              decoration: InputDecoration(labelText: 'Category Name'),
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _editCategory(idx, {
                                                    "name": editController.text.trim(),
                                                    "color": cat['color'],
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Save'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () {
                                                  _deleteCategory(idx);
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
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
      ),
    );
  }
}
