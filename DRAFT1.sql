
-- exec QORT_ARM_SUPPORT_TEST.dbo.DRAFT1 @SendMail = 0

CREATE PROCEDURE [dbo].[DRAFT1]
    @SendMail BIT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Объявление переменных
        
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @
todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
        DECLARE @WaitCount INT
        DECLARE @Message VARCHAR(1024)
        DECLARE @Result VARCHAR(128) 
        DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCT
ION\DealsRepo\DealsR.xlsx'
        DECLARE @NotifyEmail VARCHAR(1024) = 'aleksandr.mironov@armbrok.am'
        DECLARE @Sheet1 VARCHAR(64) = 'Sheet1' 
        DECLARE @sql VARCHAR(1024)

        -- Удаляем временные таблицы, если они существуют
        IF
 OBJECT_ID('tempdb..##f', 'U') IS NOT NULL DROP TABLE ##f
        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t
        IF OBJECT_ID('tempdb..#result', 'U') IS NOT NULL DROP TABLE #result

        -- Подготовка запроса для импорта данных из Ex
cel-файла в временную таблицу ##f
        SET @sql = 'SELECT * INTO ##f
        FROM OPENROWSET (
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0; Database='+ @FileName + '; HDR=NO;IMEX=1'',
            ''SELECT * FROM [' + @Sheet1 + '$
A1:Q500]'')'

        EXEC(@sql)

        -- Проверка данных из Excel-файла
       delete FROM ##f where [F1] = '' --or  [F1] = 0

		select * from ##f order by [F14] --return
        -- Забираем значения из файла Excel, в который подгружаются данные из Bl
oomberg
		CREATE TABLE #t (

    ISIN VARCHAR(50), 

	Qty float,-- Укажите подходящий размер для поля ISIN

    Volume FLOAT,              -- Тип данных для объёма

    Dataleg1 VARCHAR(16),

    Dataleg2 VARCHAR(16),

    Repoday INT,               -- Например, тип данных для дней

    DataFirst VARCHAR(16),

    Rate FLOAT,                -- Процентная ставка, используйте FLOAT или другой подходящий тип

    VolPercent FLOAT,          -- Тип данных для процента объёма

    CP VARCHAR(50),            -- Укажите размер для поля CP

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

WHERE ISNULL(f.[F14], '0') <> '0';


         

        -- Проверка и вывод данных из временной таблицы #t
        SELECT * FROM #t 
		where right(DataFirst,7) = '10/2024' 
		ORDER BY Dataleg1


		DECLARE @ISIN VARCHAR(16) = 'US0378331005'--'US87238U2033'--USY77108AA93

		DECLARE @BuySell int = 1 --2

		DECLARE @TSSEC VARCHAR(16) = 'ОТС_REPO'

		DECLARE @TradeDate int = 20240917

		DECLARE @Qty float = 5 -1-0

		DECLARE @FirmID int = 6 -- BCS Cyprus

		DECLARE @payCur varchar(16) = 'EUR' -- MXN

		DECLARE @payCurID int = (select top 1 id from QORT_BACK_DB_UAT..Assets where Name = 'EUR')



		----------------------добавление инструмента НА ПЛОЩАДКУ ОТС РЕПО ЕСЛИ НЕТ--------------------------

			--/*

			insert into QORT_BACK_TDB_UAT.dbo.Securities (

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

		FROM #t ttt 

		left outer join QORT_BACK_DB_UAT.dbo.Assets s on ttt.isin = s.ISIN

		left join QORT_BACK_DB_UAT.dbo.Assets b on B.ID = s.BaseCurrencyAsset_ID and b.Enabled = 0 



		where s.Enabled = 0 

				and s.id is not null

		 and NOT EXISTS (
				select TOP 1 *
				from QORT_BACK_DB_UAT.dbo.Securities a
				where a.Asset_ID = s.id and a.Enabled = 0 
				and a.TSSection_ID = 160 -- OTC_REPO
			)

		set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_UAT.dbo.Securities q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

--return

/*

Insert into QORT_BACK_TDB_UAT.dbo.ImportTrades (

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

			--, CrossRate

			--, ExternalNum

			--, TradeNum

			, Discount

			, RepoRate

			--, QFlags

			--, PriceEx

		) --*/



		

		SELECT 1 as IsProcessed

			, 2 as ET_Const

			, 'n' as IsDraft 

			, CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) TradeDate

			, 'ОТС_REPO'  TSSection_Name

			, IIF(t.agrement NOT LIKE '%R%', 1, 2) BuySell

			, isnull(sec.SecCode, 'unknow' + t.ISIN) Security_Code

			, t.Qty / ISNULL(ASS.basevalue, 1) Qty

			, t.Volume / isnull(t.Qty,1) * 100 * iif(assBC.name = t.Currency, 1 ,  IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid),1)) Price

			, (t.Volume + t.VolPercent) / isnull(t.Qty,1) * 100 * iif(assBC.name = t.Currency, 1 ,  IIF(assBC.BaseCurrencyAsset_ID = 17, 1, crsTr.Bid) / isnull(IIF(ass.BaseCurrencyAsset_ID = 17, 1, crsAS.Bid),1)) BackPrice

			, ROUND (t.Volume,2) Volume1

			, ROUND(t.Volume + t.VolPercent,2) Volume2

			, t.Currency CurrPriceAsset_ShortName

			, CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) PutPlannedDate

			, CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) PayPlannedDate

			, CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) RepoDate2

			, CONVERT(INT, SUBSTRING(t.Dataleg2, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg2, 1, 2), 2)) BackDate

			, 'ARMBR_DEPO' PutAccount_ExportCode

			, 'Armbrok_Mn_OWN' PayAccount_ExportCode

			, 'ARMBR_Subacc' SubAcc_Code

			, t.Agrement AgreeNum

			, 6 TT_Const --OTC repo

			, case

					when t.CP = 'HSBC' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00885')

			        when t.CP = 'Trinfiko' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00804') 

					when t.CP = 'Armswissbank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00035')

					when t.CP = 'Artsakhbank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '001146')

					when t.CP = 'Acba' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00018')

					when t.CP = 'ArmEconombank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00033')

					when t.CP = 'ABB' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00032') --amio bank

					when t.CP = 'Anelik' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00347')

					when t.CP = 'Ardshininvestbank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00029')

					when t.CP = 'Ameriabank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00025')

					when t.CP = 'Prometeybank' then (Select Name from QORT_BACK_DB_UAT..Firms where BOCode = '00059') --evoca bank

						  else 'unknow_' + t.CP 

						  end

							  CpFirm_ShortName		

			, 'autoload' Comment

			, CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) AgreePlannedDate

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

			--, (Select Top 1 bid from QORT_BACK_DB_UAT..CrossRates cro where cro.tradeasset_id = @payCurID) / ISNULL((Select Top 1 bid from QORT_BACK_DB_UAT..CrossRates cro where cro.tradeasset_id = assBC.Name),1) CrossRate

			--, isnull(cast(d.AgreeMent as varchar), 'N/A') ExternalNum

			--, @TradeDate + ass.id

			, 0 Discount

			, t.Rate RepoRate

			--, 67108864 qflags

			--, 123 PriceEx-- Open REPO trade

		FROM #t t



		      OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB_UAT.dbo.Assets ass

            WHERE ass.ISIN = t.ISIN

            AND ass.Enabled = 0 		

        ) AS ass

		      OUTER APPLY (

            SELECT TOP 1 *

            FROM QORT_BACK_DB_UAT.dbo.Securities  sec

            WHERE sec.Asset_ID =  ass.id

            AND sec.Enabled = 0 	

			and sec.TSSection_ID = (Select top 1 ID from QORT_BACK_DB_UAT..TSSections where name = 'ОТС_REPO')

        ) AS sec

		        OUTER APPLY (
            SELECT TOP 1 *
            FROM QORT_BACK_DB_UAT..CrossRatesHist crs 
            WHERE 
                crs.TradeAsset_ID = ass.BaseCurrencyAsset_ID
                AND crs.OldDate = CONVERT(INT, SUBSTRING(t.Dataleg1, 
7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2))
                AND crs.PriceAsset_ID = 17
                AND InfoSource = 'CBA'
        ) crsAS

				        OUTER APPLY (
            SELECT TOP 1 crs.Bid
            FROM QORT_BACK_DB_UAT..CrossRatesHist crs 
			left outer join QORT_BACK_DB_UAT..Assets aaa on aaa.Name = t.Currency and aaa.Enabled = 0
            WHERE 
                crs.TradeAsse
t_ID = aaa.id
                AND crs.OldDate = CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2))
                AND crs.PriceAsset_ID = 17
                AND InfoSour
ce = 'CBA'
        ) crsTr

		--left join QORT_BACK_DB_UAT.dbo.Securities sec with (nolock) on sec.Asset_ID =  ass.id and sec.TSSection_ID = (Select top 1 ID from QORT_BACK_DB_UAT..TSSections where name = 'ОТС_REPO')-- @TSSEC)

		--left join QORT_BACK_DB_UAT.dbo.MarketInfoHist mrk with (nolock) on mrk.Asset_ID = ass.id and mrk.OldDate = @TradeDate

		left join QORT_BACK_DB_UAT.dbo.Assets assBC with (nolock) on assBC.ID = ass.BaseCurrencyAsset_ID

		

		--left join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPut with (nolock) on aPut.AccountCode = d.DeliveryAccount collate Cyrillic_General_CS_AS

		--left join QORT_BACK_DB_TEST.dbo.Accounts aPay with (nolock) on aPay.AccountCode = d.[Payment Account] collate Cyrillic_General_CS_AS

		WHERE t.Agrement NOT LIKE '%/%'
		--and right(t.DataFirst,7) = '09/2024' 
		--and LEFT(t.agrement,3) = '518'
		and CONVERT(INT, SUBSTRING(t.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(t.Dataleg1, 1, 2), 2)) > 
20240930
		and NOT EXISTS (
				select TOP 1 *
				from QORT_BACK_DB_UAT.dbo.Trades tr
				where tr.AgreeNum like t.Agrement collate Cyrillic_General_CS_AS
			      AND Tr.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND tr.NullStatus = 'n'

         AND tr.Enabled = 0

          AND tr.IsDraft = 'n'

          AND tr.IsProcessed = 'y'
		  
			)

	/*	
		Insert into QORT_BACK_TDB_UAT.dbo.phases (
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
			)
--*/
			select 
			 1 as IsProcessed
			, 2 as ET_Const
			, tt.agrement 
			, 4 PC_Const
			, 20241001 date 
--CONVERT(INT, SUBSTRING(tt.Dataleg1, 7, 4) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 4, 2), 2) +  RIGHT('0' + SUBSTRING(tt.Dataleg1, 1, 2), 2)) date
			, (-1) as SystemID
			, '123' as BackID
			, null as InfoSource
			, trad.id Trade_SID
			, tt.Qty as QtyB
efore
			, Sub.SubAccCode as SubAcc_Code
			from #t tt
			--left join QORT_BACK_DB_UAT.dbo.Trades trad with (nolock) on trad.AgreeNum = tt.agrement 
			
			        OUTER APPLY (
            SELECT top 1 *
            FROM QORT_BACK_DB_UAT..Trades trad 
		
	
            WHERE 
                trad.AgreeNum = tt.agrement collate Cyrillic_General_CS_AS
                  AND Trad.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad.NullStatus = 'n'

         AND trad.Enabled = 0

          AND trad.IsDraft = 'n'

          AND trad.IsProcessed = 'y'
		  and trad.IsRepo2 = 'y'
        ) trad
		left outer join QORT_BACK_DB_UAT..Subaccs sub on sub.id = trad.SubAcc_ID

		WHERE tt.Agrement NOT LIKE '%/%'
		and right(tt.DataFirst,7) = '09/2024' 
		--and LEFT(tt.agrement
,3) = '518'



    END TRY
    BEGIN CATCH
        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 
        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QOR
T_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
        SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;
    END CATCH

END
