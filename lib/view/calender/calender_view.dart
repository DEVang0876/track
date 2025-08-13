import 'dart:math';

import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:flutter/material.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/view/settings/settings_view.dart';

import 'package:trackizer/storage/storage_service.dart';

import '../../common_widget/subscription_cell.dart';

class CalenderView extends StatefulWidget {
  const CalenderView({super.key});

  @override
  State<CalenderView> createState() => _CalenderViewState();
}

class _CalenderViewState extends State<CalenderView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _allEntries = [];
  Map<DateTime, List<Map<String, dynamic>>> _entriesByDate = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    // Load all expenses, borrow, credit entries from storage
    final expenses = await StorageService.loadExpenses();
    // You may need to load other types if stored separately
    setState(() {
      _allEntries = expenses;
      _entriesByDate = {};
      for (var entry in _allEntries) {
        if (entry["date"] != null) {
          final date = DateTime.parse(entry["date"]).toLocal();
          final key = DateTime(date.year, date.month, date.day);
          _entriesByDate.putIfAbsent(key, () => []).add(entry);
        }
      }
    });
  }

  double _getTotalExpenseForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final entries = _entriesByDate[key] ?? [];
    double total = 0;
    for (var e in entries) {
      if (e["type"] == "expense" || e["_entryType"] == "expense") {
        total += double.tryParse(e["amount"].toString()) ?? 0;
      }
    }
    return total;
  }

  Color _getDateColor(DateTime date) {
    double total = _getTotalExpenseForDate(date);
    if (total == 0) return Colors.green[200]!;
    if (total < 500) return Colors.green;
    if (total < 2000) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> _getEntriesForSelectedDay() {
    if (_selectedDay == null) return [];
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    return _entriesByDate[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday;

    List<Widget> calendarRows = [];
    List<Widget> currentRow = [];
    int dayCounter = 1;
    // Fill initial empty days
    for (int i = 1; i < startWeekday; i++) {
      currentRow.add(Expanded(child: Container()));
    }
    while (dayCounter <= daysInMonth) {
      while (currentRow.length < 7 && dayCounter <= daysInMonth) {
        final date = DateTime(now.year, now.month, dayCounter);
        final isSelected = _selectedDay != null && date.year == _selectedDay!.year && date.month == _selectedDay!.month && date.day == _selectedDay!.day;
        currentRow.add(
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = date;
                });
              },
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? TColor.primary20 : _getDateColor(date),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: TColor.primaryText, width: 2) : null,
                ),
                height: 40,
                child: Center(
                  child: Text(
                    dayCounter.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : TColor.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        dayCounter++;
      }
      calendarRows.add(Row(children: currentRow));
      currentRow = [];
    }

    return Scaffold(
      backgroundColor: TColor.gray,
      appBar: AppBar(
        backgroundColor: TColor.gray,
        elevation: 0,
        title: Text('Calendar', style: TextStyle(color: TColor.primaryText)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: TColor.gray30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsView()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "${now.year} - ${now.month.toString().padLeft(2, '0')}",
              style: TextStyle(color: TColor.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...calendarRows,
            SizedBox(height: 18),
            if (_selectedDay != null)
              Text(
                "Entries for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                style: TextStyle(color: TColor.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            if (_selectedDay != null)
              Expanded(
                child: _getEntriesForSelectedDay().isEmpty
                    ? Center(child: Text('No entries for this date.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _getEntriesForSelectedDay().length,
                        itemBuilder: (context, idx) {
                          final entry = _getEntriesForSelectedDay()[idx];
                          final type = entry["type"] ?? entry["_entryType"] ?? "";
                          final desc = entry["desc"] ?? "";
                          final amount = entry["amount"] ?? "";
                          final color = type == "expense" ? Colors.red[300] : (type == "credit" ? Colors.green[300] : Colors.orange[300]);
                          return Card(
                            color: color,
                            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            child: ListTile(
                              title: Text(desc, style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w600)),
                              subtitle: Text(type, style: TextStyle(color: Colors.white70)),
                              trailing: Text("₹${amount}", style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
