# KillerDateTableRu
Функция, возвращающая таблицу-календарь с полями для Time Intelligence BI функций. 
Среди полей есть флаг рабочего-нерабочего дня (по данным производственного календаря). 
Для Power Query.


## Список столбцов и примеры значений

| Название столбца             | Пример данных |
|------------------------------|---------------|
| Date                         | 01.01.2015    |
| DayOfMonthNumber             | 1             |
| DaySeqNumber                 | 1             |
| DaySeqNumberReverse          | -1431         |
| DayOfWeekName                | четверг       |
| DayOfWeekNumber              | 4             |
| DayOfYearNumber              | 1             |
| WeekCalendarSeqNumber        | 1             |
| WeekCalendarSeqNumberReverse | -204          |
| WeekStart                    | 29.12.2014    |
| WeekEnd                      | 04.01.2015    |
| WeekSeqNumberReverse         | -204          |
| WeekOfYearNumber             | 1             |
| MonthAndYear                 | Янв 2015      |
| MonthName                    | Январь        |
| MonthSeqNumber               | 1             |
| MonthSeqNumberReverse        | 48            |
| MonthOfYearNumber            | 1             |
| MonthStartDate               | 01.01.2015    |
| QuarterAndYear               | Q1 2015       |
| QuarterOfYear                | 1             |
| Year                         | 2015          |
| YearMonthDateNumber          | 20150101      |
| YearMonthNumber              | 201501        |
| IsHolidayInRussia            | true          |
| IsShortDayInRussia           | false         |
