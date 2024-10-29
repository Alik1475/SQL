

CREATE PROCEDURE [dbo].[GetFlaskData]
(
    @IsinCodes NVARCHAR(MAX), -- Строка с ISIN-кодами, разделенными запятыми, например: 'US78462F1030,US9128285M81'
    @StartDate NVARCHAR(8),   -- Дата начала в формате YYYYMMDD
    @EndDate NVARCHAR(8)-- Дата око
нчания в формате YYYYMMDD
--	,  @Fields NVARCHAR(MAX) = NULL -- Строка с полями, разделенными запятыми, например: 'PX_LAST,VOLUME'
)
AS
BEGIN
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHA
R(MAX);
	DECLARE @Fields NVARCHAR(MAX) = 'PX_LAST\",\"CNCY';
	IF OBJECT_ID('tempdb..##ParsedResults', 'U') IS NOT NULL DROP TABLE ##ParsedResults
    CREATE TABLE ##ParsedResults (
        Code NVARCHAR(50),
        Px_Last FLOAT,
        Volume FLOAT,
  
      ErrorMessage NVARCHAR(MAX)
    );


    -- Подготовка команды curl
    SET @CurlCommand = 'curl -X POST http://192.168.13.59:5002/get_data_bdh -H "Content-Type: application/json" -d "{\"securities\": [\"' + @IsinCodes + '\"], \"fields\": [\"' + @Fie
lds + '\"], \"start_date\": \"' + @StartDate + '\", \"end_date\": \"' + @EndDate + '\"}"';
    PRINT @CurlCommand --return

    BEGIN TRY
        -- Выполнение команды curl и сохранение результата
        CREATE TABLE #Curloutput_TEST (output NVARCHAR(MAX
));
        INSERT INTO #Curloutput_TEST (output)
        EXEC xp_cmdshell @CurlCommand;

        -- Обработка результатов curl
        SELECT @JsonResult = STRING_AGG(CAST(output AS NVARCHAR(MAX)), '')
        FROM #Curloutput_TEST
        WHERE output I
S NOT NULL;

        -- Очистка результата от всего перед первым символом '['
        SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));

        -- Проверка правильности JSON
        IF ISJSON(@JsonResult) = 1
      
  BEGIN
            -- Вставка распарсенных данных в таблицу #ParsedResults
            INSERT INTO ##ParsedResults (
                Code, Px_Last, Volume, ErrorMessage)
            SELECT 
                ISNULL (JSON_VALUE(jsonData.value, '$.CODE'), ''
) AS Code,
                ISNULL (JSON_VALUE(jsonData.value, '$.PX_LAST'),'') AS Px_Last,
                ISNULL (JSON_VALUE(jsonData.value, '$.CNCY'), '') AS Volume,
                '' AS ErrorMessage
            FROM OPENJSON(@JsonResult) AS jsonData;

        END
        ELSE
        BEGIN
            -- Если JSON некорректен, добавляем запись с сообщением об ошибке
            INSERT INTO ##ParsedResults(Code, ErrorMessage)
            VALUES (@IsinCodes, 'Некорректный JSON');
        END;
        SEL
ECT * FROM ##ParsedResults;
    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        SET @ErrorMessage = ERROR_MESSAGE();
        INSERT INTO ##ParsedResults (Code, ErrorMessage)
        VALUES (@IsinCodes, @ErrorMessage);
    END CATCH;
END;
