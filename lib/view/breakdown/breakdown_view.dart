import 'package:flutter/material.dart';
import '../../common/color_extension.dart';

// Use the same globalExpenses list as in home_view.dart
import '../home/home_view.dart';

class BreakdownView extends StatelessWidget {
  const BreakdownView({super.key});

  @override
  Widget build(BuildContext context) {
    double totalExpenses = globalExpenses.where((e) => e['type'] == 'expense').fold(0.0, (sum, e) => sum + (double.tryParse(e['amount'] ?? '0') ?? 0));
    double totalBorrowed = globalExpenses.where((e) => e['type'] == 'debit').fold(0.0, (sum, e) => sum + (double.tryParse(e['amount'] ?? '0') ?? 0));
    double totalCredit = globalExpenses.where((e) => e['type'] == 'credit').fold(0.0, (sum, e) => sum + (double.tryParse(e['amount'] ?? '0') ?? 0));

    return Scaffold(
      backgroundColor: TColor.gray,
      appBar: AppBar(
        backgroundColor: TColor.gray,
        title: const Text('Breakdown', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text('Spent:  ₹${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)), backgroundColor: TColor.secondary),
                      Chip(label: Text('Borrowed:  ₹${totalBorrowed.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                      Chip(label: Text('Credit Given:  ₹${totalCredit.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Expenses', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...globalExpenses.asMap().entries.where((e) => e.value['type'] == 'expense').map((entry) {
              final exp = entry.value;
              return Card(
                color: TColor.gray60,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.attach_money, color: TColor.secondary),
                  title: Text(exp['desc'] ?? '', style: TextStyle(color: TColor.white)),
                  subtitle: Text(exp['date'] ?? '', style: TextStyle(color: TColor.gray30)),
                  trailing: Text('₹${exp['amount']}', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold)),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Borrowed from Friends', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...globalExpenses.asMap().entries.where((e) => e.value['type'] == 'debit').map((entry) {
              final exp = entry.value;
              return Card(
                color: Colors.red[100],
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.arrow_downward, color: Colors.red),
                  title: Text(exp['desc'] ?? '', style: TextStyle(color: Colors.red[900])),
                  subtitle: Text(exp['date'] ?? '', style: TextStyle(color: Colors.red[700])),
                  trailing: Text('₹${exp['amount']}', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Credit Given to Friends', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...globalExpenses.asMap().entries.where((e) => e.value['type'] == 'credit').map((entry) {
              final exp = entry.value;
              return Card(
                color: Colors.green[100],
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.arrow_upward, color: Colors.green),
                  title: Text(exp['desc'] ?? '', style: TextStyle(color: Colors.green[900])),
                  subtitle: Text(exp['date'] ?? '', style: TextStyle(color: Colors.green[700])),
                  trailing: Text('₹${exp['amount']}', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
