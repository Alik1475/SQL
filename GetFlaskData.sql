/* exec QORT_ARM_SUPPORT..GetFlaskData @ID = '192.168.13.80',

    @IsinCodes = 'USY77108AA93 CORP', -- Строка с ISIN-кодами, разделенными запятыми, например: 'US78462F1030,US9128285M81'
    @StartDate = 20250603,   -- Дата начала в формате YYYYMMDD
    @EndDate = 20250620 -- Дата окончания в формате YYYYMMDD
--	,  @
Fields NVARCHAR(MAX) = NULL -- Строка с полями, разделенными зап*/

CREATE PROCEDURE [dbo].[GetFlaskData]
(
	@ID VARCHAR(16),
    @IsinCodes NVARCHAR(MAX), -- Строка с ISIN-кодами, разделенными запятыми, например: 'US78462F1030,US9128285M81'
    @StartDate NVARCHAR(8),   -- Дата начала в формате YYYYMMDD
    @EndDate NVAR
CHAR(8)-- Дата окончания в формате YYYYMMDD
--	,  @Fields NVARCHAR(MAX) = NULL -- Строка с полями, разделенными запятыми, например: 'PX_LAST,VOLUME'
)
AS
BEGIN
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @Er
rorMessage NVARCHAR(MAX);
	DECLARE @Fields NVARCHAR(MAX) = 'PX_LAST\",\"INT_ACC_PER_BOND';
	IF OBJECT_ID('tempdb..##ParsedResults', 'U') IS NOT NULL DROP TABLE ##ParsedResults
    CREATE TABLE ##ParsedResults (
        Code NVARCHAR(50),
        Px_Last F
LOAT,
        PX_DISC_MID FLOAT,
        ErrorMessage NVARCHAR(MAX)
    );


    -- Подготовка команды curl
    SET @CurlCommand = 'curl -X POST http://' + @ID + ':5002/get_data_bdh -H "Content-Type: application/json" -d "{\"securities\": [\"' + @IsinCode
s + '\"], \"fields\": [\"' + @Fields + '\"], \"start_date\": \"' + @StartDate + '\", \"end_date\": \"' + @EndDate + '\"}"';
    PRINT @CurlCommand --return

    BEGIN TRY
        -- Выполнение команды curl и сохранение результата
        CREATE TABLE #Cur
loutput_TEST (output NVARCHAR(MAX));
        INSERT INTO #Curloutput_TEST (output)
        EXEC xp_cmdshell @CurlCommand;

        -- Обработка результатов curl
        SELECT @JsonResult = STRING_AGG(CAST(output AS NVARCHAR(MAX)), '')
        FROM #Curlo
utput_TEST
        WHERE output IS NOT NULL;

        -- Очистка результата от всего перед первым символом '['
        SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));

        -- Проверка правильности JSON
        
IF ISJSON(@JsonResult) = 1
        BEGIN
            -- Вставка распарсенных данных в таблицу #ParsedResults
            INSERT INTO ##ParsedResults (
                Code, Px_Last, PX_DISC_MID, ErrorMessage)
            SELECT 
                ISNULL (JS
ON_VALUE(jsonData.value, '$.CODE'), '') AS Code,
                ISNULL (JSON_VALUE(jsonData.value, '$.PX_LAST'),'') AS Px_Last,
                ISNULL (JSON_VALUE(jsonData.value, '$.INT_ACC_PER_BOND'), '') AS PX_DISC_MID,
                '' AS ErrorMessa
ge
            FROM OPENJSON(@JsonResult) AS jsonData;
        END
        ELSE
        BEGIN
            -- Если JSON некорректен, добавляем запись с сообщением об ошибке
            INSERT INTO ##ParsedResults(Code, ErrorMessage)
            VALUES (@Is
inCodes, 'Некорректный JSON');
        END;

		UPDATE ##ParsedResults
		SET PX_LAST = PX_DISC_MID
		WHERE PX_LAST < PX_DISC_MID;
        SELECT * FROM ##ParsedResults;

    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        SET @ErrorMessage = ER
ROR_MESSAGE();
        INSERT INTO ##ParsedResults (Code, ErrorMessage)
        VALUES (@IsinCodes, @ErrorMessage);
    END CATCH;
END;
