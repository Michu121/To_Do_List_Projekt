import 'package:flutter/material.dart';

extension DateTimeExt on DateTime {
  DateTime get monthStart => DateTime(year, month);
  DateTime get dayStart => DateTime(year, month, day);

  DateTime addMonth(int count) {
    return DateTime(year, month + count, day);
  }

  bool isSameDate(DateTime date) {
    return year == date.year && month == date.month && day == date.day;
  }

  bool get isToday {
    return isSameDate(DateTime.now());
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime selectedMonth;
  DateTime? selectedDate;

  @override
  void initState() {
    selectedMonth = DateTime.now().monthStart;
    selectedDate = DateTime.now().dayStart;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              selectedMonth: selectedMonth,
              selectedDate: selectedDate,
              onChange: (value) => setState(() => selectedMonth = value),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _Body(
                selectedDate: selectedDate,
                selectedMonth: selectedMonth,
                selectDate: (DateTime value) => setState(() {
                  selectedDate = value;
                }),
              ),
            ),
            _Bottom(
              selectedDate: selectedDate,
            )
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.selectedMonth,
    required this.selectedDate,
    required this.selectDate,
  });

  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> selectDate;

  @override
  Widget build(BuildContext context) {
    var data = CalendarMonthData(
      year: selectedMonth.year,
      month: selectedMonth.month,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('M', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('T', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('W', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('T', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('F', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('S', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text('S', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.blue.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (var week in data.weeks)
                  Row(
                    children: week.map((d) {
                      return Expanded(
                        child: _RowItem(
                          date: d.date,
                          isActiveMonth: d.isActiveMonth,
                          onTap: () => selectDate(d.date),
                          isSelected: selectedDate != null && selectedDate!.isSameDate(d.date),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.isActiveMonth,
    required this.isSelected,
    required this.date,
    required this.onTap,
  });

  final bool isActiveMonth;
  final VoidCallback onTap;
  final bool isSelected;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = date.isToday;
    final bool isPassed = date.isBefore(DateTime.now().dayStart);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        height: 50,
        margin: const EdgeInsets.all(2),
        decoration: isSelected
            ? const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)
            : isToday
            ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blueAccent, width: 2),
        )
            : null,
        child: Text(
          date.day.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : isPassed
                ? (isActiveMonth ? Colors.grey[700] : Colors.transparent)
                : (isActiveMonth ? Colors.lightBlue[200] : Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.selectedMonth,
    required this.selectedDate,
    required this.onChange,
  });

  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            selectedDate == null
                ? 'No date selected'
                : 'Selected: ${selectedDate!.day} ${months[selectedDate!.month - 1]} ${selectedDate!.year}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onChange(selectedMonth.addMonth(-1)),
                icon: const Icon(Icons.chevron_left, color: Colors.blueAccent, size: 30),
              ),
              Text(
                '${months[selectedMonth.month - 1]} ${selectedMonth.year}',
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold
                ),
              ),
              IconButton(
                onPressed: () => onChange(selectedMonth.addMonth(1)),
                icon: const Icon(Icons.chevron_right, color: Colors.blueAccent, size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.selectedDate});
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () {
            if (selectedDate != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
              );
            }
          },
          child: const Text('test', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class CalendarMonthData {
  final int year;
  final int month;

  const CalendarMonthData({required this.year, required this.month});

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  int get firstDayOffset {
    int weekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    return weekday - 1;
  }

  int get weeksCount => ((daysInMonth + firstDayOffset) / 7).ceil();

  List<List<CalendarDayData>> get weeks {
    final res = <List<CalendarDayData>>[];
    var firstDayMonth = DateTime(year, month, 1);
    var firstDayToShow = firstDayMonth.subtract(Duration(days: firstDayOffset));

    for (var w = 0; w < weeksCount; w++) {
      final week = List<CalendarDayData>.generate(7, (index) {
        final date = firstDayToShow.add(Duration(days: index));
        return CalendarDayData(
          date: date,
          isActiveMonth: date.year == year && date.month == month,
          isActiveDate: date.isToday,
        );
      });
      res.add(week);
      firstDayToShow = firstDayToShow.add(const Duration(days: 7));
    }
    return res;
  }
}

class CalendarDayData {
  final DateTime date;
  final bool isActiveMonth;
  final bool isActiveDate;

  const CalendarDayData({
    required this.date,
    required this.isActiveMonth,
    required this.isActiveDate,
  });
}