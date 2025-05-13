import 'package:flutter/material.dart';
import 'package:froggydoro/screens/achievement_screen.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime currentMonth;
  late List<DateTime> datesGrid;

  DateTime? selectedDate;
  int focusMinutes = 0;
  int focusCount = 0;
  int monthlyFocusMinutes = 0;
  int monthlyFocusCount = 0;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
    datesGrid = _generateDatesGrid(currentMonth);
    _loadMonthlyStats();
  }

  ///Generates a grid where the months will be filled with dates
  List<DateTime> _generateDatesGrid(DateTime month) {
    int numDays = DateTime(month.year, month.month + 1, 0).day;
    int firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    List<DateTime> dates = [];

    /// Fill previous month's dates
    DateTime previousMonth = DateTime(month.year, month.month - 1);
    int previousMonthLastDay =
        DateTime(previousMonth.year, previousMonth.month + 1, 0).day;
    for (int i = firstWeekday; i > 0; i--) {
      dates.add(
        DateTime(
          previousMonth.year,
          previousMonth.month,
          previousMonthLastDay - i + 1,
        ),
      );
    }

    // Fill current month's dates
    for (int day = 1; day <= numDays; day++) {
      dates.add(DateTime(month.year, month.month, day));
    }

    // Fill next month's dates
    int remainingBoxes = 42 - dates.length; // 6 weeks * 7 days
    for (int day = 1; day <= remainingBoxes; day++) {
      dates.add(DateTime(month.year, month.month + 1, day));
    }

    return dates;
  }

  // Add this method to load monthly stats
  Future<void> _loadMonthlyStats() async {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );

    final String firstDay = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
    final String lastDay = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);

    // Get all entries for the month
    final entries = await _databaseService.getCalendarEntries();

    // Filter entries for the current month
    final monthEntries =
        entries.where((entry) {
          final entryDate = entry.date;
          return entryDate.year == currentMonth.year &&
              entryDate.month == currentMonth.month &&
              entry.type == 'work' &&
              entry.status == 'completed';
        }).toList();

    // Calculate stats
    final totalMinutes = monthEntries.fold(0, (sum, e) => sum + e.duration);
    final entryCount = monthEntries.length;

    setState(() {
      monthlyFocusMinutes = totalMinutes;
      monthlyFocusCount = entryCount;

      // If no date is selected, show monthly stats
      if (selectedDate == null) {
        focusMinutes = totalMinutes;
        focusCount = entryCount;
      }
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
      datesGrid = _generateDatesGrid(currentMonth);
      selectedDate = null; // Reset selected date when changing months

      // Reset stats to show monthly data
      focusMinutes = 0;
      focusCount = 0;
    });

    // Load stats for the new month
    _loadMonthlyStats();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final backgroundBlockColor =
        brightness == Brightness.dark
            ? const Color(0xFF3A4A38)
            : const Color(0xFFE4E8CD);
    final textColor =
        brightness == Brightness.dark ? Color(0xFFB0C8AE) : Color(0xFF586F51);

    final bool isCalendarScreen = true; // you're on this screen

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Calendar Block
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: backgroundBlockColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      '${_monthName(currentMonth.month)} ${currentMonth.year}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),

                // Weekdays
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      7,
                      (index) => Text(
                        [
                          'Sun',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                        ][index],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Calendar grid
                SizedBox(
                  height: 280,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: datesGrid.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                    itemBuilder: (context, index) {
                      DateTime date = datesGrid[index];
                      bool isCurrentMonth = date.month == currentMonth.month;

                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: GestureDetector(
                          onTap: () async {
                            if (isCurrentMonth) {
                              // Check if we're already viewing this date
                              if (selectedDate != null &&
                                  _isSameDay(selectedDate!, date)) {
                                // If the same date is tapped again, switch back to monthly view
                                setState(() {
                                  selectedDate = null;
                                  focusMinutes = monthlyFocusMinutes;
                                  focusCount = monthlyFocusCount;
                                });
                              } else {
                                // Different date tapped, show that date's stats
                                String formattedDate = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(date);
                                final entries = await _databaseService
                                    .getWorkEntriesForDate(formattedDate);

                                // Filter entries that would not count test durations
                                final filteredEntries =
                                    entries
                                        .where(
                                          (entry) =>
                                              entry.type == 'work' &&
                                              entry.status == 'completed' &&
                                              entry.duration > 0,
                                        )
                                        .toList();

                                // Calculates the sum of all the minutes in the entries that have completed work sessions
                                final totalMinutes = entries
                                    .where(
                                      (e) =>
                                          e.type == 'work' &&
                                          e.status == 'completed',
                                    )
                                    .fold(0, (sum, e) => sum + e.duration);

                                setState(() {
                                  selectedDate = date;
                                  focusMinutes = totalMinutes;
                                  focusCount = filteredEntries.length;
                                });
                              }
                            }
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                isCurrentMonth
                                    ? (selectedDate != null &&
                                            _isSameDay(selectedDate!, date)
                                        ? Colors.lightGreen
                                        : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(
                                          0xFF63805C,
                                        ) // Dark theme color
                                        : const Color(
                                          0xFFC8CBB2,
                                        )) // Light theme color
                                    : Colors.transparent,
                            child: Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: isCurrentMonth ? textColor : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Block for focus data
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: backgroundBlockColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shows if viewing daily or monthly stats
                Text(
                  selectedDate == null
                      ? 'Monthly Statistics (${_monthName(currentMonth.month)})'
                      : 'Daily Statistics (${DateFormat('MMM d, yyyy').format(selectedDate!)})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Focus Sessions: $focusCount',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Focus Minutes: $focusMinutes minutes',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///Finds the month based of the provided number
  String _monthName(int monthNumber) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][monthNumber - 1];
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
