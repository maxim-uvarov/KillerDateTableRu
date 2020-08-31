// KillerDateTable
let
    Source = (StartDateParam as date, EndDateParam as date, IndexReverse0Date as date, CultureParameter as any, RuHolidaysSwitchParameter as logical) => let

// killerDateTableRu v1.9 (https://github.com/power-bi/KillerDateTableRu)

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

    getProductionCalendar = ( ) as nullable table =>
      let
        #"Повышенные заголовки" = 
            Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("7ZrtcqwgDIbvxZ/IOIQPgWvp9P5v4wABhR1AcDvddk9/2Vk1Yp4kb4j9+FjAWrvQBSingkq6E6qppcAo7BQ05YJySQWjAtxVuzsJgoKknFHu7nEXmPi7qZ7xNr0x8MbAeGNcOXske6aJD1T+mZyHZ1p3jbtEUbcKIBR4tA42PMBdp9vWIRgPS5LerF+PM+vO+1eVVIU7uL/D23MX7O53v5jum9ffMDMncovuPv+SXIXVgPR/M+YPYJjeuP+DM7mZ5ZN++FPsEUPwS8sp+LjCG34lmvhlVt7OW24Z9OfCCxJ/QZ8iz119Ybe10IanL6npC24xUCr4uArWIXjCWoUUGDJgiQDkvhgP5/g7un4qGrNE8L5C/3cdVnvFW9He49ZK8yMyay44DPKqzYc8gHYe8Mwjeih+OIm+CAvxZwOL8TJmHiqSiiiOkK/4LZKYdN90terl0FklGvGQV84i7GJpwqRQmBTB7xoP4A4Rhzj8oggSGY0mGU9kMEaLxKNCZDQaritEQo16cFrpeunULdrouZzHaXeKh8z8Uk/GZkiJwyd/gn0p2KoQbJEKFTsLlVryirEn+INhHotWdEzMLTOtlzw9tu84Meu7GfXraYkg0Tu1F+uEA5cmYNAhGUxgog3fQrKB0ZtMGPY6hpFAKoXjif7pTP2f2T2dFGbzaJyDrnAYiqKSwp1WimQorhspktF4XSOlJlKJZDhs1siaHXHsG0Iydjt0wtRwTDdTX6HfffWuaPdwA/R18k1yaRsl+aDbcXMhULcF6rZIPGyFB65/ULmPM4PFLYvPkkHLX43u5Gbs36j5QEOdmmqFE4MyLzTmhY55YdmRF8CaHEbiCF/RZcTTc4/f0EQdsqEHY2KaBjRp/PVQ39dDAa9jmOihok8O9R4ubYV4H092Vt9XvPWVeIOo8JgR7+XWGEQnlWlMQequ+wGDEDnXEB9VSqPjAw4dbtCabxIhWZcnEYes4Rgeg6Sa/5I5yAt6qTut1BSO9sZ7fA5yp5vq0HjPnqoAgvKhRQRi2AmksQW/jieSN1Xol5lyV4q4eFsZRw4WOUjksCcO4uRQ3YJPDkLQKc/MQt53FFLkA+7ztEoc+Mmhuvd+YhQyU9yKfmrku9Lv7qhGNaO9/f6OD0w6/8Z0dlb/d1vFa1vx8bZqxReIKr7elPFTxNc3VfHKp2+NB3CHiKK9Dx+aipBcweO/Etwai6zxuevQYGR97WRkqjOeHY3wxp78xlzE30zutFTrYEe1/r6WqqBgkYJNFPhJoboTn5+LPNtP/eD/zEkM1jsdVYHBIAaTMMApFdUd+HxH9SfdfekutQJ3GngAm4aFvLb9npDt5WEa0in1zXHI3DDkpZMQcver0sCXvs9/", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Год/Месяц" = _t, Январь = _t, Февраль = _t, Март = _t, Апрель = _t, Май = _t, Июнь = _t, Июль = _t, Август = _t, Сентябрь = _t, Октябрь = _t, Ноябрь = _t, Декабрь = _t, #"Всего рабочих дней" = _t, #"Всего праздничных и выходных дней" = _t, #"Количество рабочих часов при 40-часовой рабочей неделе" = _t, #"Количество рабочих часов при 36-часовой рабочей неделе" = _t, #"Количество рабочих часов при 24-часовой рабочей неделе" = _t]),
          
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

ProductionCalendar = Table.Buffer( 
       getProductionCalendar( ) 
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
    CheckIfRuCalendarNeeded = if IsRuHolidaysParameter = true then IsShortDayInRussia else WeekCurrentAnotherWeek,
    #"Reordered Columns" = Table.ReorderColumns(CheckIfRuCalendarNeeded,
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