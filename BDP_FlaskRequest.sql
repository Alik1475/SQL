

-- exec QORT_ARM_SUPPORT..BDP_FlaskRequest @IP= '192.168.13.80', @IsinCode = 'US05554TRQ03 corp'

CREATE PROCEDURE [dbo].[BDP_FlaskRequest] @IP VARCHAR(16)

	,@IsinCode NVARCHAR(MAX)

AS

BEGIN

	-- Проверка и создание временных таблиц

	IF OBJECT_ID('tempdb..#Curloutput_TEST') IS NOT NULL

		DROP TABLE #Curloutput_TEST;



	IF OBJECT_ID('tempdb..#Curloutput') IS NOT NULL

		DROP TABLE #Curloutput;



	IF OBJECT_ID('tempdb..#ParsedResults') IS NOT NULL

		DROP TABLE #ParsedResults;



	DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках

	DECLARE @todayDate DATE = GETDATE()

	DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

	DECLARE @Fields NVARCHAR(MAX) = '\"NAME\",\"PX_CLOSE_1D\",\"CPN\",\"DS027\",\"INDUSTRY_SECTOR\",\"YAS_BOND_YLD\",\"AMT_OUTSTANDING\",\"DX129\",\"SECTORAL_SANCTIONED_SECURITY\",\"OFAC_SANCTIONED_SECURITY\",\"EU_SANCTIONED_SECURITY\",\"UK_SANCTIONED_SECURI
TY\",\"DX657\",\"LONG_COMPANY_NAME_REALTIME\",\"ISSUER_BULK\",\"SECURITY_NAME\",\"DS122\",\"DS674\",\"EQY_PRIM_SECURITY_CRNCY\",\"CRNCY\",\"PAR_AMT\",\"AMT_ISSUED\",\"ISSUE_DT\",\"MATURITY\",\"DS497\",\"CPN_FREQ\",\"NXT_CPN_DT\",\"INT_ACC\",\"DS306\",\"FU
ND_TYP\",\"DS004\"';



	CREATE TABLE #Curloutput_TEST (OUTPUT NVARCHAR(MAX));



	DECLARE @Curloutput TABLE (OUTPUT NVARCHAR(MAX));



	CREATE TABLE #ParsedResults (

		DATE INT

		,Code NVARCHAR(50)

		,Name NVARCHAR(255)

		,PX_CLOSE_1D FLOAT

		,Cpn FLOAT

		,DS027 NVARCHAR(255)

		,Industry_Sector NVARCHAR(255)

		,YAS_BOND_YLD FLOAT

		,Amt_Outstanding FLOAT

		,DX129 NVARCHAR(50)

		,Sectoral_Sanctioned_Security NVARCHAR(10)

		,OFAC_Sanctioned_Security NVARCHAR(10)

		,EU_SANCTIONED_SECURITY NVARCHAR(10)

		,UK_Sanctioned_Security NVARCHAR(10)

		,DX657 NVARCHAR(50)

		,Long_Company_Name_Realtime NVARCHAR(255)

		,Issuer_Bulk NVARCHAR(255)

		,Security_Name NVARCHAR(255)

		,DS122 NVARCHAR(255)

		,DS674 NVARCHAR(255)

		,EQY_Prim_Security_Crncy NVARCHAR(10)

		,Crncy NVARCHAR(10)

		,Par_Amt FLOAT

		,Amt_Issued FLOAT

		,Issue_Dt NVARCHAR(255)

		,Maturity NVARCHAR(255)

		,DS497 NVARCHAR(255)

		,Cpn_Freq NVARCHAR(50)

		,Nxt_Cpn_Dt NVARCHAR(255)

		,Int_Acc FLOAT

		,Found BIT

		,ErrorMessage NVARCHAR(MAX)

		-- Добавлено для хранения сообщений об ошибках

		, DS306 VARCHAR(5)

		, FUND_TYP VARCHAR(5)

		, DS004 VARCHAR(5)

		);



	-- Заполнение таблицы #Curloutput данными

	IF (@IsinCode IS NULL)

	BEGIN

		EXEC QORT_ARM_SUPPORT.dbo.CodeAssets;



		INSERT INTO @Curloutput (OUTPUT)

		SELECT ca.code

		FROM ##CodeAssets ca

		--/*	

		WHERE NOT EXISTS (

				SELECT 1

				FROM QORT_ARM_SUPPORT.dbo.BloombergData a

				WHERE a.code = ca.code

					AND a.DATE = @todayInt

				)

			--*/

			--and ca.code = 'XS2196334671 CORP'

	END

	ELSE

	BEGIN

		INSERT INTO @Curloutput (OUTPUT)

		VALUES (@IsinCode)

	END



	SELECT *

	FROM @Curloutput



	--return

	--return

	DECLARE @TotalRows INT;

	DECLARE @CurrentRow INT = 1;

	-- DECLARE @IsinCode NVARCHAR(MAX);

	DECLARE @CurlCommand NVARCHAR(4000);

	DECLARE @JsonResult NVARCHAR(MAX);

	DECLARE @ErrorMessage NVARCHAR(MAX);



	-- Получаем общее количество строк

	SELECT @TotalRows = COUNT(*)

	FROM @Curloutput;



	-- Цикл для обработки данных по одному ISIN-коду за раз

	WHILE @CurrentRow <= @TotalRows

	BEGIN

		-- Получаем один ISIN-код для обработки

		SELECT @IsinCode =

		OUTPUT

		FROM (

			SELECT ROW_NUMBER() OVER (

					ORDER BY (

							SELECT NULL

							)

					) AS RowNum

				,

			OUTPUT

			FROM @Curloutput

			) AS OrderedData

		WHERE RowNum = @CurrentRow;



		-- Подготовка команды curl

		SET @IsinCode = '\"' + @IsinCode + '\"';

		SET @CurlCommand = 'curl -X POST http://' + @IP + ':5001/get_data -H "Content-Type: application/json" -d "{\"isin_codes\": [' + @IsinCode + '], \"fields\": [' + @Fields + ']}"';



		PRINT @CurlCommand



		BEGIN TRY

			-- Выполнение команды curl

			INSERT INTO #Curloutput_TEST (OUTPUT)

			EXEC xp_cmdshell @CurlCommand;



			-- Обработка результатов curl

			SELECT @JsonResult = STRING_AGG(CAST(OUTPUT AS NVARCHAR(MAX)), '')

			FROM #Curloutput_TEST

			WHERE

			OUTPUT IS NOT NULL;



			-- Очистка результата от всего перед первым символом '['

			SET @JsonResult = SUBSTRING(@JsonResult, CHARINDEX('[', @JsonResult), LEN(@JsonResult));



			-- Проверка правильности JSON и вывод на экран

			PRINT @JsonResult;



			-- Проверка правильности JSON

			IF ISJSON(@JsonResult) = 1

			BEGIN

				PRINT 'JSON is valid';



				-- Вставка распарсенных данных в таблицу #ParsedResults

				INSERT INTO #ParsedResults (

					DATE

					,Code

					,Name

					,PX_CLOSE_1D

					,Cpn

					,DS027

					,Industry_Sector

					,YAS_BOND_YLD

					,Amt_Outstanding

					,DX129

					,Sectoral_Sanctioned_Security

					,OFAC_Sanctioned_Security

					,EU_SANCTIONED_SECURITY

					,UK_Sanctioned_Security

					,DX657

					,Long_Company_Name_Realtime

					,Issuer_Bulk

					,Security_Name

					,DS122

					,DS674

					,EQY_Prim_Security_Crncy

					,Crncy

					,Par_Amt

					,Amt_Issued

					,Issue_Dt

					,Maturity

					,DS497

					,Cpn_Freq

					,Nxt_Cpn_Dt

					,Int_Acc

					,Found

					,ErrorMessage

					,DS306

					,FUND_TYP

					,DS004

					)

				SELECT @todayInt AS DATE

					,JSON_VALUE(jsonData.value, '$.CODE') AS Code

					,JSON_VALUE(jsonData.value, '$.NAME') AS Name

					,JSON_VALUE(jsonData.value, '$.PX_CLOSE_1D') AS PX_CLOSE_1D

					,JSON_VALUE(jsonData.value, '$.CPN') AS Cpn

					,TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(JSON_VALUE(jsonData.value, '$.DS027') AS BIGINT) / 60000, '1970-01-01'), 112) /*JSON_VALUE(jsonData.value, '$.DS027') */ AS DS027

					,JSON_VALUE(jsonData.value, '$.INDUSTRY_SECTOR') AS Industry_Sector

					,JSON_VALUE(jsonData.value, '$.YAS_BOND_YLD') AS YAS_BOND_YLD

					,JSON_VALUE(jsonData.value, '$.AMT_OUTSTANDING') AS Amt_Outstanding

					,JSON_VALUE(jsonData.value, '$.DX129') AS DX129

					,JSON_VALUE(jsonData.value, '$.SECTORAL_SANCTIONED_SECURITY') AS Sectoral_Sanctioned_Security

					,JSON_VALUE(jsonData.value, '$.OFAC_SANCTIONED_SECURITY') AS OFAC_Sanctioned_Security

					,JSON_VALUE(jsonData.value, '$.EU_SANCTIONED_SECURITY') AS EU_SANCTIONED_SECURITY

					,JSON_VALUE(jsonData.value, '$.UK_SANCTIONED_SECURITY') AS UK_Sanctioned_Security

					,JSON_VALUE(jsonData.value, '$.DX657') AS DX657

					,JSON_VALUE(jsonData.value, '$.LONG_COMPANY_NAME_REALTIME') AS Long_Company_Name_Realtime

					,JSON_VALUE(jsonData.value, '$.ISSUER_BULK') AS Issuer_Bulk

					,JSON_VALUE(jsonData.value, '$.SECURITY_NAME') AS Security_Name

					,JSON_VALUE(jsonData.value, '$.DS122') AS DS122

					,JSON_VALUE(jsonData.value, '$.DS674') AS DS674

					,JSON_VALUE(jsonData.value, '$.EQY_PRIM_SECURITY_CRNCY') AS EQY_Prim_Security_Crncy

					,JSON_VALUE(jsonData.value, '$.CRNCY') AS Crncy

					,JSON_VALUE(jsonData.value, '$.PAR_AMT') AS Par_Amt

					,JSON_VALUE(jsonData.value, '$.AMT_ISSUED') AS Amt_Issued

					,JSON_VALUE(jsonData.value, '$.ISSUE_DT') AS Issue_Dt

					,JSON_VALUE(jsonData.value, '$.MATURITY') AS Maturity

					,JSON_VALUE(jsonData.value, '$.DS497') AS DS497

					,JSON_VALUE(jsonData.value, '$.CPN_FREQ') AS Cpn_Freq

					,JSON_VALUE(jsonData.value, '$.NXT_CPN_DT') AS Nxt_Cpn_Dt

					,JSON_VALUE(jsonData.value, '$.INT_ACC') AS Int_Acc

					,JSON_VALUE(jsonData.value, '$.FOUND') AS Found

					,NULL AS ErrorMessage

					,JSON_VALUE(jsonData.value, '$.DS306') AS DS306

					,JSON_VALUE(jsonData.value, '$.FUND_TYP') AS FUND_TYP

					,JSON_VALUE(jsonData.value, '$.DS004') AS DS004

				FROM OPENJSON(@JsonResult) AS jsonData;

			END

			ELSE

			BEGIN

				-- Если JSON некорректен, добавляем запись с сообщением об ошибке

				INSERT INTO #ParsedResults (

					Code

					,ErrorMessage

					)

				VALUES (

					@IsinCode

					,'Некорректный JSON: ' + LEFT(@JsonResult, 1000)

					);

			END;

		END TRY



		BEGIN CATCH

			-- Обработка ошибок

			SET @ErrorMessage = ERROR_MESSAGE();



			INSERT INTO #ParsedResults (

				Code

				,ErrorMessage

				)

			VALUES (

				@IsinCode

				,@ErrorMessage

				);

		END CATCH;



		--/*	--обновление таблицы Ассетс, если бумага HE найдена в Блумберг, чтобы больше не запрашивать---

		IF EXISTS (

				SELECT 1

				FROM #ParsedResults

				WHERE left(code, 12) = SUBSTRING(@IsinCode, 3, 12)

					AND found = 0

				)

		BEGIN

			INSERT INTO QORT_BACK_TDB.dbo.Assets (

				IsProcessed

				,ET_Const

				,ISIN

				,PricingTSSectionName

				,shortName

				,Marking

				)

			SELECT DISTINCT 1 AS IsProcessed

				,4 AS ET_Const

				,ass.ISIN ISIN

				,'OTC_SWAP' AS PricingTSSectionName

				,ass.ShortName shortName

				,ass.Marking Marking

			FROM QORT_BACK_DB.dbo.Assets ass

			WHERE ass.ISIN = SUBSTRING(@IsinCode, 3, 12)

				AND ass.Enabled <> ass.id

		END



		--обновление таблицы Ассетс, если бумага найдена в Блумберг, чтобы больше не запрашивать---

		IF EXISTS (

				SELECT 1

				FROM #ParsedResults

				WHERE left(code, 12) = SUBSTRING(@IsinCode, 3, 12)

					AND found = 1

				)

		BEGIN

			INSERT INTO QORT_BACK_TDB.dbo.Assets (

				IsProcessed

				,ET_Const

				,ISIN

				,PricingTSSectionName

				,shortName

				,Marking

				)

			SELECT DISTINCT 1 AS IsProcessed

				,4 AS ET_Const

				,ass.ISIN ISIN

				,'OTC_Securities' AS PricingTSSectionName

				,ass.ShortName shortName

				,ass.Marking Marking

			FROM QORT_BACK_DB.dbo.Assets ass

			WHERE ass.ISIN = SUBSTRING(@IsinCode, 3, 12)

				AND ass.Enabled <> ass.id

		END



		--*/

		-- Обновляем текущий ряд для следующей итерации

		SET @CurrentRow = @CurrentRow + 1;



		-- Очищаем временную таблицу перед следующим запросом

		DELETE

		FROM #Curloutput_TEST;

	END;



	-- Выводим результаты парсинга

	INSERT INTO QORT_ARM_SUPPORT.DBO.BloombergData

	SELECT *

	FROM #ParsedResults pa

	WHERE NOT EXISTS (

			SELECT 1

			FROM QORT_ARM_SUPPORT.DBO.BloombergData a

			WHERE a.Code = Pa.Code

				AND DATE = @todayInt

			)



	--and pa.Found = 1

	SELECT *

	FROM #ParsedResults

END;

