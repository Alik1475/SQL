/* exec QORT_ARM_SUPPORT..BDH_FlaskReguest_Maxim @ID = '192.168.13.80',

    @IsinCodes = 'PPLT US equity', -- Строка с ISIN-кодами, разделенными запятыми, например: 'US78462F1030,US9128285M81'
    @StartDateD = '2025-05-01',   -- Дата начала в формате YYYYMMDD
    @EndDateD = '2025-05-02' -- Дата окончания в формате YYYYMMDD

--	,  @Fields NVARCHAR(MAX) = NULL -- Строка с полями, разделенными зап*/

CREATE PROCEDURE [dbo].[BDH_FlaskReguest_Maxim]
(
	@ID VARCHAR(16),
    @IsinCodes NVARCHAR(MAX), -- Строка с ISIN-кодами, разделенными запятыми, например: 'US78462F1030,US9128285M81'
    @StartDateD date,   -- Дата начала в формате YYYYMMDD
    @EndDateD
 date-- Дата окончания в формате YYYYMMDD
--	,  @Fields NVARCHAR(MAX) = NULL -- Строка с полями, разделенными запятыми, например: 'PX_LAST,VOLUME'
)
AS
BEGIN
    DECLARE @StartDate NVARCHAR(8)   -- Дата начала в формате YYYYMMDD
    DECLARE @EndDate NVARC
HAR(8)-- Дата окончания в формате YYYYMMDD
	SET @StartDate = CONVERT(NVARCHAR(8), @StartDateD, 112);

	SET @EndDate = CONVERT(NVARCHAR(8), @EndDateD, 112);
	    
    
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(MAX);
	DECLARE @Fields NVARCHAR(MAX) = '\"PX_LAST\",\"DIRTY_PRICE\"';
	IF O
BJECT_ID('tempdb..##ParsedResults', 'U') IS NOT NULL DROP TABLE ##ParsedResults
CREATE TABLE ##ParsedResults (

    Code NVARCHAR(50),

    Px_Last FLOAT,

    Date BIGINT,

	--CRNCY NVARCHAR(50),

    DateText NVARCHAR(50), -- добавлено для читаемой даты

    ErrorMessage NVARCHAR(MAX)

);


    -- Подготовка команды curl
    SET @CurlCommand = 'curl -X POST http://' + @ID + ':5002/get_data_bdh -H "Content-Type: application/json" -d "{\"securities\": [\"' + @IsinCodes + '\"], \"fields\": [\"' + @Fields + '\"], \"start_date\": \"' + @Star
tDate + '\", \"end_date\": \"' + @EndDate + '\"}"';
    PRINT @CurlCommand -- return

    BEGIN TRY
        -- Выполнение команды curl и сохранение результата
        CREATE TABLE #Curloutput_TEST (output NVARCHAR(MAX));
        INSERT INTO #Curloutput_TE
ST (output)
        EXEC xp_cmdshell @CurlCommand;

        -- Обработка результатов curl
        SELECT @JsonResult = STRING_AGG(CAST(output AS NVARCHAR(MAX)), '')
        FROM #Curloutput_TEST
        WHERE output IS NOT NULL;

        -- Очистка резуль
тата от всего перед первым символом '['
        SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));

        -- Проверка правильности JSON
        IF ISJSON(@JsonResult) = 1
        BEGIN
            -- Вставка распарс
енных данных в таблицу #ParsedResults
            INSERT INTO ##ParsedResults (
                Code, Px_Last, Date, /*CRNCY,*/ ErrorMessage)
            SELECT 
                ISNULL (JSON_VALUE(jsonData.value, '$.CODE'), @IsinCodes) AS Code,
          
      ISNULL (JSON_VALUE(jsonData.value, '$.PX_LAST'),'') AS Px_Last,
                ISNULL (JSON_VALUE(jsonData.value, '$.date'), '') AS Date,
			--	ISNULL (JSON_VALUE(jsonData.value, '$.Crncy'), '') AS CRNCY,
                '' AS ErrorMessage
        
    FROM OPENJSON(@JsonResult) AS jsonData;
        END
        ELSE
        BEGIN
            -- Если JSON некорректен, добавляем запись с сообщением об ошибке
            INSERT INTO ##ParsedResults(Code, ErrorMessage)
            VALUES (@IsinCodes, 'Н
екорректный JSON');
        END;
		--SELECT * FROM ##ParsedResults;

UPDATE ##ParsedResults

SET 

    Code = @IsinCodes;



UPDATE ##ParsedResults

SET DateText = FORMAT(

    DATEADD(SECOND, TRY_CAST(Date AS BIGINT) / 1000, '1970-01-01'),

    'dd MMM yy', 'en-US'

)

WHERE ISNUMERIC(Date) = 1;

        


	
        SELECT * FROM ##ParsedResults;

    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        SET @ErrorMessage = ERROR_MESSAGE();
        INSERT INTO ##ParsedResults (Code, ErrorMessage)
        VALUES (@IsinCodes, @ErrorMessage);
    END CA
TCH;
END;
