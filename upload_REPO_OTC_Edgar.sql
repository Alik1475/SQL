

-- exec QORT_ARM_SUPPORT.dbo.upload_REPO_OTC_Edgar @Nom = '404'



CREATE PROCEDURE [dbo].[upload_REPO_OTC_Edgar]

   -- @Nom varchar(12)

AS

BEGIN

    SET NOCOUNT ON;



    BEGIN TRY

			EXEC xp_cmdshell 'powershell.exe -File "C:\scripts\StartTask.ps1"';
			WAITFOR DELAY '00:01:00';

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

		IF OBJECT_ID('tempdb..#t10', 'U') IS NOT NULL DROP TABLE #t10

		IF OBJECT_ID('tempdb..#t9', 'U') IS NOT NULL DROP TABLE #t9

		IF OBJECT_ID('tempdb..#t8', 'U') IS NOT NULL DROP TABLE #t8

        IF OBJECT_ID('tempdb..##f', 'U') IS NOT NULL DROP TABLE ##f

        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t

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

            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',

            ''SELECT * FROM [' + @Sheet1 + '$A1:Q1000]'')'

        EXEC(@sql)

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

       delete FROM ##f where [F1] = '' or  [F1] = 0

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

    ISIN VARCHAR(50), 

	Qty float-- Укажите подходящий размер для поля ISIN

    , Volume FLOAT              -- Тип данных для объёма

    , Dataleg1 VARCHAR(16),

    Dataleg2 VARCHAR(16),

    Repoday INT,               -- Например, тип данных для дней

    DataFirst VARCHAR(16),

    Rate FLOAT                -- Процентная ставка, используйте FLOAT или другой подходящий тип

    , VolPercent FLOAT          -- Тип данных для процента объёма

    , CP VARCHAR(50),            -- Укажите размер для поля CP

    Agrement VARCHAR(16),

    Currency VARCHAR(3)        -- Размер для валютного кода (например, "USD", "EUR")

);







     INSERT INTO #t (

      ISIN

	, Qty

    , Volume

    , Dataleg1

    , Dataleg2

    , Repoday

    , DataFirst

    , Rate

    , VolPercent

    , CP

    , Agrement

    , Currency

)

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



		DECLARE @ISIN VARCHAR(16) = 'US0378331005'--'US87238U2033'--USY77108AA93

		DECLARE @BuySell int = 1 --2

		DECLARE @TSSEC VARCHAR(16) = 'ОТС_REPO'

		DECLARE @TradeDate int = 20240917

		DECLARE @Qty float = 5 -1-0

		DECLARE @FirmID int = 6 -- BCS Cyprus

		DECLARE @payCur varchar(16) = 'EUR' -- MXN

		DECLARE @payCurID int = (select top 1 id from QORT_BACK_DB..Assets where Name = 'EUR')



		----------------------добавление инструмента НА ПЛОЩАДКУ ОТС РЕПО ЕСЛИ НЕТ--------------------------

			--/*

			insert into QORT_BACK_TDB.dbo.Securities (

			IsProcessed, ET_Const, ShortName

			, Name, TSSection_Name, SecCode

			, Asset_ShortName, QuoteList, IsProcent

			, LotSize, IsTrading, Lot_multiplicity

			, Scale

			, CurrPriceAsset_ShortName

		) 

		--*/

		SELECT DISTINCT

		1 as IsProcessed, 2 as ET_Const

			, s.shortname

			, s.ISIN Name

			, 'ОТС_REPO' as TSSection_Name

			, s.ISIN  secCode

			, s.ShortName Asset_ShortName

			, 1 QuoteList

			, iif(s.AssetSort_Const in (6,3), 'y', NULL) IsProcent

			, 1 LotSize

			, 'y' IsTrading

			, 1 lot_multiplicity

			, 8 Scale

			, B.ShortName CurrPriceAsset_ShortName

		--into #t10 

		FROM #t ttt 

		left outer join QORT_BACK_DB.dbo.Assets s on ttt.isin = s.ISIN

		left join QORT_BACK_DB.dbo.Assets b on B.ID = s.BaseCurrencyAsset_ID and b.Enabled = 0 



		where s.Enabled = 0 

				and s.id is not null

		 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Securities a

				where a.Asset_ID = s.id and a.Enabled = 0 

				and a.TSSection_ID = 160 -- OTC_REPO

			)

			--select * from #t10-- return

			

		set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Securities q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end







--/*

Insert into QORT_BACK_TDB.dbo.ImportTrades (

			IsProcessed

			, ET_Const

			, IsDraft

			, TradeDate

			, TSSection_Name

			, BuySell

			, Security_Code

			, Qty

			, Price

			, BackPrice

			, Volume1

			, Volume2

			, CurrPriceAsset_ShortName, PutPlannedDate, PayPlannedDate

			, RepoDate2

			, BackDate

			, PutAccount_ExportCode, PayAccount_ExportCode, SubAcc_Code

			, AgreeNum, TT_Const, CpFirm_ShortName

			, Comment

			, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, PT_Const, TSCommission, IsAccrued

			, IsSynchronize--, CpSubacc_Code

			, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, CrossRate

			--, ExternalNum

			--, TradeNum

			, Discount

			, RepoRate

			--, QFlags

			--, PriceEx

			, RepoBasis 

			, CRT_Const

			, CrossRateDate

		) --*/



		

		SELECT 1 as IsProcessed

			, 2 as ET_Const

			, 'n' as IsDraft 

			, CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) TradeDate

			, 'ОТС_REPO'  TSSection_Name

			, IIF(t.agrement NOT LIKE '%HR%', 2, 1) BuySell 

			, isnull(sec.SecCode, 'unknow' + t.ISIN) Security_Code

			, t.Qty / ISNULL(ASS.basevalue, 1) Qty

			, t.Volume / isnull(t.Qty,1) * 100 * iif(assBC.name = t.Currency, 1 ,  IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid),1)) Price

			, (t.Volume + t.VolPercent) / isnull(t.Qty,1) * 100 * iif(assBC.name = t.Currency, 1 ,  IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid),1)) BackPrice

			, ROUND (t.Volume,2) Volume1

			, ROUND(t.Volume + t.VolPercent,2) Volume2

			, assbc.Name CurrPriceAsset_ShortName

			, CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) PutPlannedDate

			, CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) PayPlannedDate

			, CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) RepoDate2

			, CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) BackDate

			, iif((t.isin in ('XS2010043904', 'XS2080321198', 'XS2010028939') or t.CP in ('Trinfiko')), 'CLIENT_CDA_Own', 'CB_RA_FOR_REPO') PutAccount_ExportCode

			, 'Armbrok_Mn_OWN' PayAccount_ExportCode

			, 'ARMBR_Subacc' as SubAcc_Code

			, t.Agrement AgreeNum

			, 6 TT_Const --OTC repo

			, case

					when t.CP = 'HSBC' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00885')

			        when t.CP = 'Trinfiko' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00804') 

					when t.CP = 'Armswissbank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00035')

					when t.CP = 'Artsakhbank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '01146')

					when t.CP = 'Acba' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00018')

					when t.CP = 'ArmEconombank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00033')

					when t.CP = 'ABB' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00032') --amio bank

					when t.CP = 'Anelik' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00347')

					when t.CP = 'Ardshininvestbank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00029')

					when t.CP = 'Ameriabank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00025')

					when t.CP = 'Prometeybank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00059') --evoca bank

					when t.CP = 'Araratbank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00028') 

					when t.CP = 'Fastbank' then (Select FirmShortName from QORT_BACK_DB..Firms where BOCode = '00064') 

						  else 'unknow_' + t.CP 

						  end

							  CpFirm_ShortName		

			, 'autoload' Comment

			, CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2)) AgreePlannedDate

			, 0 Accruedint

			--, uTrader.id TraderUser_ID

			--, uSales.id SalesManager_ID

			, IIF(sec.IsProcent = 'y',1,2) PT_Const

			, 0 TSCommission

			, 'n' IsAccrued

			, 'n' IsSynchronize

			--, d.[Counterparty Subaccount] CpSubacc_Code

			, 1 SS_Const -- вид оасчетов

			, 0 FunctionType -- функциональный тип

			, t.Currency CurrPayAsset_ShortName

			, isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid),1) / isnull(IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid),1) CrossRate

			--, isnull(cast(d.AgreeMent as varchar), 'N/A') ExternalNum

			--, @TradeDate + ass.id

			, 0 Discount

			, t.Rate RepoRate

			--, 562949953421312 qflags

			--, 123 PriceEx-- Open REPO trade

			, iif(right(t.agrement,3) = '24R' , 7 , 3) RepoBasis -- 7-TBT_ACT_366/ 3-TBT_ACT_365 

			, iif(assbc.Name = t.currency, 1, 1) CRT_Const

			, iif(assbc.Name = t.currency, 0,CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))) CrossRateDate

		FROM #t t



		      OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB.dbo.Assets ass

            WHERE ass.ISIN = t.ISIN

            AND ass.Enabled = 0 		

        ) AS ass

		      OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB.dbo.Securities  sec

            WHERE sec.Asset_ID =  ass.id

            AND sec.Enabled = 0 	

			and sec.TSSection_ID = (Select top 1 ID from QORT_BACK_DB..TSSections where name = 'ОТС_REPO')

        ) AS sec

		        OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB..CrossRatesHist crs 

            WHERE 

                crs.TradeAsset_ID = ass.BaseCurrencyAsset_ID

                AND crs.Date = CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsAS

				        OUTER APPLY (

            SELECT TOP 1 crs.Bid

            FROM QORT_BACK_DB..CrossRatesHist crs 

			left outer join QORT_BACK_DB..Assets aaa on aaa.Name = t.Currency and aaa.Enabled = 0

            WHERE 

                crs.TradeAsset_ID = aaa.id

                AND crs.Date = CONVERT(INT, SUBSTRING(t.DataFirst, 7, 4) +  RIGHT('0' + SUBSTRING(t.DataFirst, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.DataFirst, 1, 2), 2))

                AND crs.PriceAsset_ID = 17

                AND InfoSource = 'CBA'

        ) crsTr

		--left join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.Asset_ID =  ass.id and sec.TSSection_ID = (Select top 1 ID from QORT_BACK_DB..TSSections where name = 'ОТС_REPO')-- @TSSEC)

		--left join QORT_BACK_DB.dbo.MarketInfoHist mrk with (nolock) on mrk.Asset_ID = ass.id and mrk.OldDate = @TradeDate

		left join QORT_BACK_DB.dbo.Assets assBC with (nolock) on assBC.ID = ass.BaseCurrencyAsset_ID

		

		--left join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPut with (nolock) on aPut.AccountCode = d.DeliveryAccount collate Cyrillic_General_CS_AS

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPay with (nolock) on aPay.AccountCode = d.[Payment Account] collate Cyrillic_General_CS_AS

		WHERE t.Agrement NOT LIKE '%/%'

		and sec.SecCode is not null

		and right(t.agrement,1) = 'R'

		--and CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) > 20231231

		and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Trades tr

				where tr.AgreeNum like t.Agrement collate Cyrillic_General_CS_AS

			      AND Tr.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND tr.NullStatus = 'n'

         AND tr.Enabled = 0

          AND tr.IsDraft = 'n'

          AND tr.IsProcessed = 'y'

		  

			)

			

			order by AgreeNum --return



			select * from QORT_BACK_TDB.dbo.ImportTrades where ImportInsertDate = @todayInt and IsProcessed in (1,2) order by AgreeNum



			set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили сделки----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.ImportTrades q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

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

			select cast(SUBSTRING(tt.Agrement, CHARINDEX('/', tt.Agrement) + 1, LEN(tt.Agrement)) as int) AS RowNum

			,  1 as IsProcessed

			, 2 as ET_Const

			, tt.agrement 

			, 14 PC_Const

			, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) date

			, (-1) as SystemID

			, tt.agrement +'_' + CAST(isnull(trad.id,'') as varchar(16)) as BackID

			, null as InfoSource

			, trad.id Trade_SID

			, 0 as QtyBefore

			, Sub.SubAccCode as SubAcc_Code

			, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) NewRepoRateDate

			,  tt.Rate QtyAfter

			, trad.shortname

			into #t9

			from #t tt

			--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

			

			        OUTER APPLY (

            SELECT top 1  ass.ShortName, trad1.id, trad1.SubAcc_ID

            FROM QORT_BACK_DB..Trades trad1 

			left outer join QORT_BACK_DB..Securities sec on sec.id = trad1.Security_ID
			left outer join QORT_BACK_DB..Assets ass on ass.id = sec.Asset_ID

			WHERE 

                trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

                  AND Trad1.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad1.NullStatus = 'n'

         AND trad1.Enabled = 0

          AND trad1.IsDraft = 'n'

          AND trad1.IsProcessed = 'y'

		  and trad1.IsRepo2 = 'y'

		  and ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

        ) trad

		left outer join QORT_BACK_DB..Subaccs sub on sub.id = trad.SubAcc_ID

		

		WHERE tt.Agrement LIKE '%R/%'

		--and left(Agrement,3) = @Nom --+ '-24R/1'

		--and right(tt.DataFirst,7) = '09/2024' 

		--and LEFT(tt.agrement,3) = '518'

		 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Phases a

				where (tt.Agrement + '_' + cast(isnull(trad.id,'') as varchar(16)) = a.BackID  or a.BackID = tt.Agrement)

				and a.Enabled = 0 and a.IsCanceled = 'n' 

				and a.PC_Const = 14

			)

			order by tt.Agrement asc



select * from #t9 --return



			set @MaxRow = (select MAX(rownum) from #t9)	

			set @n = 1

			while @n <= @MaxRow

begin







--/*	--------------------------------загружаем фазы прологации по поставкам активов через цикл-------------------

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

		select IsProcessed

			, ET_Const

			, agrement AgreeNum

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

		

		from #t9

		where RowNum = @n



		set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили фазы по пролонгации по активам----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Phases q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end



		set @n = @n + 1



	end

	



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

			select cast(SUBSTRING(tt.Agrement, CHARINDEX('/', tt.Agrement) + 1, LEN(tt.Agrement)) as int) AS RowNum

			,  1 as IsProcessed

			, 2 as ET_Const

			, tt.agrement 

			, 13 PC_Const

			, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) date

			, (-1) as SystemID

			, tt.agrement +'_' + CAST(isnull(trad.id,'') as varchar(16)) as BackID

			, null as InfoSource

			, trad.id Trade_SID

			, 0 as QtyBefore

			, Sub.SubAccCode as SubAcc_Code

			, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) NewRepoRateDate

			,  tt.Rate QtyAfter

			INTO #t8

			from #t tt

			--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

						        OUTER APPLY (

            SELECT top 1  ass.ShortName, trad1.id, trad1.SubAcc_ID

            FROM QORT_BACK_DB..Trades trad1 

			left outer join QORT_BACK_DB..Securities sec on sec.id = trad1.Security_ID

			left outer join QORT_BACK_DB..Assets ass on ass.id = sec.Asset_ID

			WHERE 

                trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

                  AND Trad1.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad1.NullStatus = 'n'

         AND trad1.Enabled = 0

          AND trad1.IsDraft = 'n'

          AND trad1.IsProcessed = 'y'

		  and trad1.IsRepo2 = 'y'

		  and ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

        ) trad

		left outer join QORT_BACK_DB..Subaccs sub on sub.id = trad.SubAcc_ID

		

		WHERE tt.Agrement LIKE '%R/%'

		--and left(Agrement,3) = @Nom --+ '-24R/1'

		--and right(tt.DataFirst,7) = '09/2024' 

		--and LEFT(tt.agrement,3) = '518'

		 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Phases a

				where ( tt.Agrement + '_' + cast(isnull(trad.id,'') as varchar(16)) = a.BackID or a.BackID = tt.Agrement)

				and a.Enabled = 0 and a.IsCanceled = 'n' 

				and a.PC_Const = 13

			)

			order by tt.Agrement asc

			select * from #t8 

			set @MaxRow = (select MAX(rownum) from #t8)	

			set @n = 1

			while @n <= @MaxRow



begin

--/*

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

			select 

			IsProcessed

			, ET_Const

			, Agrement AgreeNum

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

			from #t8

			where RowNum = @n



				set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Phases q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end



		set @n = @n + 1



	end

	

	

		--/*	--------------------------------загружаем фазы промежуточных выплат процентов-------------------

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

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			, QtyAfter

			)

--*/

			select 

			 1 as IsProcessed

			, 2 as ET_Const

			, tt.agrement 

			, 5 PC_Const

			, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) date

			, (-1) as SystemID

			, tt.agrement +'_' + CAST(isnull(trad.id,'') as varchar(16)) as BackID

			, null as InfoSource

			, trad.id Trade_SID

			, round(tt1.VolPercent, 2) as QtyBefore

			, Sub.SubAccCode as SubAcc_Code

			--, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) DateAfter

			--, CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) DateBefore

			--, CONVERT(INT, SUBSTRING(tt.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg2, 1, 2), 2)) NewRepoRateDate

			,  (-1) QtyAfter

			from #t tt

			--left join QORT_BACK_DB.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 

			

 OUTER APPLY (

            SELECT top 1  ass.ShortName, trad1.id, trad1.SubAcc_ID

            FROM QORT_BACK_DB..Trades trad1 

			left outer join QORT_BACK_DB..Securities sec on sec.id = trad1.Security_ID

			left outer join QORT_BACK_DB..Assets ass on ass.id = sec.Asset_ID

			WHERE 

                trad1.AgreeNum = LEFT(tt.agrement, CHARINDEX('/', tt.agrement) - 1) collate Cyrillic_General_CS_AS

                  AND Trad1.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad1.NullStatus = 'n'

         AND trad1.Enabled = 0

          AND trad1.IsDraft = 'n'

          AND trad1.IsProcessed = 'y'

		  and trad1.IsRepo2 = 'y'

		  and ass.ISIN = tt.ISIN collate Cyrillic_General_CS_AS

        ) trad

			        OUTER APPLY (

            SELECT top 1 *

            FROM #t tt1	

            WHERE 

                tt1.Dataleg2 = tt.Dataleg1

				and left(tt1.Agrement,6) = left(tt.Agrement,6)

        ) tt1

		left outer join QORT_BACK_DB..Subaccs sub on sub.id = trad.SubAcc_ID



		WHERE tt.Agrement LIKE '%R/%'

		--and left(tt.Agrement,3) = @Nom 

		--and right(tt.DataFirst,7) = '09/2024' 

		--and LEFT(tt.agrement,3) = '518'

			 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Phases a

				where (tt.Agrement + '_' + cast(isnull(trad.id,'') as varchar(16)) = a.BackID or a.BackID = tt.Agrement)

				and a.Enabled = 0 and a.IsCanceled = 'n' 

				and a.PC_Const = 5

			)



		--/*	---------------------------------формируем full delivery/payment под вторые ноги у которых дата исполнения вчера, а пролонгации не было.

			

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

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			, QtyAfter)

			--*/

			select 

			 1 as IsProcessed

			, 2 as ET_Const

			, AgreeNum as AgreeNum

			, 4 as PC_Const

			, PutPlannedDate as date

			, (-1) as SystemID

			, trad.AgreeNum +'_' + CAST(isnull(trad.id,'') as varchar(16)) as backID

			, Null as InfoSource

			, id as Trade_SID

			, Qty as QtyBefore

			, 'ARMBR_Subacc' as SubAcc_Code

			, (-1) as QtyAfter

			from QORT_BACK_DB..Trades trad 

			where Trad.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad.NullStatus = 'n'

          AND trad.Enabled = 0

          AND trad.IsDraft = 'n'

          AND trad.IsProcessed = 'y'

          AND Trad.TT_Const IN (6) -- OTC repo (6); Exchange repo (3)

          AND (Trad.PutDate = 0 or Trad.PayDate = 0)

		  and trad.PutPlannedDate < @todayInt

		  and trad.IsRepo2 = 'y'

		  and PayAccount_ID = 175 -- CB_RA_FOR_REPO

		  	 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Phases a

				where (a.BackID = trad.AgreeNum collate Cyrillic_General_CI_AS or a.BackID = trad.AgreeNum +'_' + cast(trad.id as varchar(16)) collate Cyrillic_General_CI_AS)

				and a.Enabled = 0 and a.IsCanceled = 'n' 

				and a.PC_Const = 4

			)

			--and trad.id = 17556



			select * from QORT_BACK_TDB.dbo.Phases where ModifiedDate = @todayInt and IsProcessed in (1,2) and PC_Const = 4



							set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Phases q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

			--/*

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

			--, DateAfter

			--, DateBefore

			--, NewRepoRateDate

			, QtyAfter)

			--*/

			select 

			 1 as IsProcessed

			, 2 as ET_Const

			, AgreeNum as AgreeNum

			, 7 as PC_Const

			, PayPlannedDate as date

			, (-1) as SystemID

			, trad.AgreeNum +'_' + CAST(isnull(trad.id,'') as varchar(16))  as backID

			, Null as InfoSource

			, id as Trade_SID

			, Volume1 - isnull(pha.SumQty,0) as QtyBefore

			, 'ARMBR_Subacc' as SubAcc_Code

			, (-1) as QtyAfter

			--, isnull(pha.SumQty,0)

			from QORT_BACK_DB..Trades trad 

			OUTER APPLY (

						SELECT SUM(pha.QtyBefore) AS SumQty

						FROM QORT_BACK_DB..Phases pha

						WHERE 

							trad.id = pha.Trade_ID

							and pha.IsCanceled = 'n'

							and pha.PC_Const in (5)

					) pha

			where Trad.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad.NullStatus = 'n'

          AND trad.Enabled = 0

          AND trad.IsDraft = 'n'

          AND trad.IsProcessed = 'y'

          AND Trad.TT_Const IN (6) -- OTC repo (6); Exchange repo (3)

          AND (Trad.PutDate = 0 or Trad.PayDate = 0)

		  and trad.PutPlannedDate < @todayInt

		  and trad.IsRepo2 = 'y'

		  and PayAccount_ID = 175 -- CB_RA_FOR_REPO

		  	 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB.dbo.Phases a

				where (a.BackID = trad.AgreeNum collate Cyrillic_General_CI_AS or a.BackID = trad.AgreeNum +'_' + cast(trad.id as varchar(16)) collate Cyrillic_General_CI_AS)

				and a.Enabled = 0 and a.IsCanceled = 'n' 

				and a.PC_Const = 7

			)

			--and trad.id = 17556

			order by backID

			select * from QORT_BACK_TDB.dbo.Phases where ModifiedDate = @todayInt and IsProcessed in (1,2) and PC_Const = 7

    END TRY

    BEGIN CATCH

        -- Обработка исключений

        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN

        SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 

        -- Вставка сообщения об ошибке в таблицу uploadLogs

        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);

        -- Возвращаем сообщение об ошибке

        SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;

    END CATCH



END
