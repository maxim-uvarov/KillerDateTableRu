// KillerDateTableRuForPowerBIService
let
    Source = (StartDateParam as date, EndDateParam as date, IndexReverse0Date as date, CultureParameter as any) => let

// killerDateTableRu v2.1 (https://github.com/power-bi/KillerDateTableRu)

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
//  IsRuHolidaysParameter  = RuHolidaysSwitchParameter,

    MONTHS_ORDERED_BY_DEFAULT = {
        "Январь", "Февраль", "Март",
        "Апрель", "Май", "Июнь", 
        "Июль", "Август", "Сентябрь", 
        "Октябрь", "Ноябрь", "Декабрь"
      },

    // Данные по рабочим/выходным дням до 2013 года взяты с сайта https://data.gov.ru/opendata/7708660670-proizvcalendar?page=1
    // С 2013 года с сайта http://xmlcalendar.ru/ 
    // Для статического календаря таблицу можно взять отсюда

    #"Статический календарь" = 
  Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("7VpRbusgELxLPhGy2AUMnKXq/a9RYDGGCDAkVdNG/UpfsBeY2d0ZyPv4uIFz7sZvwJFLrvjOuOGOg+CwczAcJUfFpeAS/FO7HwTJQXEUHP07/gGbvrfNkRAzBIMQDGwIhtrHY8WcNk2ow5yIcU7nn/GPaO5XAYwDpujg4gT+OdOPDjF4XJIKYcN6fFg/HraquI5vYHgjxPMP7P77sJjhzts7LMLJMqJ/L2wSdVwNqPC3EOEDrDAbhj9QqM3ePvlHGBL3NERceqDQdBUaYSWGhWU2dhci9wKGsbhBFh4Ys4gl1BdxewvtIH3JmrngLSVKgz7UMTpEJJzTxIIgDsTBAJRYzKdz+p6gX8rGohACVoT/ELDWFh/K9hFvvTLPmdmCIAfEZsy7OoB+HWCBiJnKH2QJi7iQMBq5mG9j9q4j6URFTvkGbomJRfiWu9Wohs4u0cmHsnNWaZdaExWFpqKIuBv6AP+R6JAZF82IkdlsUmmgIGO2SdwrRMFGB7pKJPQsgstKNyqnYdMm5Eo+zrhLfKgCl3YxdlNKZkz+BftSsHUl2PJoVOJsVPpWdoz9IH8yzVPTSsCk2rLLeonHtGPg5Cp2K+o30hLJEjqtjQ3SAZWNNJhYDDZyYixusdjAmk0dNOxtGmYSqRaOJ/zTWfq/0z2dLKzW0TwPpsHDVBbVLDxipVhBxbWRYgUbrzNSeqGUWEGHK4ys3YmOfSOSrNuyTtgWHctm6jv0e6zeDe2eNkDfJ9+slLZZJu90Ox0uJOm2JN2WBx+uwQetf1K588hkcyvys+agh1fHnTyY+w/0fOCxTy1Z4YODui4M1YVJdeFErgsQXR5m8oi26Cvi6XuPv2CismyYyZxYZgO6bPx7qJ/zUIBtGhY8VMIkq/d0a6vEO8/so76veJsr8QbZ4GNFvG8PXYOYiZuQNny/4DJErZni3KkMgR8pMfEFY3BTRJTztZIoUS1Kpq9CDkxfchfyAj/1jJ2apqR/AJ+/D3nEVQ0YeU9vVRFCMmJkIsSKk5DOUfw6p1hprgiXlbZXi7l8WzknHhzxoIiH/eBBnjw0j+KLFyIEyjN3Iu97JVLVA533jD54wJOH5hn8iSuRleZW+aqZ35f+trOa1YzWMfzfWb3SWWHrRD7vrGj9XQ3PnHSNQuGUaItp1vLAnxpiIrKsq2bIBRegMm/A/4AVoPohag0dZ7S3AnH9Qtl8gsE+5OtW4Llfq+auFX7DdUu94mmzeLRA+u8M9OshWQBD/wJPVKKlc9D/0csWWdDxphZtZA0+vwA=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Год/Месяц" = _t, Январь = _t, Февраль = _t, Март = _t, Апрель = _t, Май = _t, Июнь = _t, Июль = _t, Август = _t, Сентябрь = _t, Октябрь = _t, Ноябрь = _t, Декабрь = _t, #"Всего рабочих дней" = _t, #"Всего праздничных и выходных дней" = _t, #"Количество рабочих часов при 40-часовой рабочей неделе" = _t, #"Количество рабочих часов при 36-часовой рабочей неделе" = _t, #"Количество рабочих часов при 24-часовой рабочей неделе" = _t]),

#"Переименовали поле в год" = 
  Table.RenameColumns( #"Статический календарь",
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

calendar_from_site = 
  Table.AddColumn( #"Уточнли тип полей календаря", "Дата", each
    #date( [Год], [НомерМесяца], [День] )
  ),

ProductionCalendar = Table.Buffer( calendar_from_site ) ,

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
      
    ReverseIndex0Date = if IndexReverse0Date = null then EndDateParam else IndexReverse0Date,
            
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
    // CheckIfRuCalendarNeeded = if IsRuHolidaysParameter = true then IsShortDayInRussia else WeekCurrentAnotherWeek,
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
        "YearMonthNumber"
      }
    )
in
    #"Reordered Columns"
in
    Source