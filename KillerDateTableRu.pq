// KillerDateTable
let
    Source = (StartDateParam as date, EndDateParam as date, CultureParameter as any, RuHolidaysSwitchParameter as logical) => let

// killerDateTableRu v1.6 (https://github.com/power-bi/KillerDateTableRu)
// функция killerDateTableRu создает таблицу с датами. Дополняет ее различными полезными для Time Intelligence столбцами. 
// В случае, если четвертый аргумент принимает Дни 1, то функция добавляет столбец с выходными.
// Оригинальная идея philbritton https://gist.github.com/philbritton/9677152
// Дополнил русскими выходными и дополнительными столбцам Максим Уваров
// Причесал код, исправил ошибки Дмитрий Власов 
// Пример использования функции: killerDateTableRu(#date(2017, 2, 1), #date(2017, 2, 4), "RU-ru", 1)


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

    ProductionCalendar = Table.Buffer( try getProductionCalendar( PROD_СALENDAR_URL ) otherwise getProductionCalendar( PROD_СALENDAR_URL_Backup ) ) ,

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
    
    QuarterOfYear = 
      Table.AddColumn( Year, "QuarterOfYear", each 
        Date.QuarterOfYear( [Date] ),
        Int64.Type
      ),
    
    MonthOfYearNumber = 
      Table.AddColumn( QuarterOfYear, "MonthOfYearNumber", each
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
        "Q" & Number.ToText( [QuarterOfYear] ) & " " & Number.ToText( [Year] ),
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
    
    MonthSeqNumber = 
      Table.AddColumn( DayOfYearNumber, "MonthSeqNumber", each
        List.PositionOf( listBufferMonths, [MonthStartDate]) + 1,
        Int64.Type
      ),
    
    MonthSeqNumberReverse = 
      Table.AddColumn( MonthSeqNumber, "MonthSeqNumberReverse", each
        List.PositionOf(
          List.Reverse( listBufferMonths ),
          [MonthStartDate]
        ) + 1,
        Int64.Type
      ),
    
    listBufferWeeks =
      List.Buffer( 
        List.Distinct( MonthSeqNumberReverse[WeekStart] )
      ),
    
    DaySeqNumber =
      Table.AddIndexColumn(
        MonthSeqNumberReverse,
        "DaySeqNumber",
        1,
        1
      ),
    DaySeqNumberChangedType = Table.TransformColumnTypes(DaySeqNumber,{{"DaySeqNumber", Int64.Type}}),

    DaySeqNumberReverse =
      Table.AddIndexColumn( 
        DaySeqNumberChangedType,
        "DaySeqNumberReverse",
        -Table.RowCount(DaySeqNumberChangedType) + 1,
        1 
      ),
    DaySeqNumberReverseChangedType = Table.TransformColumnTypes(DaySeqNumberReverse,{{"DaySeqNumberReverse", Int64.Type}}),

    WeekSeqNumberReverse = 
      Table.AddColumn(
        DaySeqNumberReverseChangedType, 
        "WeekSeqNumberReverse", 
        each Number.IntegerDivide([DaySeqNumberReverse], 7), 
        Int64.Type),
   
    WeekCalendarSeqNumber = 
      Table.AddColumn( 
        WeekSeqNumberReverse, 
        "WeekCalendarSeqNumber", 
        each List.PositionOf( listBufferWeeks, [WeekStart] ) + 1,
        Int64.Type
      ),
    
    WeekCalendarSeqNumberReverse = Table.AddColumn( 
      WeekCalendarSeqNumber, 
        "WeekCalendarSeqNumberReverse", 
        each [WeekCalendarSeqNumber] - List.Count(listBufferWeeks),
        Int64.Type
      ),
    
    IsHolidayInRussia = 
      Table.AddColumn( 
        WeekCalendarSeqNumberReverse, 
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
        "WeekCalendarSeqNumber", 
        "WeekCalendarSeqNumberReverse", 
        "WeekStart", 
        "WeekEnd", 
        "WeekSeqNumberReverse", 
        "WeekOfYearNumber", 
        "MonthAndYear", 
        "MonthName", 
        "MonthSeqNumber", 
        "MonthSeqNumberReverse", 
        "MonthOfYearNumber", 
        "MonthStartDate", 
        "QuarterAndYear", 
        "QuarterOfYear", 
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