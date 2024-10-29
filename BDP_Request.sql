

/*

exec QORT_ARM_SUPPORT.dbo.BDP_Request @IP = '192.168.13.59',

@IsinCodes = 'US6698881090 EQUITY',
    @Field1 = 'PX_LAST'
	,@Field2 = 'PX_CLOSE_1D'
	,
    @Field3 = 'PX_DISC_BID',
    @Field4 = 'MATURITY'

*/

CREATE PROCEDURE [dbo].[BDP_Request]
	@IP varchar(16),
    @IsinCodes NVARCHAR(MAX), -- строка с ISIN-кодом
	@Field1 NVARCHAR(MAX),  
	@Field2 NVARCHAR(MAX),
	@Field3 NVARCHAR(MAX),
	@Field4 NVARCHAR(MAX)
AS
BEGIN
    -- Создание временных таблиц
    IF O
BJECT_ID('tempdb..#Curloutput_TEST') IS NOT NULL DROP TABLE #Curloutput_TEST;
    IF OBJECT_ID('tempdb..##ParsedResultsBDP') IS NOT NULL DROP TABLE ##ParsedResultsBDP;
	   DECLARE @TotalRows INT;
    DECLARE @CurrentRow INT = 1;
    DECLARE @IsinCode NVAR
CHAR(MAX);
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @FieldsForQuery NVARCHAR(MAX);
	DECLARE @Fields NVARCHAR(MAX);
    -- Создание временных таблиц для обработки д
анных
    CREATE TABLE #Curloutput_TEST (output NVARCHAR(MAX));
    CREATE TABLE ##ParsedResultsBDP (
      
        Code NVARCHAR(50),
        Field1 NVARCHAR(MAX),
        Field2 NVARCHAR(MAX),
        Field3 NVARCHAR(MAX),
        Field4 NVARCHAR(MAX),

      --  Field5 NVARCHAR(MAX),
        -- Добавьте больше столбцов, если потребуется
        Found BIT,
        ErrorMessage NVARCHAR(MAX) -- Для хранения сообщений об ошибках
    );
/*
    -- Разделение входных параметров на таблицы
    DECLARE @IsinTa
ble TABLE (IsinCode NVARCHAR(50));
    DECLARE @FieldTable TABLE (FieldName NVARCHAR(255));

    INSERT INTO @IsinTable (IsinCode)
    SELECT TRIM(value)
    FROM STRING_SPLIT(@IsinCodes, ',');

    INSERT INTO @FieldTable (FieldName)
    SELECT TRIM(valu
e)
    FROM STRING_SPLIT(@Fields, ',');

    DECLARE @TotalRows INT;
    DECLARE @CurrentRow INT = 1;
    DECLARE @IsinCode NVARCHAR(MAX);
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(M
AX);
    DECLARE @FieldsForQuery NVARCHAR(MAX);

    -- Формирование строки с полями для запроса
    SELECT @FieldsForQuery = STRING_AGG('\"' + FieldName + '\"', ',')
    FROM @FieldTable;

    -- Получаем общее количество строк
    SELECT @TotalRows = CO
UNT(*) FROM @IsinTable;

    -- Цикл для обработки данных по одному ISIN-коду за раз
    WHILE @CurrentRow <= @TotalRows
    BEGIN
        -- Получаем один ISIN-код для обработки
        SELECT @IsinCode = IsinCode
        FROM (
            SELECT ROW_NU
MBER() OVER (ORDER BY (SELECT NULL)) AS RowNum, IsinCode
            FROM @IsinTable
        ) AS OrderedData
        WHERE RowNum = @CurrentRow;
		*/
        -- Подготовка команды curl
        SET @IsinCodes = '\"' + @IsinCodes + '\",\"' + LEFT(@IsinCode
s,12)+ '@BGN CORP\",\"' + LEFT(@IsinCodes,12) + '@BVAL CORP\",\"' + LEFT(@IsinCodes,12) +'@BMRK CORP\"';
		SET @Fields = '\"' + @Field1 + '\",\"' + @Field2 + '\",\"' + @Field3 + '\",\"' + @Field4 +'\"';
        SET @CurlCommand = 'curl -X POST http://' + 
@IP + ':5001/get_data -H "Content-Type: application/json" -d "{\"isin_codes\": [' + @IsinCodes + '], \"fields\": [' + @Fields + ']}"';
		print @CurlCommand --return
        -- Выполнение команды curl и обработка результатов
        BEGIN TRY
            -
- Выполнение команды curl
            INSERT INTO #Curloutput_TEST (output)
            EXEC xp_cmdshell @CurlCommand;

            -- Обработка результатов curl
            SELECT @JsonResult = STRING_AGG(CAST(output AS NVARCHAR(MAX)), '')
            FR
OM #Curloutput_TEST
            WHERE output IS NOT NULL;

            -- Очистка результата от всего перед первым символом '['
            SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));

            -- Проверка п
равильности JSON и добавление данных в результирующую таблицу
            IF ISJSON(@JsonResult) = 1
            BEGIN
                PRINT 'JSON is valid';

                -- Вставка распарсенных данных в таблицу #ParsedResults
     /*           INSERT
 INTO #ParsedResults (Code, Field1, Field2, Field3, Field4, Found, ErrorMessage)
                SELECT 
                 
                    JSON_VALUE(jsonData.value, '$.CODE') AS Code,
                    JSON_VALUE(jsonData.value, '$.PX_LAST') AS Fie
ld1,
                    JSON_VALUE(jsonData.value, '$.Field2') AS Field2,
                    JSON_VALUE(jsonData.value, '$.Field3') AS Field3,
                    JSON_VALUE(jsonData.value, '$.Field4') AS Field4,
                    JSON_VALUE(jsonData.
value, '$.FOUND') AS Found,
                    NULL AS ErrorMessage
                FROM OPENJSON(@JsonResult) AS jsonData;
				*/
				
DECLARE @SQL NVARCHAR(MAX);
set @Field1  = '$.'+@Field1;
set @Field2  = '$.'+@Field2;
set @Field3  = '$.'+@Field3;
set
 @Field4  = '$.'+@Field4;
--print @Field1  return
SET @SQL = '
    INSERT INTO ##ParsedResultsBDP (Code, Field1, Field2, Field3, Field4, Found, ErrorMessage)
    SELECT 
        JSON_VALUE(jsonData.value, ''$.CODE'') AS Code,
        JSON_VALUE(jsonData.v
alue, ''' + @Field1 + ''') AS Field1,
        JSON_VALUE(jsonData.value, ''' + @Field2 + ''') AS Field2,
        JSON_VALUE(jsonData.value, ''' + @Field3 + ''') AS Field3,
        JSON_VALUE(jsonData.value, ''' + @Field4 + ''') AS Field4,
        JSON_VAL
UE(jsonData.value, ''$.FOUND'') AS Found,
        NULL AS ErrorMessage
    FROM OPENJSON(@JsonResult) AS jsonData
';

EXEC sp_executesql @SQL, N'@JsonResult NVARCHAR(MAX)', @JsonResult = @JsonResult;



            END
            ELSE
            BEGIN
 
               -- Если JSON некорректен, добавляем запись с сообщением об ошибке
                INSERT INTO ##ParsedResultsBDP (Code, ErrorMessage)
                VALUES (@IsinCode, 'Некорректный JSON: ' + LEFT(@JsonResult, 1000));
            END;

   
     END TRY
        BEGIN CATCH
            -- Обработка ошибок
            SET @ErrorMessage = ERROR_MESSAGE();
            INSERT INTO ##ParsedResultsBDP (Code, ErrorMessage)
            VALUES (@IsinCode, @ErrorMessage);
        END CATCH;

        --
 Обновляем текущий ряд для следующей итерации
      --  SET @CurrentRow = @CurrentRow + 1;

        -- Очищаем временную таблицу перед следующим запросом
        DELETE FROM #Curloutput_TEST;
    --END;

    -- Выводим результаты парсинга
    SELECT * FRO
M ##ParsedResultsBDP;

    -- Очистка временной таблицы
    --DROP TABLE #ParsedResults;
END;
/*
-- Вызов процедуры и сохранение результата в таблицу

CREATE TABLE #IntermediateResult (
    Code NVARCHAR(50),
    Field1 NVARCHAR(MAX),
    Field2 NVARCHAR(MAX),
    Field3 NVARCHAR(MAX),
    Field4 NVARCHAR(MAX),
    Found BIT,
    ErrorMessage NVARCHAR(MAX)
);

-- Выполнение процедуры и вставка результат
ов во временную таблицу
DECLARE @SQL NVARCHAR(MAX);



SET @SQL = N'

    INSERT INTO #IntermediateResult (Code, Field1, Field2, Field3, Field4, Found, ErrorMessage)

    EXEC dbo.BDP_Request @Code, @Field1, @Field2, @Field3, @Field4;



';



-- Выполнение динамического SQL

EXEC sp_executesql @SQL,

                   N'@Code NVARCHAR(50), @Field1 NVARCHAR(MAX), @Field2 NVARCHAR(MAX), @Field3 NVARCHAR(MAX), @Field4 NVARCHAR(MAX)',

                   @Code = 'XS1936100483 CORP',

                   @Field1 = 'PX_LAST',

                   @Field2 = 'NAME',

                   @Field3 = 'CPN',

                   @Field4 = 'MATURITY';





-- Использование результата

SELECT * FROM #IntermediateResult 

DROP TABLE #IntermediateResult;



*/
