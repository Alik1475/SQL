
-- exec QORT_ARM_SUPPORT_TEST..TestFlaskRequest

CREATE PROCEDURE [dbo].[TestFlaskRequest]
AS
BEGIN
    -- Проверка и создание временных таблиц
    IF OBJECT_ID('tempdb..#Curloutput_TEST') IS NOT NULL DROP TABLE #Curloutput_TEST;
    IF OBJECT_ID('tempdb
..#Curloutput') IS NOT NULL DROP TABLE #Curloutput;
    IF OBJECT_ID('tempdb..#ParsedResults') IS NOT NULL DROP TABLE #ParsedResults;

	    DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках
        DECLARE @todayDate DATE = GETDATE()
        DE
CLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

    CREATE TABLE #Curloutput_TEST (output NVARCHAR(MAX));
   -- CREATE TABLE #Curloutput (output NVARCHAR(MAX));
    CREATE TABLE #ParsedResults (
		
        Code NVARCHAR(50),
        
Name NVARCHAR(255),
        Px_Last FLOAT,
        Cpn FLOAT,
        BB_COMPOSITE NVARCHAR(255),
        Industry_Sector NVARCHAR(255),
        YAS_BOND_YLD FLOAT,
        Amt_Outstanding FLOAT,
        DX129 NVARCHAR(50),
        Sectoral_Sanctioned_Sec
urity NVARCHAR(10),
        OFAC_Sanctioned_Security NVARCHAR(10),
        UK_Sanctioned_Security NVARCHAR(10),
        DX657 NVARCHAR(50),
        Long_Company_Name_Realtime NVARCHAR(255),
        Issuer_Bulk NVARCHAR(255),
        Security_Name NVARCHAR
(255),
        DS122 NVARCHAR(255),
        DS674 NVARCHAR(255),
        EQY_Prim_Security_Crncy NVARCHAR(10),
        Crncy NVARCHAR(10),
        Par_Amt FLOAT,
        Amt_Issued FLOAT,
        Issue_Dt NVARCHAR(255),
        Maturity NVARCHAR(255),
   
     DS497 NVARCHAR(255),
        Cpn_Freq NVARCHAR(50),
        Nxt_Cpn_Dt NVARCHAR(255),
        Int_Acc FLOAT,
        Found BIT,
        ErrorMessage NVARCHAR(MAX), -- Добавлено для хранения сообщений об ошибках
		date int
    );

    -- Заполнение та
блицы #Curloutput данными
    --INSERT INTO #Curloutput (output)
    EXEC QORT_ARM_SUPPORT_test..Draft;

	select code output
	into #Curloutput
	from ##CodeAssets
	select * from #Curloutput
	--return
    DECLARE @TotalRows INT;
    DECLARE @CurrentRow INT 
= 1;
    DECLARE @IsinCode NVARCHAR(MAX);
    DECLARE @CurlCommand NVARCHAR(4000);
    DECLARE @JsonResult NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(MAX);

    -- Получаем общее количество строк
    SELECT @TotalRows = COUNT(*) FROM #Curloutput;


    -- Цикл для обработки данных по одному ISIN-коду за раз
    WHILE @CurrentRow <= @TotalRows
    BEGIN
        -- Получаем один ISIN-код для обработки
        SELECT @IsinCode = output
        FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELE
CT NULL)) AS RowNum, output
            FROM #Curloutput
        ) AS OrderedData
        WHERE RowNum = @CurrentRow;

        -- Подготовка команды curl
        SET @IsinCode = '\"' + @IsinCode + '\"';
        SET @CurlCommand = 'curl -X POST http://192.
168.13.59:5001/get_data -H "Content-Type: application/json" -d "{\"isin_codes\": [' + @IsinCode + ']}"';
		print @CurlCommand
        BEGIN TRY
            -- Выполнение команды curl
            INSERT INTO #Curloutput_TEST (output)
            EXEC xp_cm
dshell @CurlCommand;

            -- Обработка результатов curl
            SELECT @JsonResult = STRING_AGG(CAST(output AS NVARCHAR(MAX)), '')
            FROM #Curloutput_TEST
            WHERE output IS NOT NULL;

            -- Очистка результата от вс
его перед первым символом '['
            SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));

            -- Проверка правильности JSON
            IF ISJSON(@JsonResult) = 1
            BEGIN
                PRINT 'J
SON is valid';

                -- Вставка распарсенных данных в таблицу #ParsedResults
                INSERT INTO #ParsedResults (
                     Code, Name, Px_Last, Cpn, BB_COMPOSITE, Industry_Sector, YAS_BOND_YLD, Amt_Outstanding, DX129, 
     
               Sectoral_Sanctioned_Security, OFAC_Sanctioned_Security, UK_Sanctioned_Security, DX657, 
                    Long_Company_Name_Realtime, Issuer_Bulk, Security_Name, DS122, DS674, EQY_Prim_Security_Crncy, 
                    Crncy, Par_Amt, 
Amt_Issued, Issue_Dt, Maturity, DS497, Cpn_Freq, Nxt_Cpn_Dt, Int_Acc, Found, ErrorMessage, date)
                SELECT 
					
                    JSON_VALUE(jsonData.value, '$.CODE') AS Code,
                    JSON_VALUE(jsonData.value, '$.NAME') AS Na
me,
                    JSON_VALUE(jsonData.value, '$.PX_LAST') AS Px_Last,
                    JSON_VALUE(jsonData.value, '$.CPN') AS Cpn,
                    JSON_VALUE(jsonData.value, '$.BB_COMPOSITE') AS BB_COMPOSITE,
                    JSON_VALUE(js
onData.value, '$.INDUSTRY_SECTOR') AS Industry_Sector,
                    JSON_VALUE(jsonData.value, '$.YAS_BOND_YLD') AS YAS_BOND_YLD,
                    JSON_VALUE(jsonData.value, '$.AMT_OUTSTANDING') AS Amt_Outstanding,
                    JSON_VALUE
(jsonData.value, '$.DX129') AS DX129,
                    JSON_VALUE(jsonData.value, '$.SECTORAL_SANCTIONED_SECURITY') AS Sectoral_Sanctioned_Security,
                    JSON_VALUE(jsonData.value, '$.OFAC_SANCTIONED_SECURITY') AS OFAC_Sanctioned_Securit
y,
                    JSON_VALUE(jsonData.value, '$.UK_SANCTIONED_SECURITY') AS UK_Sanctioned_Security,
                    JSON_VALUE(jsonData.value, '$.DX657') AS DX657,
                    JSON_VALUE(jsonData.value, '$.LONG_COMPANY_NAME_REALTIME') AS 
Long_Company_Name_Realtime,
                    JSON_VALUE(jsonData.value, '$.ISSUER_BULK') AS Issuer_Bulk,
                    JSON_VALUE(jsonData.value, '$.SECURITY_NAME') AS Security_Name,
                    JSON_VALUE(jsonData.value, '$.DS122') AS DS
122,
                    JSON_VALUE(jsonData.value, '$.DS674') AS DS674,
                    JSON_VALUE(jsonData.value, '$.EQY_PRIM_SECURITY_CRNCY') AS EQY_Prim_Security_Crncy,
                    JSON_VALUE(jsonData.value, '$.CRNCY') AS Crncy,
          
          JSON_VALUE(jsonData.value, '$.PAR_AMT') AS Par_Amt,
                    JSON_VALUE(jsonData.value, '$.AMT_ISSUED') AS Amt_Issued,
                    JSON_VALUE(jsonData.value, '$.ISSUE_DT') AS Issue_Dt,
                    JSON_VALUE(jsonData.v
alue, '$.MATURITY') AS Maturity,
                    JSON_VALUE(jsonData.value, '$.DS497') AS DS497,
                    JSON_VALUE(jsonData.value, '$.CPN_FREQ') AS Cpn_Freq,
                    JSON_VALUE(jsonData.value, '$.NXT_CPN_DT') AS Nxt_Cpn_Dt,
  
                  JSON_VALUE(jsonData.value, '$.INT_ACC') AS Int_Acc,
                    JSON_VALUE(jsonData.value, '$.FOUND') AS Found,
                    NULL AS ErrorMessage,
					@todayInt as date
                FROM OPENJSON(@JsonResult) AS jsonDa
ta;
            END
            ELSE
            BEGIN
                -- Если JSON некорректен, добавляем запись с сообщением об ошибке
                INSERT INTO #ParsedResults (Code, ErrorMessage)
                VALUES (@IsinCode, 'Некорректный JSON:
 ' + LEFT(@JsonResult, 1000));
            END;

        END TRY
        BEGIN CATCH
            -- Обработка ошибок
            SET @ErrorMessage = ERROR_MESSAGE();
            INSERT INTO #ParsedResults (Code, ErrorMessage)
            VALUES (@IsinCode
, @ErrorMessage);
        END CATCH;

        -- Обновляем текущий ряд для следующей итерации
        SET @CurrentRow = @CurrentRow + 1;

        -- Очищаем временную таблицу перед следующим запросом
        DELETE FROM #Curloutput_TEST;
    END;

    -- 
Выводим результаты парсинга
     insert into QORT_arm_sUPPORT_TEST.DBO.BloombergData 
SELECT  * FROM #ParsedResults

END;
