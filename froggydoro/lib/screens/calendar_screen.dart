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
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
    datesGrid = _generateDatesGrid(currentMonth);
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
      dates.add(DateTime(previousMonth.year, previousMonth.month,
          previousMonthLastDay - i + 1));
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

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
      datesGrid = _generateDatesGrid(currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final backgroundBlockColor = brightness == Brightness.dark
        ? const Color(0xFF3A4A38)
        : const Color(0xFFE4E8CD);

    final bubbleColor = brightness == Brightness.dark
        ? const Color(0xFF63805C)
        : const Color(0xFFC8CBB2);

    final textColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    
    final bool isCalendarScreen = true; // you're on this screen

    return SingleChildScrollView(      
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Refresh
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCalendarScreen ? bubbleColor : backgroundBlockColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              ),
              child: Text(
                'Calendar',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !isCalendarScreen ? bubbleColor : backgroundBlockColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              ),
              child: Text(
                'Achievements',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),


        const SizedBox(height: 16),
        
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
                        ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: textColor.withOpacity(0.7),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                              final entries = await _databaseService.getWorkEntriesForDate(formattedDate);
                              //await _databaseService.checkDatabase();  // For testing only 
                              
                              // This counts test duration
                              // final totalCount = entries.where((entry) =>
                              //     entry.type == 'work' && entry.status == 'completed').length;

                              // Filter entries that would not count test durations
                              final filteredEntries = entries.where((entry) =>
                                  entry.type == 'work' &&
                                  entry.status == 'completed' &&
                                  entry.duration > 0).toList();

                              // Calculates the sum of all the minutes in the entries that have completed work sessions 
                              final totalMinutes = entries
                                  .where((e) => e.type == 'work' && e.status == 'completed')
                                  .fold(0, (sum, e) => sum + e.duration);
                              
                              setState(() {                                
                                selectedDate = date;
                                focusMinutes = totalMinutes;
                                focusCount = filteredEntries.length;
                                //focusCount = filteredEntries.length;
                              });
                          }
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: isCurrentMonth
                              ? (selectedDate != null && _isSameDay(selectedDate!, date)
                                  ? Colors.amber 
                                  : bubbleColor)
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
                Text(
                  'Total Focus Count: $focusCount Times',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8), // space between lines
                const SizedBox(height: 8),
                Text(
                  'Total Focus Minute: $focusMinutes minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
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
      'December'
    ][monthNumber - 1];
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}