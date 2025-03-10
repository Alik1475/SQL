

-- exec QORT_ARM_SUPPORT..BDP_FlaskRequestOPT @IP= '192.168.13.80', @IsinCode = 'NBIS US 04/17/25 C33 Equity'

CREATE PROCEDURE [dbo].[BDP_FlaskRequestOPT] @IP VARCHAR(16)

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

	DECLARE @Fields NVARCHAR(MAX) = '\"NAME\",\"PX_CLOSE_1D\",\"OPT_EXER_TYP\",\"OPT_CONT_SIZE\",\"CRNCY\",\"OPT_STRIKE_PX\",\"OPT_UNDL_TICKER\",\"OPT_PUT_CALL\",\"OPT_EXPIRE_DT\"';



	CREATE TABLE #Curloutput_TEST (OUTPUT NVARCHAR(MAX));



	DECLARE @Curloutput TABLE (OUTPUT NVARCHAR(MAX));



	CREATE TABLE #ParsedResults (

		DATE INT

		,Code NVARCHAR(50)

		,Name NVARCHAR(255)

		,PX_CLOSE_1D FLOAT

		,OPT_EXER_TYP NVARCHAR(255)

		,OPT_CONT_SIZE float

		,CRNCY NVARCHAR(10)

		,OPT_STRIKE_PX FLOAT

		,OPT_UNDL_TICKER NVARCHAR(255)

		,OPT_PUT_CALL NVARCHAR(10)

		,OPT_EXPIRE_DT NVARCHAR(255)

		,Found BIT

		,ErrorMessage NVARCHAR(MAX)

		-- Добавлено для хранения сообщений об ошибках

		, DS306 VARCHAR(5)

		, FUND_TYP VARCHAR(5)

		, DS004 VARCHAR(5)

		);



	-- Заполнение таблицы #Curloutput данными

/*	IF (@IsinCode IS NULL)

	BEGIN

		EXEC QORT_ARM_SUPPORT.dbo.CodeAssets;



		INSERT INTO @Curloutput (OUTPUT)

		SELECT ca.code

		FROM ##CodeAssets ca

			

		WHERE NOT EXISTS (

				SELECT 1

				FROM QORT_ARM_SUPPORT.dbo.BloombergData a

				WHERE a.code = ca.code

					AND a.DATE = @todayInt

				)

			

			--and ca.code = 'XS2196334671 CORP'

	END

	ELSE

	BEGIN

		INSERT INTO @Curloutput (OUTPUT)

		VALUES (@IsinCode)

	END

		--*/	

			

		INSERT INTO @Curloutput (OUTPUT)

		VALUES (@IsinCode)

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

					,OPT_EXER_TYP

					,OPT_CONT_SIZE

					,CRNCY

					,OPT_STRIKE_PX 

					,OPT_UNDL_TICKER 

					,OPT_PUT_CALL

					,OPT_EXPIRE_DT

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

					,JSON_VALUE(jsonData.value, '$.OPT_EXER_TYP') AS OPT_EXER_TYP



					,JSON_VALUE(jsonData.value, '$.OPT_CONT_SIZE') AS OPT_CONT_SIZE

					,JSON_VALUE(jsonData.value, '$.CRNCY') AS CRNCY 

					,JSON_VALUE(jsonData.value, '$.OPT_STRIKE_PX') AS OPT_STRIKE_PX

					,JSON_VALUE(jsonData.value, '$.OPT_UNDL_TICKER') AS OPT_UNDL_TICKER

					,JSON_VALUE(jsonData.value, '$.OPT_PUT_CALL') AS OPT_PUT_CALL

					--,JSON_VALUE(jsonData.value, '$.OPT_EXPIRE_DT') AS OPT_EXPIRE_DT

					,TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(JSON_VALUE(jsonData.value, '$.OPT_EXPIRE_DT') AS BIGINT) / 60000, '1970-01-01'), 112) /*JSON_VALUE(jsonData.value, '$.DS027') */ AS OPT_EXPIRE_DT

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



		/*	--обновление таблицы Ассетс, если бумага HE найдена в Блумберг, чтобы больше не запрашивать---

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

	--INSERT INTO QORT_ARM_SUPPORT.DBO.BloombergData

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



	--/*

			insert into QORT_BACK_TDB.dbo.Assets(

			IsProcessed, ET_Const

			, Name

			--, ISIN

			, AssetClass_Const

			, AssetSort_Const, AssetType_Const, CancelDate

			, ShortName, DocName

			--, EmitDate

			, PricingTSSectionName

			, BaseCurrencyAsset

			, Marking

			, IsTrading

			, Scale

			, BaseAsset

			, OptionStrike

			, OPS_Const

			, BaseAssetSize

			, BaseAssetPutDate

		) 

	--	*/

		SELECT TOP 1 1 as IsProcessed, 2 as ET_Const,

			 BL.name NAME

			 --, LEFT(BL.Code,12) ISIN



			 , 4 AS AssetClass_Const --OPTION

			 , IIF(BL.OPT_PUT_CALL = 'CALL', 19,18)	 AssetSort_Const

			 , 2 -- Rights and liabilities

							 AssetType_Const

			 , BL.OPT_EXPIRE_DT AS CancelDate

			 , REPLACE(BL.Code, ' Equity', '')	ShortName

			, REPLACE(BL.Code, ' Equity', '')	DocName

			, 'OPRA' PricingTSSectionName

			, CRNCY BaseCurrencyAsset

			, REPLACE(BL.Code, ' Equity', '') Marking

			, 'y' IsTrading

			, 8 Scale

			, BOCO.ShortName as BaseAsset

			, BL.OPT_STRIKE_PX OptionStrike

			, case when BL.OPT_EXER_TYP = 'American' then 1

			       when BL.OPT_EXER_TYP = 'European' then 2

				   when BL.OPT_EXER_TYP = 'Bermudian' then 3

				   when BL.OPT_EXER_TYP = 'Exotic' then 4

				   when BL.OPT_EXER_TYP = '	Asian' then 5

				   else 0 end

			OPS_Const

			,BL.OPT_CONT_SIZE BaseAssetSize

			,BL.OPT_EXPIRE_DT BaseAssetPutDate

			--into #t

		 FROM #ParsedResults BL

		 outer apply
					(select top 1  Marking, ShortName
							from QORT_BACK_DB.dbo.Assets a
							where bl.OPT_UNDL_TICKER = a.ShortName

					) BOCO

		 WHERE-- BL.Code = @IsinCodes AND BL.Found = 1 and

		  NOT EXISTS (
				select 1 
				from QORT_BACK_DB.dbo.Assets a
				where a.ShortName = REPLACE(BL.Code, ' Equity', '') and a.Enabled = 0
			)









END;

