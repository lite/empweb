# 2012.08.08 13:38:59

    Добавлена проверка и заиена недопустимых символов в xslt_convert.
    Добавлены файлы, todo для перевода модуля xml на xmerl.

# 2012.05.20 21:14:12

    * Оcуществлен переход на чистые Cи,
        Хеш-таблицы из STL были заменены лучевым поиском.
    * Исправлена ошибка с порядком аргументов при вызове адаптера.

# 2012.05.20 15:42:46

    * Создан файл erlxslt_port.c.
        Туда были вынесены наиболее общие функции работы с портом.
    * Создан файл erlxslt_transform.c.
        Вынесены низкоуровневые действия с xml и xslt.
    * Переформирован основной файл драйвера
        --- erlxslt_adapter.c

# 2012.03.15 15:48:58

    * Создан заголовочный файл.
    * Изменен метод создания выходного файла
        xsltSaveResultToString(&resBuff, &resSize, result, xsl);
            vs
        xmlDocDumpMemory(result, &resBuff, &resSize);
        Первый вариант правильнее, т.к. он учитывает
            параментры вывода xsl:output

# 2012.02.03 20:39:18

    * Изменены имена модулей. Добавлен перффикс `xslt_` к модулям, у которых
        его не было, кроме `xml`.
        Это было сделано для совместимости с одноименными модулями
        в приложениях основанном на erlxslt
    * Добавлена опция DEBUG в `libxslt_adapter.c`.
        Она отключает кеширование шаблонов, если ведется разработка.
        Постоянно включенное кеширование не особо удобно.
        Режим отладки (DEBUG) включается или отключается в `rebar.config`
    * Изменены названия некоторых методов и аргуметов и переменных
        в `libxslt_adapter.c`, убрано глобальное определение карты.
        Последнее, возможно сделано зря, так как удобно
        использовать несколько процессов работающих
        процессов `libxslt_adapter`. Это действие можно отменить определив
        в коде `USE_GLOBAL`.
