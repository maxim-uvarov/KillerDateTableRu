// KillerDateTable
let
    Source = (StartDateParam as date, EndDateParam as date, IndexReverse0Date as any, CultureParameter as any, RuHolidaysSwitchParameter as logical) => let

// killerDateTableRu v1.7 (https://github.com/power-bi/KillerDateTableRu)

// функция killerDateTableRu создает таблицу с датами. Дополняет ее различными полезными для Time Intelligence столбцами. 
// Первый аргумент - дата начала календаря
// Второй аргумент - последняя дата создаваемого календаря
// Третий аргумент ("IndexReverse0Date") - дата для определения нумерации столбцов Sequence Reverse. Столбцы удобны для построения отчетов
// с относительными времеными промежутками вчера, неделю назад и т.д. В качестве значений можно прописать дату в текстовом
// формате, в формате #date(01,01,2015) или в формате today, yesterday.
// Четвертый аргумент ("CultreParmeter") - задание локали, для подстановки названий дней недели или месяцев в соответстующие столбцы.
// Пятый аргумент ("RuHolidaysSwitchParameter") принимает значение 1 или true, то функция добавляет столбцы
// "IsShortDayInRussia" - флаг пометки сокращенного дня и "IsHolidayInRussia" -  флаг пометки выходного дня.

// Авторы:
// Дополнил русскими выходными и дополнительными столбцам Максим Уваров
// Причесал код, исправил ошибки Дмитрий Власов 

// Оригинальная идея календаря и названия Phil Britton https://gist.github.com/philbritton/9677152
// Похожие проекты: 
// 1. https://github.com/dmitriysolovev/powerbi/blob/master/fnDateTableRus
// 2. https://excel.city/2016/11/скачать-производственный-календарь/ 
// Пример использования функции: killerDateTableRu(#date(2017, 2, 1), #date(2017, 2, 4), "yesterday","RU-ru", 1)


  StartDateParameter = StartDateParam ,   
  EndDateParameter = EndDateParam,
  IsRuHolidaysParameter  = RuHolidaysSwitchParameter,

    MONTHS_ORDERED_BY_DEFAULT = {
        "Январь", "Февраль", "Март",
        "Апрель", "Май", "Июнь", 
        "Июль", "Август", "Сентябрь", 
        "Октябрь", "Ноябрь", "Декабрь"
      },

    getProductionCalendar = ( URL as text ) as nullable table =>
      let
          GetDataFromGovRu =
            Csv.Document( 
              Web.Contents( URL ),
              [ Delimiter  = ",",
                Encoding   = 65001,
                QuoteStyle = QuoteStyle.None ]
            ),

          #"Повышенные заголовки" = 
            Table.PromoteHeaders( GetDataFromGovRu ),
          
          #"Переименовали поле в год" = 
            Table.RenameColumns( #"Повышенные заголовки",
              { 
                {"Год/Месяц", "Год"}
              }
            ),

          #"Выбрали год и месяц" =
            Table.SelectColumns( #"Переименовали поле в год", 
              { "Год" } & MONTHS_ORDERED_BY_DEFAULT 
            ),

          #"Спрямили календарь" = 
            Table.UnpivotOtherColumns( #"Выбрали год и месяц", 
              { "Год" }, "Месяц", "День"
            ),
          
          #"Добавили номер месяца" = 
            Table.AddColumn( #"Спрямили календарь", "НомерМесяца", each 
              1 + List.PositionOf( MONTHS_ORDERED_BY_DEFAULT, [Месяц] ), 
              type number
            ),
          
          #"Преобразовали строку дат в список" =
            Table.TransformColumns( #"Добавили номер месяца",
              { 
                { "День", each Text.Split( _, "," ) }
              }
            ),

          #"Развернули список дней" = 
            Table.ExpandListColumn( #"Преобразовали строку дат в список",
              "День" 
            ),

          #"Добавили сокращенный день" = 
            Table.AddColumn( #"Развернули список дней", "Сокращенный День", each 
              Text.Contains( [День], "*" )
            ),

          #"Добавили выходной день" = 
            Table.AddColumn( #"Добавили сокращенный день", "Выходной День", each 
              not [Сокращенный День]
            ),

          #"Удалили признак сокращенного дня" = 
            Table.ReplaceValue( #"Добавили выходной день",
              "*", "", Replacer.ReplaceText, { "День" }
            ),

          #"Уточнли тип полей календаря" = 
            Table.TransformColumnTypes( #"Удалили признак сокращенного дня",
              {
                { "Год", Int64.Type },
                { "День", Int64.Type },
                { "НомерМесяца", Int64.Type }
              }
            ),

          #"Рассчитали дату" = 
            Table.AddColumn( #"Уточнли тип полей календаря", "Дата", each
              #date( [Год], [НомерМесяца], [День] )
            )
      in
          #"Рассчитали дату",

// Примечание: 
//  источник взят отсюда: http://data.gov.ru/opendata/7708660670-proizvcalendar
//  На момент 24.05.2018 в календаре содержатся описание праздников с 1999 года по 2025 год.
    PROD_СALENDAR_URL =
      "http://data.gov.ru/opendata/7708660670-proizvcalendar/data-20180410T1145-structure-20180410T1145.csv?encoding=UTF-8",
      
    PROD_СALENDAR_URL_Backup =
      "https://raw.githubusercontent.com/power-bi/KillerDateTableRu/master/data-20180410T1145-structure-20180410T1145.csv",

    ProductionCalendar = Table.Buffer( 
      try getProductionCalendar( PROD_СALENDAR_URL ) 
      otherwise getProductionCalendar( PROD_СALENDAR_URL_Backup ) 
      ) ,

    ListOfShortday = 
      Table.SelectRows( ProductionCalendar, each [Сокращенный День] = true )[Дата],
    
    ListOfHoliday =
      Table.SelectRows( ProductionCalendar, each [Выходной День] = true )[Дата],

    CheckIfThereIsShortdayList = 
      try List.Buffer( ListOfShortday ) otherwise {},

    CheckIfThereIsHolidayList = 
      try List.Buffer( ListOfHoliday ) otherwise {},

    DayCount = 
      Duration.Days( 
        Duration.From( 
          EndDateParameter - StartDateParameter 
        ) 
      ) + 1,
      
    ReverseIndex0DateInput = Text.Lower ( IndexReverse0Date ),
    ReverseIndex0Date = if ReverseIndex0DateInput = "today" then Date.From(DateTime.FixedLocalNow())
        else if ReverseIndex0DateInput = "yesterday" then Date.AddDays(Date.From(DateTime.FixedLocalNow()), -1)
        else try Date.From(ReverseIndex0DateInput) 
            otherwise Date.AddDays(Date.From(DateTime.FixedLocalNow()), 0),
            
    MainList = 
      List.Dates( StartDateParameter, DayCount, #duration( 1, 0, 0, 0 ) ),
    
    TableFromList = 
      Table.FromList( MainList, 
        Splitter.SplitByNothing(), { "Date" } 
      ),    
    
    ChangedType = 
      Table.TransformColumnTypes( TableFromList, 
        { 
          {"Date", type date } 
        } 
      ),
    
    Year = 
      Table.AddColumn( ChangedType, "Year", each 
        Date.Year( [Date] ), 
        Int64.Type
      ),
    
    QuarterOfYearNumber = 
      Table.AddColumn( Year, "QuarterOfYearNumber", each 
        Date.QuarterOfYear( [Date] ),
        Int64.Type
      ),
    
    MonthOfYearNumber = 
      Table.AddColumn( QuarterOfYearNumber, "MonthOfYearNumber", each
        Date.Month( [Date] ),
        Int64.Type 
      ),
    
    DayOfMonthNumber = 
      Table.AddColumn( MonthOfYearNumber, "DayOfMonthNumber", each
        Date.Day( [Date] ),
        Int64.Type
      ),
    
    YearMonthDateNumber = 
      Table.AddColumn( DayOfMonthNumber, "YearMonthDateNumber", each 
        [Year] * 10000 + [MonthOfYearNumber] * 100 + [DayOfMonthNumber],
        Int64.Type
      ),
    
    YearMonthNumber = 
      Table.AddColumn( YearMonthDateNumber, "YearMonthNumber", each 
        [Year] * 100 + [MonthOfYearNumber] * 1,
        Int64.Type
      ),
    
    MonthName = 
      Table.AddColumn( YearMonthNumber, "MonthName", each 
        Date.ToText( [Date], "MMMM", CultureParameter ),
        type text
      ),
    
    MonthAndYear = 
      Table.AddColumn( MonthName, "MonthAndYear", each
        ( try ( Text.Range( [MonthName], 0, 3 ) ) otherwise [MonthName] ) & " " & Number.ToText( [Year] ),
        type text
      ),
    
    QuarterAndYear = 
      Table.AddColumn( MonthAndYear, "QuarterAndYear", each 
        "Q" & Number.ToText( [QuarterOfYearNumber] ) & " " & Number.ToText( [Year] ),
        type text
      ),
    
    DayOfWeekNumber = 
      Table.AddColumn(QuarterAndYear, "DayOfWeekNumber", each 
        Date.DayOfWeek( [Date], Day.Monday ) + 1, 
        Int64.Type
      ),
    
    DayOfWeekName = 
      Table.AddColumn(DayOfWeekNumber, "DayOfWeekName", each 
        Date.ToText( [Date], "dddd", CultureParameter ),
        type text
      ),
    WeekStart = Table.AddColumn(DayOfWeekName, "WeekStart", each
        Date.StartOfWeek( [Date], Day.Monday ),
        type date
      ),
    
    WeekEnd = 
      Table.AddColumn(WeekStart, "WeekEnd", each 
        Date.EndOfWeek( [Date], Day.Monday ),
        type date
      ),
    MonthStartDate = 
      Table.AddColumn(WeekEnd, "MonthStartDate", each 
        Date.StartOfMonth( [Date] ),
        type date
      ),
    
    WeekOfYearNumber = 
      Table.AddColumn(MonthStartDate, "WeekOfYearNumber", each 
        Date.WeekOfYear( [Date], Day.Monday ),
        Int64.Type
      ),
    
    DayOfYearNumber = 
      Table.AddColumn(WeekOfYearNumber, "DayOfYearNumber", each 
        Date.DayOfYear( [Date] ),
        Int64.Type
        ),
    
    listBufferMonths = 
      List.Buffer(
        List.Distinct(
          DayOfYearNumber[MonthStartDate]
        )
        ),
    
    MonthCalendarSeqNumber = 
      Table.AddColumn( DayOfYearNumber, "MonthCalendarSeqNumber", 
        each List.PositionOf( listBufferMonths, [MonthStartDate]) + 1,
        Int64.Type
      ),
    
    MonthCalendarSeqNumberReverse = 
      Table.AddColumn( MonthCalendarSeqNumber, "MonthCalendarSeqNumberReverse", 
        each [MonthCalendarSeqNumber] - 1 - List.PositionOf(listBufferMonths, Date.StartOfMonth(ReverseIndex0Date)) ,
        Int64.Type
      ),
    
    listBufferWeeks =
      List.Buffer( 
        List.Distinct( MonthCalendarSeqNumberReverse[WeekStart] )
      ),
    
    DaySeqNumber =
      Table.AddIndexColumn(
        MonthCalendarSeqNumberReverse,
        "DaySeqNumber",
        0,
        1
      ),
    DaySeqNumberChangedType = Table.TransformColumnTypes(DaySeqNumber,{{"DaySeqNumber", Int64.Type}}),
    DaySeqNumberReverse = 
      Table.AddColumn(
        DaySeqNumberChangedType, 
        "DaySeqNumberReverse", 
        each Number.From([Date]-ReverseIndex0Date), 
        Int64.Type),
        
    SevenDaysIntervalReverse = 
      Table.AddColumn(
        DaySeqNumberReverse, 
        "SevenDaysIntervalReverse", 
        each Number.RoundDown([DaySeqNumberReverse] / 7), 
        Int64.Type),
   
    WeekCalendarSeqNumber = 
      Table.AddColumn( 
        SevenDaysIntervalReverse, 
        "WeekCalendarSeqNumber", 
        each List.PositionOf( listBufferWeeks, [WeekStart] ) ,
        Int64.Type
      ),
    
    WeekCalendarSeqNumberReverse = Table.AddColumn( 
      WeekCalendarSeqNumber, 
        "WeekCalendarSeqNumberReverse", 
        each [WeekCalendarSeqNumber] - List.PositionOf( listBufferWeeks, Date.StartOfWeek(ReverseIndex0Date, Day.Monday )),
        Int64.Type
      ),
    WeekCurrentAnotherWeek = Table.AddColumn(
      WeekCalendarSeqNumberReverse, 
      "ТекущаяПрошлаяНеделя", 
      each if [WeekCalendarSeqNumberReverse] = 0 then "Текущая неделя" 
        else if [WeekCalendarSeqNumberReverse] = -1 then "Прошлая неделя" 
        else if [WeekCalendarSeqNumberReverse] = -2 then "Позапрошлая неделя" 
        else if [WeekCalendarSeqNumberReverse] > 0 then "В будущем" 
        else "Больше 2-ух недель назад"),
    
    IsHolidayInRussia = 
      Table.AddColumn( 
        WeekCurrentAnotherWeek, 
        "IsHolidayInRussia", 
        each 
          if List.Count( CheckIfThereIsHolidayList ) = 0 
          then null
          else 
            if List.Contains( CheckIfThereIsHolidayList, [Date]) 
            then true 
            else false,
      type logical
      ),

    IsShortDayInRussia = 
      Table.AddColumn( IsHolidayInRussia, "IsShortDayInRussia", each
        if List.Count( CheckIfThereIsShortdayList ) = 0 
        then null
        else 
          if List.Contains( CheckIfThereIsShortdayList, [Date]) 
          then true 
          else false,
    type logical
      ),
    #"Reordered Columns" = Table.ReorderColumns(IsShortDayInRussia,
      {
        "Date", 
        "DayOfMonthNumber", 
        "DaySeqNumber", 
        "DaySeqNumberReverse", 
        "DayOfWeekName", 
        "DayOfWeekNumber", 
        "DayOfYearNumber", 
        "SevenDaysIntervalReverse", 
        "WeekCalendarSeqNumber", 
        "WeekCalendarSeqNumberReverse", 
        "WeekStart", 
        "WeekEnd", 
        "WeekOfYearNumber", 
        "MonthAndYear", 
        "MonthName", 
        "MonthCalendarSeqNumber", 
        "MonthCalendarSeqNumberReverse", 
        "MonthOfYearNumber", 
        "MonthStartDate", 
        "QuarterAndYear", 
        "QuarterOfYearNumber", 
        "Year", 
        "YearMonthDateNumber", 
        "YearMonthNumber", 
        "IsHolidayInRussia", 
        "IsShortDayInRussia"
      }
    )
in
    #"Reordered Columns"
in
    Source