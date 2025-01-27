

-- exec QORT_ARM_SUPPORT.dbo.upload_REPO_OTC_Edgar

CREATE PROCEDURE [dbo].[upload_REPO_OTC_Edgar]

	-- @Nom varchar(12)

AS

BEGIN

	SET NOCOUNT ON;



	BEGIN TRY

		EXEC xp_cmdshell 'powershell.exe -File "C:\scripts\StartTask.ps1"';



		WAITFOR DELAY '00:02:00';



		-- Объявление переменных

		-- return

		DECLARE @todayDate DATE = GETDATE()

		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

		DECLARE @WaitCount INT

		DECLARE @n INT

		DECLARE @MaxRow INT

		DECLARE @Message VARCHAR(1024)

		DECLARE @Result VARCHAR(128)

		DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\DealsRepo\DealsR.xlsx'

		DECLARE @NotifyEmail VARCHAR(1024) = 'aleksandr.mironov@armbrok.am'

		DECLARE @Sheet1 VARCHAR(64) = 'Sheet1'

		DECLARE @sql VARCHAR(1024)



		-- Удаляем временные таблицы, если они существуют

		IF OBJECT_ID('tempdb..#t10', 'U') IS NOT NULL

			DROP TABLE #t10



		IF OBJECT_ID('tempdb..#t9', 'U') IS NOT NULL

			DROP TABLE #t9



		IF OBJECT_ID('tempdb..#t8', 'U') IS NOT NULL

			DROP TABLE #t8



		IF OBJECT_ID('tempdb..##f', 'U') IS NOT NULL

			DROP TABLE ##f



		IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL

			DROP TABLE #t



		/*IF OBJECT_ID('tempdb..##lt1223', 'U') IS NOT NULL DROP TABLE ##lt1223

		IF OBJECT_ID('tempdb..##lt09', 'U') IS NOT NULL DROP TABLE ##lt09

		IF OBJECT_ID('tempdb..##lt08', 'U') IS NOT NULL DROP TABLE ##lt08

		IF OBJECT_ID('tempdb..##lt07', 'U') IS NOT NULL DROP TABLE ##lt07

		IF OBJECT_ID('tempdb..##lt06', 'U') IS NOT NULL DROP TABLE ##lt06

		IF OBJECT_ID('tempdb..##lt05', 'U') IS NOT NULL DROP TABLE ##lt05

		IF OBJECT_ID('tempdb..##lt04', 'U') IS NOT NULL DROP TABLE ##lt04

		IF OBJECT_ID('tempdb..##lt03', 'U') IS NOT NULL DROP TABLE ##lt03

		IF OBJECT_ID('tempdb..##lt02', 'U') IS NOT NULL DROP TABLE ##lt02

		IF OBJECT_ID('tempdb..##lt01', 'U') IS NOT NULL DROP TABLE ##lt01

		*/

		-- Подготовка запроса для импорта данных из Excel-файла в временную таблицу ##f

		SET @sql = 'SELECT * INTO ##f

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database=' + @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + @Sheet1 + '$A1:Q1000]'')'



		EXEC (@sql)



		/*

		SET @sql = 'SELECT * INTO ##lt09

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '09' + '$A1:Q500]'')'

        EXEC(@sql)



			SET @sql = 'SELECT * INTO ##lt08

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '08' + '$A1:Q500]'')'

        EXEC(@sql)



		  SET @sql = 'SELECT * INTO ##lt1223

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '1223' + '$A1:Q500]'')'

        EXEC(@sql)



		   

		  SET @sql = 'SELECT * INTO ##lt07

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '07' + '$A1:Q500]'')'

        EXEC(@sql)



			  SET @sql = 'SELECT * INTO ##lt06

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '06' + '$A1:Q500]'')'

        EXEC(@sql)

			 SET @sql = 'SELECT * INTO ##lt05

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '05' + '$A1:Q500]'')'

        EXEC(@sql)

		      SET @sql = 'SELECT * INTO ##lt04

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '04' + '$A1:Q500]'')'

        EXEC(@sql)

			      SET @sql = 'SELECT * INTO ##lt03

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '03' + '$A1:Q500]'')'

        EXEC(@sql)

					      SET @sql = 'SELECT * INTO ##lt02

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '02' + '$A1:Q500]'')'

        EXEC(@sql)

					      SET @sql = 'SELECT * INTO ##lt01

        FROM OPENROWSET (

            ''Microsoft.ACE.OLEDB.12.0'',

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + '01' + '$A1:Q500]'')'

        EXEC(@sql)

		--select * from ##lt

		*/

		-- Проверка данных из Excel-файла

		DELETE

		FROM ##f

		WHERE [F1] = ''

			OR [F1] = '0'



		/* delete FROM ##lt1223 where [F1] = ''

		   delete FROM ##lt09 where [F1] = ''

           delete FROM ##lt08 where [F1] = ''

		   delete FROM ##lt07 where [F1] = ''

		   delete FROM ##lt06 where [F1] = ''

		   delete FROM ##lt05 where [F1] = ''

		   delete FROM ##lt04 where [F1] = ''

		   delete FROM ##lt03 where [F1] = ''

		   delete FROM ##lt02 where [F1] = ''

		   delete FROM ##lt01 where [F1] = ''*/

		--select * from ##f order by [F14]

		--select * from ##lt order by [F14]--return

		-- Забираем значения из файла Excel, в который подгружаются данные из Bloomberg

		CREATE TABLE #t (

			ISIN VARCHAR(50)

			,Qty FLOAT -- Укажите подходящий размер для поля ISIN

			,Volume FLOAT -- Тип данных для объёма

			,Dataleg1 VARCHAR(16)

			,Dataleg2 VARCHAR(16)

			,Repoday INT

			,-- Например, тип данных для дней

			DataFirst VARCHAR(16)

			,Rate FLOAT -- Процентная ставка, используйте FLOAT или другой подходящий тип

			,VolPercent FLOAT -- Тип данных для процента объёма

			,CP VARCHAR(50)

			,-- Укажите размер для поля CP

			Agrement VARCHAR(16)

			,Currency VARCHAR(3) -- Размер для валютного кода (например, "USD", "EUR")

			);



		INSERT INTO #t (

			ISIN

			,Qty

			,Volume

			,Dataleg1

			,Dataleg2

			,Repoday

			,DataFirst

			,Rate

			,VolPercent

			,CP

			,Agrement

			,Currency

			)

		SELECT [F2] AS ISIN

			,[F3] AS Qty

			,[F4] AS Volume

			,CAST([F7] AS VARCHAR(16)) AS Dataleg1

			,CAST([F8] AS VARCHAR(16)) AS Dataleg2

			,[F9] AS Repoday

			,CAST([F10] AS VARCHAR(16)) AS DataFirst

			,[F11] AS Rate

			,[F12] AS VolPercent

			,[F13] AS CP

			,CAST([F14] AS VARCHAR(16)) AS Agrement

			,[F17] AS Currency

		FROM ##f f

		WHERE ISNULL(f.[F14], '0') <> '0'



		/*

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt1223 lt1223

WHERE ISNULL(lt1223.[F14], '0') <> '0'   



union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt09 lt09

WHERE ISNULL(lt09.[F14], '0') <> '0' 

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt08 lt08

WHERE ISNULL(lt08.[F14], '0') <> '0' 

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt07 lt07

WHERE ISNULL(lt07.[F14], '0') <> '0'    

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt06 lt06

WHERE ISNULL(lt06.[F14], '0') <> '0' 

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt05 lt05

WHERE ISNULL(lt05.[F14], '0') <> '0' 

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt04 lt04

WHERE ISNULL(lt04.[F14], '0') <> '0'   

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt03 lt03

WHERE ISNULL(lt03.[F14], '0') <> '0'

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt02 lt02

WHERE ISNULL(lt02.[F14], '0') <> '0'  

union

SELECT 

      [F2] AS ISIN

	, [F3] AS Qty

    , [F4] AS Volume

    , CAST([F7] AS VARCHAR(16)) AS Dataleg1

    , CAST([F8] AS VARCHAR(16)) AS Dataleg2

    , [F9] AS Repoday

    , CAST([F10] AS VARCHAR(16)) AS DataFirst

    , [F11] AS Rate

    , [F12] AS VolPercent

    , [F13] AS CP

    , CAST([F14] AS VARCHAR(16)) AS Agrement

    , [F17] AS Currency

FROM ##lt01 lt01

WHERE ISNULL(lt01.[F14], '0') <> '0';   

*/

		-- Проверка и вывод данных из временной таблицы #t

		-- SELECT * FROM #t order by Agrement

		--where left(Agrement,3) = @Nom 

		--where right(DataFirst,7) = '10/2024' 

		--	ORDER BY Dataleg1

		--return

		DECLARE @ISIN VARCHAR(16) = 'US0378331005' --'US87238U2033'--USY77108AA93

		DECLARE @BuySell INT = 1 --2

		DECLARE @TSSEC VARCHAR(16) = 'ОТС_REPO'

		DECLARE @TradeDate INT = 20240917

		DECLARE @Qty FLOAT = 5 - 1 - 0

		DECLARE @FirmID INT = 6 -- BCS Cyprus

		DECLARE @payCur VARCHAR(16) = 'EUR' -- MXN

		DECLARE @payCurID INT = (

				SELECT TOP 1 id

				FROM QORT_BACK_DB..Assets

				WHERE Name = 'EUR'

				)



		----------------------добавление инструмента НА ПЛОЩАДКУ ОТС РЕПО ЕСЛИ НЕТ--------------------------

		--/*

		INSERT INTO QORT_BACK_TDB.dbo.Securities (

			IsProcessed

			,ET_Const

			,ShortName

			,Name

			,TSSection_Name

			,SecCode

			,Asset_ShortName

			,QuoteList

			,IsProcent

			,LotSize

			,IsTrading

			,Lot_multiplicity

			,Scale

			,CurrPriceAsset_ShortName

			)

		--*/

		SELECT DISTINCT 1 AS IsProcessed

			,2 AS ET_Const

			,s.shortname

			,s.ISIN Name

			,'ОТС_REPO' AS TSSection_Name

			,s.ISIN secCode

			,s.ShortName Asset_ShortName

			,1 QuoteList

			,iif(s.AssetSort_Const IN (

					6

					,3

					), 'y', NULL) IsProcent

			,1 LotSize

			,'y' IsTrading

			,1 lot_multiplicity

			,8 Scale

			,B.ShortName CurrPriceAsset_ShortName

		--into #t10 

		FROM #t ttt

		LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets s ON ttt.isin = s.ISIN

		LEFT JOIN QORT_BACK_DB.dbo.Assets b ON B.ID = s.BaseCurrencyAsset_ID

			AND b.Enabled = 0

		WHERE s.Enabled = 0

			AND s.id IS NOT NULL

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Securities a

				WHERE a.Asset_ID = s.id

					AND a.Enabled = 0

					AND a.TSSection_ID = 160 -- OTC_REPO

				)



		--select * from #t10-- return

		SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------



		WHILE (

				@WaitCount > 0

				AND EXISTS (

					SELECT TOP 1 1

					FROM QORT_BACK_TDB.dbo.Securities q WITH (NOLOCK)

					WHERE q.IsProcessed IN (

							1

							,2

							)

					)

				)

		BEGIN

			WAITFOR DELAY '00:00:03'



			SET @WaitCount = @WaitCount - 1

		END



		--/*

		INSERT INTO QORT_BACK_TDB.dbo.ImportTrades (

			IsProcessed

			,ET_Const

			,IsDraft

			,TradeDate

			,TSSection_Name

			,BuySell

			,Security_Code

			,Qty

			,Price

			,BackPrice

			,Volume1

			,Volume2

			,CurrPriceAsset_ShortName

			,PutPlannedDate

			,PayPlannedDate

			,RepoDate2

			,BackDate

			,PutAccount_ExportCode

			,PayAccount_ExportCode

			,SubAcc_Code

			,AgreeNum

			,TT_Const

			,CpFirm_ShortName

			,Comment

			,AgreePlannedDate

			,Accruedint

			--, TraderUser_ID, SalesManager_ID

			,PT_Const

			,TSCommission

			,IsAccrued

			,IsSynchronize --, CpSubacc_Code

			,SS_Const

			,FunctionType

			,CurrPayAsset_ShortName

			,CrossRate

			--, ExternalNum

			--, TradeNum

			,Discount

			,RepoRate

			--, QFlags

			--, PriceEx

			,RepoBasis

			,CRT_Const

			,CrossRateDate

			) --*/

		SELECT 1 AS IsProcessed

			,2 AS ET_Const

			,'n' AS IsDraft

			,CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) TradeDate

			,'ОТС_REPO' TSSection_Name

			,IIF(t.agrement NOT LIKE '%HR%', 2, 1) BuySell

			,isnull(sec.SecCode, 'unknow' + t.ISIN) Security_Code

			,t.Qty / IIF(ASS.AssetClass_Const in (6), ISNULL(ASS.basevalue, 1), 1) Qty

			,IIF(ASS.AssetClass_Const in (6),t.Volume / isnull(t.Qty, 1) * 100 * iif(assBC.name = t.Currency, 1, IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid), 1)),t.Volume/t.Qty)  Price

			,IIF(ASS.AssetClass_Const in (6),(t.Volume + t.VolPercent) / isnull(t.Qty, 1) * 100 * iif(assBC.name = t.Currency, 1, IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid), 1)),(t.Volume + t.VolPer
cent)/t.Qty ) BackPrice

			,ROUND(t.Volume, 2) Volume1

			,ROUND(t.Volume + t.VolPercent, 2) Volume2

			,assbc.Name CurrPriceAsset_ShortName

			,CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) PutPlannedDate

			,CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) PayPlannedDate

			,CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) + RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) RepoDate2

			,CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) + RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) BackDate

			,iif((

					t.isin IN (

						'XS2010043904'

						,'XS2080321198'

						,'XS2010028939'

						)

					OR t.CP IN ('Trinfiko')

					), 'CLIENT_CDA_Own', 'CB_RA_FOR_REPO') PutAccount_ExportCode

			,'Armbrok_Mn_OWN' PayAccount_ExportCode

			,'ARMBR_Subacc' AS SubAcc_Code

			,t.Agrement AgreeNum

			,6 TT_Const --OTC repo

			,CASE 

				WHEN t.CP = 'HSBC'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00885'

							)

				WHEN t.CP = 'Trinfiko'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00804'

							)

				WHEN t.CP = 'Armswissbank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00035'

							)

				WHEN t.CP = 'Artsakhbank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '01146'

							)

				WHEN t.CP = 'Acba'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00018'

							)

				WHEN t.CP = 'ArmEconombank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00033'

							)

				WHEN t.CP = 'ABB'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00032'

							) --amio bank

				WHEN t.CP = 'Anelik'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00347'

							)

				WHEN t.CP = 'Ardshininvestbank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00029'

							)

				WHEN t.CP = 'Ameriabank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00025'

							)

				WHEN t.CP = 'Prometeybank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00059'

							) --evoca bank

				WHEN t.CP = 'Araratbank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00028'

							)

				WHEN t.CP = 'Fastbank'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00064'

							)

				WHEN t.CP = 'Glocal USD'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00362'

							)

				WHEN t.CP = 'Glocal AMD'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00360'

							)

				WHEN t.CP = 'Evgeniy Renge'

					THEN (

							SELECT FirmShortName

							FROM QORT_BACK_DB..Firms

							WHERE BOCode = '00789'

							)

				ELSE 'unknow_' + t.CP

				END CpFirm_ShortName

			,'autoload' Comment

			,CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) AgreePlannedDate

			,0 Accruedint

			--, uTrader.id TraderUser_ID

			--, uSales.id SalesManager_ID

			,IIF(sec.IsProcent = 'y', 1, 2) PT_Const

			,0 TSCommission

			,'n' IsAccrued

			,'n' IsSynchronize

			--, d.[Counterparty Subaccount] CpSubacc_Code

			,1 SS_Const -- вид оасчетов

			,0 FunctionType -- функциональный тип

			,t.Currency CurrPayAsset_ShortName

			,isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid), 1) / isnull(IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid), 1) CrossRate

			--, isnull(cast(d.AgreeMent as varchar), 'N/A') ExternalNum

			--, @TradeDate + ass.id

			,0 Discount

			,t.Rate RepoRate

			--, 562949953421312 qflags

			--, 123 PriceEx-- Open REPO trade

			,iif(right(t.agrement, 3) = '24R', 7, 3) RepoBasis -- 7-TBT_ACT_366/ 3-TBT_ACT_365 

			,iif(assbc.Name = t.currency, 1, 1) CRT_Const

			,iif(assbc.Name = t.currency, 0, CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))) CrossRateDate

		FROM #t t

		OUTER APPLY (

			SELECT TOP 1 *

			FROM QORT_BACK_DB.dbo.Assets ass

			WHERE ass.ISIN = t.ISIN

				AND ass.Enabled = 0

			) AS ass

		OUTER APPLY (

			SELECT TOP 1 *

			FROM QORT_BACK_DB.dbo.Securities sec

			WHERE sec.Asset_ID = ass.id

				AND sec.Enabled = 0

				AND sec.TSSection_ID = (

					SELECT TOP 1 ID

					FROM QORT_BACK_DB..TSSections

					WHERE name = 'ОТС_REPO'

					)

			) AS sec

		OUTER APPLY (

			SELECT TOP 1 *

			FROM QORT_BACK_DB..CrossRatesHist crs

			WHERE crs.TradeAsset_ID = ass.BaseCurrencyAsset_ID

				AND crs.DATE = CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))

				AND crs.PriceAsset_ID = 17

				AND InfoSource = 'CBA'

			) crsAS

		OUTER APPLY (

			SELECT TOP 1 crs.Bid

			FROM QORT_BACK_DB..CrossRatesHist crs

			LEFT OUTER JOIN QORT_BACK_DB..Assets aaa ON aaa.Name = t.Currency

				AND aaa.Enabled = 0

			WHERE crs.TradeAsset_ID = aaa.id

				AND crs.DATE = CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) + RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) + RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))

				AND crs.PriceAsset_ID = 17

				AND InfoSource = 'CBA'

			) crsTr

		--left join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.Asset_ID =  ass.id and sec.TSSection_ID = (Select top 1 ID from QORT_BACK_DB..TSSections where name = 'ОТС_REPO')-- @TSSEC)

		--left join QORT_BACK_DB.dbo.MarketInfoHist mrk with (nolock) on mrk.Asset_ID = ass.id and mrk.OldDate = @TradeDate

		LEFT JOIN QORT_BACK_DB.dbo.Assets assBC WITH (NOLOCK) ON assBC.ID = ass.BaseCurrencyAsset_ID

		--left join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPut with (nolock) on aPut.AccountCode = d.DeliveryAccount collate Cyrillic_General_CS_AS

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPay with (nolock) on aPay.AccountCode = d.[Payment Account] collate Cyrillic_General_CS_AS

		WHERE t.Agrement NOT LIKE '%/%'

			AND sec.SecCode IS NOT NULL

			AND right(t.agrement, 1) = 'R'

			--and CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) > 20231231

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Trades tr

				WHERE tr.AgreeNum LIKE t.Agrement collate Cyrillic_General_CS_AS

					AND Tr.VT_Const NOT IN (

						12

						,10

						) -- сделка не расторгнута

					AND tr.NullStatus = 'n'

					AND tr.Enabled = 0

					AND tr.IsDraft = 'n'

					AND tr.IsProcessed = 'y'

				)

		ORDER BY AgreeNum 

		--return



		SELECT *

		FROM QORT_BACK_TDB.dbo.ImportTrades

		WHERE ImportInsertDate = @todayInt

			AND IsProcessed IN (

				1

				,2

				)

		ORDER BY AgreeNum



		SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили сделки----------------------



		WHILE (

				@WaitCount > 0

				AND EXISTS (

					SELECT TOP 1 1

					FROM QORT_BACK_TDB.dbo.ImportTrades q WITH (NOLOCK)

					WHERE q.IsProcessed IN (

							1

							,2

							)

					)

				)

		BEGIN

			WAITFOR DELAY '00:00:03'



			SET @WaitCount = @WaitCount - 1

		END



		/*	--------------------------------загружаем фазы прологации по поставкам активов-------------------

		Insert into QORT_BACK_TDB.dbo.phases (

			IsProcessed

			, ET_Const

			, AgreeNum

			, PC_Const

			, date

			, SystemID

			, BackID

			, InfoSource

			, Trade_SID

			, QtyBefore

			, SubAcc_Code

			, DateAfter

			, DateBefore

			, NewRepoRateDate

			, QtyAfter

			)

--*/

		SELECT cast(SUBSTRING(tt.Agrement, CHARINDEX('/', tt.Agrement) + 1, LEN(tt.Agrement)) AS INT) AS RowNum

			,1 AS IsProcessed

			,2 AS ET_Const

			,tt.agrement

			,14 PC_Const

			,CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DATE

			,(- 1) AS SystemID

			,tt.agrement + '_' + CAST(isnull(trad.id, '') AS VARCHAR(16)) AS BackID

			,NULL AS InfoSource

			,trad.id Trade_SID

			,0 AS QtyBefore

			,Sub.SubAccCode AS SubAcc_Code

			,CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			,CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) NewRepoRateDate

			,tt.Rate QtyAfter

			,trad.shortname

		INTO #t9

		FROM #t tt

		--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

		OUTER APPLY (

			SELECT TOP 1 ass.ShortName

				,trad1.id

				,trad1.SubAcc_ID

			FROM QORT_BACK_DB..Trades trad1

			LEFT OUTER JOIN QORT_BACK_DB..Securities sec ON sec.id = trad1.Security_ID

			LEFT OUTER JOIN QORT_BACK_DB..Assets ass ON ass.id = sec.Asset_ID

			WHERE trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

				AND Trad1.VT_Const NOT IN (

					12

					,10

					) -- сделка не расторгнута

				AND trad1.NullStatus = 'n'

				AND trad1.Enabled = 0

				AND trad1.IsDraft = 'n'

				AND trad1.IsProcessed = 'y'

				AND trad1.IsRepo2 = 'y'

				AND ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

			) trad

		LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = trad.SubAcc_ID

		WHERE tt.Agrement LIKE '%R/%'

			--and left(Agrement,3) = @Nom --+ '-24R/1'

			--and right(tt.DataFirst,7) = '09/2024' 

			--and LEFT(tt.agrement,3) = '518'

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Phases a

				WHERE (

						tt.Agrement + '_' + cast(isnull(trad.id, '') AS VARCHAR(16)) = a.BackID

						OR a.BackID = tt.Agrement

						)

					AND a.Enabled = 0

					AND a.IsCanceled = 'n'

					AND a.PC_Const = 14

				)

		ORDER BY tt.Agrement ASC



		SELECT *

		FROM #t9 --return



		SET @MaxRow = (

				SELECT MAX(rownum)

				FROM #t9

				)

		SET @n = 1



		WHILE @n <= @MaxRow

		BEGIN

			--/*	--------------------------------загружаем фазы прологации по поставкам активов через цикл-------------------

			INSERT INTO QORT_BACK_TDB.dbo.phases (

				IsProcessed

				,ET_Const

				,AgreeNum

				,PC_Const

				,DATE

				,SystemID

				,BackID

				,InfoSource

				,Trade_SID

				,QtyBefore

				,SubAcc_Code

				,DateAfter

				--, DateBefore

				,NewRepoRateDate

				,QtyAfter

				)

			--*/

			SELECT IsProcessed

				,ET_Const

				,agrement AgreeNum

				,PC_Const

				,DATE

				,SystemID

				,BackID

				,InfoSource

				,Trade_SID

				,QtyBefore

				,SubAcc_Code

				,DateAfter

				--, DateBefore

				,NewRepoRateDate

				,QtyAfter

			FROM #t9

			WHERE RowNum = @n



			SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили фазы по пролонгации по активам----------------------



			WHILE (

					@WaitCount > 0

					AND EXISTS (

						SELECT TOP 1 1

						FROM QORT_BACK_TDB.dbo.Phases q WITH (NOLOCK)

						WHERE q.IsProcessed IN (

								1

								,2

								)

						)

					)

			BEGIN

				WAITFOR DELAY '00:00:03'



				SET @WaitCount = @WaitCount - 1

			END



			SET @n = @n + 1

		END



		/*	--------------------------------загружаем фазы прологации по оплатам-------------------

		Insert into QORT_BACK_TDB.dbo.phases (

			IsProcessed

			, ET_Const

			, AgreeNum

			, PC_Const

			, date

			, SystemID

			, BackID

			, InfoSource

			, Trade_SID

			, QtyBefore

			, SubAcc_Code

			, DateAfter

			--, DateBefore

			, NewRepoRateDate

			, QtyAfter

			)

--*/

		SELECT cast(SUBSTRING(tt.Agrement, CHARINDEX('/', tt.Agrement) + 1, LEN(tt.Agrement)) AS INT) AS RowNum

			,1 AS IsProcessed

			,2 AS ET_Const

			,tt.agrement

			,13 PC_Const

			,CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DATE

			,(- 1) AS SystemID

			,tt.agrement + '_' + CAST(isnull(trad.id, '') AS VARCHAR(16)) AS BackID

			,NULL AS InfoSource

			,trad.id Trade_SID

			,0 AS QtyBefore

			,Sub.SubAccCode AS SubAcc_Code

			,CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			,CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) NewRepoRateDate

			,tt.Rate QtyAfter

		INTO #t8

		FROM #t tt

		--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

		OUTER APPLY (

			SELECT TOP 1 ass.ShortName

				,trad1.id

				,trad1.SubAcc_ID

			FROM QORT_BACK_DB..Trades trad1

			LEFT OUTER JOIN QORT_BACK_DB..Securities sec ON sec.id = trad1.Security_ID

			LEFT OUTER JOIN QORT_BACK_DB..Assets ass ON ass.id = sec.Asset_ID

			WHERE trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

				AND Trad1.VT_Const NOT IN (

					12

					,10

					) -- сделка не расторгнута

				AND trad1.NullStatus = 'n'

				AND trad1.Enabled = 0

				AND trad1.IsDraft = 'n'

				AND trad1.IsProcessed = 'y'

				AND trad1.IsRepo2 = 'y'

				AND ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

			) trad

		LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = trad.SubAcc_ID

		WHERE tt.Agrement LIKE '%R/%'

			--and left(Agrement,3) = @Nom --+ '-24R/1'

			--and right(tt.DataFirst,7) = '09/2024' 

			--and LEFT(tt.agrement,3) = '518'

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Phases a

				WHERE (

						tt.Agrement + '_' + cast(isnull(trad.id, '') AS VARCHAR(16)) = a.BackID

						OR a.BackID = tt.Agrement

						)

					AND a.Enabled = 0

					AND a.IsCanceled = 'n'

					AND a.PC_Const = 13

				)

		ORDER BY tt.Agrement ASC



		SELECT *

		FROM #t8



		SET @MaxRow = (

				SELECT MAX(rownum)

				FROM #t8

				)

		SET @n = 1



		WHILE @n <= @MaxRow

		BEGIN

			--/*

			INSERT INTO QORT_BACK_TDB.dbo.phases (

				IsProcessed

				,ET_Const

				,AgreeNum

				,PC_Const

				,DATE

				,SystemID

				,BackID

				,InfoSource

				,Trade_SID

				,QtyBefore

				,SubAcc_Code

				,DateAfter

				--, DateBefore

				,NewRepoRateDate

				,QtyAfter

				)

			--*/

			SELECT IsProcessed

				,ET_Const

				,Agrement AgreeNum

				,PC_Const

				,DATE

				,SystemID

				,BackID

				,InfoSource

				,Trade_SID

				,QtyBefore

				,SubAcc_Code

				,DateAfter

				--, DateBefore

				,NewRepoRateDate

				,QtyAfter

			FROM #t8

			WHERE RowNum = @n



			SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили----------------------



			WHILE (

					@WaitCount > 0

					AND EXISTS (

						SELECT TOP 1 1

						FROM QORT_BACK_TDB.dbo.Phases q WITH (NOLOCK)

						WHERE q.IsProcessed IN (

								1

								,2

								)

						)

					)

			BEGIN

				WAITFOR DELAY '00:00:03'



				SET @WaitCount = @WaitCount - 1

			END



			SET @n = @n + 1

		END



		--/*	--------------------------------загружаем фазы промежуточных выплат процентов-------------------

		INSERT INTO QORT_BACK_TDB.dbo.phases (

			IsProcessed

			,ET_Const

			,AgreeNum

			,PC_Const

			,DATE

			,SystemID

			,BackID

			,InfoSource

			,Trade_SID

			,QtyBefore

			,SubAcc_Code

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			,QtyAfter

			)

		--*/

		SELECT 1 AS IsProcessed

			,2 AS ET_Const

			,tt.agrement

			,5 PC_Const

			,CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) + RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DATE

			,(- 1) AS SystemID

			,tt.agrement + '_' + CAST(isnull(trad.id, '') AS VARCHAR(16)) AS BackID

			,NULL AS InfoSource

			,trad.id Trade_SID

			,round(tt1.VolPercent, 2) AS QtyBefore

			,Sub.SubAccCode AS SubAcc_Code

			--, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			--, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) NewRepoRateDate

			,(- 1) QtyAfter

		FROM #t tt

		--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

		OUTER APPLY (

			SELECT TOP 1 ass.ShortName

				,trad1.id

				,trad1.SubAcc_ID

			FROM QORT_BACK_DB..Trades trad1

			LEFT OUTER JOIN QORT_BACK_DB..Securities sec ON sec.id = trad1.Security_ID

			LEFT OUTER JOIN QORT_BACK_DB..Assets ass ON ass.id = sec.Asset_ID

			WHERE trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

				AND Trad1.VT_Const NOT IN (

					12

					,10

					) -- сделка не расторгнута

				AND trad1.NullStatus = 'n'

				AND trad1.Enabled = 0

				AND trad1.IsDraft = 'n'

				AND trad1.IsProcessed = 'y'

				AND trad1.IsRepo2 = 'y'

				AND ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

			) trad

		OUTER APPLY (

			SELECT TOP 1 *

			FROM #t tt1

			WHERE tt1.Dataleg2 = tt.Dataleg1

				AND left(tt1.Agrement, 6) = left(tt.Agrement, 6)

			) tt1

		LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = trad.SubAcc_ID

		WHERE tt.Agrement LIKE '%R/%'

			--and left(tt.Agrement,3) = @Nom 

			--and right(tt.DataFirst,7) = '09/2024' 

			--and LEFT(tt.agrement,3) = '518'

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Phases a

				WHERE (

						tt.Agrement + '_' + cast(isnull(trad.id, '') AS VARCHAR(16)) = a.BackID

						OR a.BackID = tt.Agrement

						)

					AND a.Enabled = 0

					AND a.IsCanceled = 'n'

					AND a.PC_Const = 5

				)



		--/*	---------------------------------формируем full delivery/payment под вторые ноги у которых дата исполнения вчера, а пролонгации не было.

		INSERT INTO QORT_BACK_TDB.dbo.phases (

			IsProcessed

			,ET_Const

			,AgreeNum

			,PC_Const

			,DATE

			,SystemID

			,BackID

			,InfoSource

			,Trade_SID

			,QtyBefore

			,SubAcc_Code

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			,QtyAfter

			)

		--*/

		SELECT 1 AS IsProcessed

			,2 AS ET_Const

			,AgreeNum AS AgreeNum

			,4 AS PC_Const

			,PutPlannedDate AS DATE

			,(- 1) AS SystemID

			,trad.AgreeNum + '_' + CAST(isnull(trad.id, '') AS VARCHAR(16)) AS backID

			,NULL AS InfoSource

			,id AS Trade_SID

			,Qty AS QtyBefore

			,'ARMBR_Subacc' AS SubAcc_Code

			,(- 1) AS QtyAfter

		FROM QORT_BACK_DB..Trades trad

		WHERE Trad.VT_Const NOT IN (

				12

				,10

				) -- сделка не расторгнута

			AND trad.NullStatus = 'n'

			AND trad.Enabled = 0

			AND trad.IsDraft = 'n'

			AND trad.IsProcessed = 'y'

			AND Trad.TT_Const IN (6) -- OTC repo (6); Exchange repo (3)

			AND (

				Trad.PutDate = 0

				OR Trad.PayDate = 0

				)

			AND trad.PutPlannedDate < @todayInt

			AND trad.IsRepo2 = 'y'

			AND PayAccount_ID = 175 -- CB_RA_FOR_REPO

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Phases a

				WHERE (

						a.BackID = trad.AgreeNum collate Cyrillic_General_CI_AS

						OR a.BackID = trad.AgreeNum + '_' + cast(trad.id AS VARCHAR(16)) collate Cyrillic_General_CI_AS

						)

					AND a.Enabled = 0

					AND a.IsCanceled = 'n'

					AND a.PC_Const = 4

				)



		--and trad.id = 17556

		SELECT *

		FROM QORT_BACK_TDB.dbo.Phases

		WHERE ModifiedDate = @todayInt

			AND IsProcessed IN (

				1

				,2

				)

			AND PC_Const = 4



		SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили----------------------



		WHILE (

				@WaitCount > 0

				AND EXISTS (

					SELECT TOP 1 1

					FROM QORT_BACK_TDB.dbo.Phases q WITH (NOLOCK)

					WHERE q.IsProcessed IN (

							1

							,2

							)

					)

				)

		BEGIN

			WAITFOR DELAY '00:00:03'



			SET @WaitCount = @WaitCount - 1

		END



		--/*

		INSERT INTO QORT_BACK_TDB.dbo.phases (

			IsProcessed

			,ET_Const

			,AgreeNum

			,PC_Const

			,DATE

			,SystemID

			,BackID

			,InfoSource

			,Trade_SID

			,QtyBefore

			,SubAcc_Code

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			,QtyAfter

			)

		--*/

		SELECT 1 AS IsProcessed

			,2 AS ET_Const

			,AgreeNum AS AgreeNum

			,7 AS PC_Const

			,PayPlannedDate AS DATE

			,(- 1) AS SystemID

			,trad.AgreeNum + '_' + CAST(isnull(trad.id, '') AS VARCHAR(16)) AS backID

			,NULL AS InfoSource

			,id AS Trade_SID

			,Volume1 - isnull(pha.SumQty, 0) AS QtyBefore

			,'ARMBR_Subacc' AS SubAcc_Code

			,(- 1) AS QtyAfter

		--, isnull(pha.SumQty,0)

		FROM QORT_BACK_DB..Trades trad

		OUTER APPLY (

			SELECT SUM(pha.QtyBefore) AS SumQty

			FROM QORT_BACK_DB..Phases pha

			WHERE trad.id = pha.Trade_ID

				AND pha.IsCanceled = 'n'

				AND pha.PC_Const IN (5)

			) pha

		WHERE Trad.VT_Const NOT IN (

				12

				,10

				) -- сделка не расторгнута

			AND trad.NullStatus = 'n'

			AND trad.Enabled = 0

			AND trad.IsDraft = 'n'

			AND trad.IsProcessed = 'y'

			AND Trad.TT_Const IN (6) -- OTC repo (6); Exchange repo (3)

			AND (

				Trad.PutDate = 0

				OR Trad.PayDate = 0

				)

			AND trad.PutPlannedDate < @todayInt

			AND trad.IsRepo2 = 'y'

			AND PayAccount_ID = 175 -- CB_RA_FOR_REPO

			AND NOT EXISTS (

				SELECT TOP 1 *

				FROM QORT_BACK_DB.dbo.Phases a

				WHERE (

						a.BackID = trad.AgreeNum collate Cyrillic_General_CI_AS

						OR a.BackID = trad.AgreeNum + '_' + cast(trad.id AS VARCHAR(16)) collate Cyrillic_General_CI_AS

						)

					AND a.Enabled = 0

					AND a.IsCanceled = 'n'

					AND a.PC_Const = 7

				)

		--and trad.id = 17556

		ORDER BY backID



		SELECT *

		FROM QORT_BACK_TDB.dbo.Phases

		WHERE ModifiedDate = @todayInt

			AND IsProcessed IN (

				1

				,2

				)

			AND PC_Const = 7

	END TRY



	BEGIN CATCH

		-- Обработка исключений

		WHILE @@TRANCOUNT > 0

			ROLLBACK TRAN



		SET @Message = 'ERROR: ' + ERROR_MESSAGE();



		-- Вставка сообщения об ошибке в таблицу uploadLogs

		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs (

			logMessage

			,errorLevel

			)

		VALUES (

			@Message

			,1001

			);



		-- Возвращаем сообщение об ошибке

		SELECT @Message AS result

			,'STATUS' AS defaultTask

			,'red' AS color;

	END CATCH

END

