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
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay = DateTime.now();
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
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
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
        final date = DateTime(_currentMonth.year, _currentMonth.month, dayCounter);
        final isSelected = _selectedDay != null && date.year == _selectedDay!.year && date.month == _selectedDay!.month && date.day == _selectedDay!.day;
        currentRow.add(
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = date;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.all(isSelected ? 2 : 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [TColor.primary20, TColor.primary10])
                      : LinearGradient(colors: [
                          _getDateColor(date).withOpacity(0.8),
                          Colors.white.withOpacity(0.2)
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(isSelected ? 16 : 10),
                  border: isSelected ? Border.all(color: TColor.primaryText, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? TColor.primary20.withOpacity(0.25) : Colors.black.withOpacity(0.10),
                      blurRadius: isSelected ? 16 : 8,
                      offset: Offset(0, isSelected ? 6 : 2),
                    ),
                  ],
                ),
                height: isSelected ? 54 : 44,
                child: Center(
                  child: Text(
                    dayCounter.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 22 : 18,
                      shadows: isSelected ? [Shadow(color: Colors.black26, blurRadius: 6)] : [],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: TColor.primaryText, size: 32),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      _selectedDay = null;
                    });
                  },
                ),
                Text(
                  "${_currentMonth.year} - ${_currentMonth.month.toString().padLeft(2, '0')}",
                  style: TextStyle(color: TColor.primaryText, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: TColor.primaryText, size: 32),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      _selectedDay = null;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            ...calendarRows,
            SizedBox(height: 18),
            if (_selectedDay != null)
              Text(
                "Entries for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                style: TextStyle(color: TColor.primaryText, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            if (_selectedDay != null)
              Expanded(
                child: _getEntriesForSelectedDay().isEmpty
                    ? Center(child: Text('No entries for this date.', style: TextStyle(color: Colors.white54, fontSize: 16)))
                    : ListView.builder(
                        itemCount: _getEntriesForSelectedDay().length,
                        itemBuilder: (context, idx) {
                          final entry = _getEntriesForSelectedDay()[idx];
                          final type = (entry["type"] ?? entry["_entryType"] ?? "").toString().toLowerCase();
                          final desc = entry["desc"] ?? "";
                          final amount = entry["amount"] ?? "";
                          final wallet = entry["wallet"] ?? "";
                          final dateStr = entry["date"] != null ? entry["date"].toString().replaceFirst('T', ' ') : "";

                          IconData iconData;
                          Color iconBg;
                          if (type.contains("expense")) {
                            iconData = Icons.shopping_bag_rounded;
                            iconBg = Color(0xFF8E2DE2); // purple
                          } else if (type.contains("credit")) {
                            iconData = Icons.trending_up_rounded;
                            iconBg = Color(0xFF56ab2f); // green
                          } else if (type.contains("borrow") || type.contains("debit")) {
                            iconData = Icons.trending_down_rounded;
                            iconBg = Color(0xFFFF512F); // orange/red
                          } else {
                            iconData = Icons.info_outline;
                            iconBg = Colors.blueGrey; // info
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            decoration: BoxDecoration(
                              color: Color(0xFF4A3F3F),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.13),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircleAvatar(
                                    backgroundColor: iconBg,
                                    radius: 24,
                                    child: Icon(iconData, color: Colors.white, size: 28),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 18.0, bottom: 12.0, right: 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(desc.toString(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                            Padding(
                                              padding: const EdgeInsets.only(right: 16.0),
                                              child: Text("₹${amount}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.13),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(type, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                            ),
                                            if (desc.isNotEmpty) ...[
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.13),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(desc, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                              ),
                                            ],
                                            if (wallet.isNotEmpty) ...[
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.13),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(wallet, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, color: Colors.white54, size: 18),
                                            SizedBox(width: 6),
                                            Text(dateStr, style: TextStyle(color: Colors.white70, fontSize: 15)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
