import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.
import 'package:provider/provider.dart'; // 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요.
import 'package:table_calendar/table_calendar.dart'; // 표 형태로 된 달력을 보여주는 라이브러리를 가져와요.
import '../services/astro_state.dart'; // 별자리 계산과 관련된 우리 앱의 기능을 가져와요.

// 화면에 달력을 보여주는 함수예요.
void showCalendarDialog(BuildContext context) {
  // 앱의 전체적인 상태(데이터)를 가져와요. 여기서는 날짜 정보가 필요해요.
  final provider = Provider.of<AstroState>(context, listen: false);
  
  DateTime focusedDay = provider.selectedDate.toLocal();
  final List<String> enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // 0: 일 선택 (TableCalendar), 1: 월 선택 (Grid), 2: 연도 선택 (Grid)
  int viewMode = 0;

  // 기준 연도를 2026년(현재 연도 주변)으로 설정하고 스크롤이 편하도록 조정
  // 예를 들어 2035년부터 1900년까지 표시 (총 136개)
  final int maxYear = DateTime.now().year + 10;
  final int minYear = 1900;
  final int totalYears = maxYear - minYear + 1;

  // 화면에 대화상자(팝업창)를 보여줘요.
  showDialog(
    context: context, // 이 대화상자를 어디에 보여줄지 알려줘요.
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final locale = Localizations.localeOf(context).languageCode;
          
          Widget content;

          if (viewMode == 2) {
            // --- 연도 선택 화면 ---
            content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    locale == 'ko' ? '연도 선택' : 'Select Year',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 다시 3칸으로 변경하여 간격을 적절히
                      childAspectRatio: 1.3, // 세로 비율 조정
                    ),
                    itemCount: totalYears, 
                    itemBuilder: (context, index) {
                      final year = maxYear - index;
                      final isSelected = year == focusedDay.year;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            focusedDay = DateTime(year, focusedDay.month, focusedDay.day);
                            viewMode = 1; // 연도 선택 후 월 선택으로 이동
                          });
                        },
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              locale == 'ko' ? '$year년' : '$year',
                              style: TextStyle(
                                fontSize: 16, // 가독성 좋은 적절한 크기로 변경
                                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (viewMode == 1) {
            // --- 월 선택 화면 ---
            content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        viewMode = 2; // 제목 누르면 다시 연도 선택으로 이동
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale == 'ko' ? '${focusedDay.year}년' : '${focusedDay.year}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.arrow_drop_up),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3줄로 변경
                      childAspectRatio: 2.0, // 버튼 가로세로 비율
                      mainAxisSpacing: 16.0, // 상하 간격 추가
                      crossAxisSpacing: 16.0, // 좌우 간격 추가
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = month == focusedDay.month;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            focusedDay = DateTime(focusedDay.year, month, focusedDay.day);
                            viewMode = 0; // 월 선택 후 기존 달력(일 선택)으로 이동
                          });
                        },
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              locale == 'ko' ? '$month월' : enMonths[month - 1],
                              style: TextStyle(
                                fontSize: 16, // 가독성 좋은 적절한 크기로 변경
                                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            // --- 기존 달력 화면 (일 선택) ---
            content = TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime(1900),
              lastDay: DateTime(2100),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: const HeaderStyle(
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        viewMode = 2; // 날짜(제목)를 누르면 연도 선택 화면으로 이동
                      });
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            locale == 'ko' ? '${day.year}년 ${day.month}월' : '${enMonths[day.month - 1]} ${day.year}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  );
                },
              ),
              onPageChanged: (newFocusedDay) {
                setState(() {
                  focusedDay = newFocusedDay;
                });
              },
              selectedDayPredicate: (day) => isSameDay(provider.selectedDate.toLocal(), day),
              onDaySelected: (selectedDay, focusedDay) {
                final newDate = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                  12,
                );
                provider.updateDate(newDate);
                Navigator.of(context).pop();
              },
            );
          }

          return Dialog(
            child: SizedBox(
              width: 1000,
              height: 480,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          );
        },
      );
    },
  );
}
