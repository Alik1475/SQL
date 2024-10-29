
-- exec QORT_ARM_SUPPORT_test..Draft
CREATE PROCEDURE [dbo].[DRAFT]
@Currency varchar(8) = 'EUR',

@MinTranAm int = 50,

@FirmID int = 725 -- BCS Cyprus

AS

BEGIN



	begin try

	

		SET NOCOUNT ON

		declare @todayDate date = getdate()



		declare @ytdDate date

		declare @n int = 0

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024)

		DECLARE @NotifyEmail VARCHAR(1024) = 'aleksandr.mironov@armbrok.am;aleksey.yudin@armbrok.am'--.sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am';

		--declare @TradeDateFrom int = cast(convert(varchar, dateadd(day, -1, @TradeDate), 112) as int)

		--declare @TradeDateFrom int = cast(convert(varchar, QORT_ARM_SUPPORT_TEST.dbo.fGetPrevBusinessDay(@todayInt), 112) as int)

		--declare @TradeDateTo int = cast(convert(varchar, @TradeDate, 112) as int)

		declare @TradeTimeFrom int = 160000000 --(16:00:00.000)

		declare @ArmBrokFirmShortName varchar(16) = 'Armbrok OJSC'

		declare @CalcBasis int;

		set @CalcBasis = 

			CASE 

			WHEN @Currency = 'GBR' THEN 365

			WHEN @Currency = 'RUB' THEN 365

			ELSE 360

			END





		        -- Определяем вчерашний рабочий день

			

        WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, @todayDate)) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

        SET @ytdDate = (DATEADD(DAY, -1-@n, @todayDate)) -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);

        declare @ytdDatevarch varchar(32) = CONVERT(VARCHAR, @ytdDate, 112);

		

		

		--declare @TradeDateToTXT varchar(32) = QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(@todayInt)



		declare @sql nvarchar(max)

		/*declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\test_42000_NY06_workTemplate.xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\temp\42000_NY06_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY06_'+cast(@TradeDateTo as varchar)+'.xls'*/

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\Collateral.xlsx'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\archive\Collateral.xlsx'+cast(@todayInt as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx
'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\Collateral_'+cast(@todayInt as varchar)+'.xlsx'

		declare @Sheet1 varchar(32) = 'Sheet1'

		declare @Sheet2 varchar(32) = 'Sheet2'



		declare @res table(r varchar(255))

		declare @cmd varchar(512)



		declare @execres varchar(1024)

		--/*

		set @cmd = 'copy "' + @TemplateFileName + '" "' + @TempFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @TempFileName

			RAISERROR (@execres, 16, 1);

		end

		--*/



		if OBJECT_ID('tempdb..#r', 'U') is not null drop table #r

		if OBJECT_ID('tempdb..##Template_01', 'U') is not null drop table ##Template_01

		if OBJECT_ID('tempdb..##Template_02', 'U') is not null drop table ##Template_02

		--print dbo.fCalculateDaysDiff(20240918) AS DaysDiff

		SELECT * FROM GetIncludedFlags (67108866);





		WITH CalculatedValues AS (

    SELECT 

        cast(isnull(frmCP.FirmShortName, 'unknow') as varchar(256)) as Account_A,

        asssec.ISIN as ISIN_B,

        iif(tra.BuySell = 2, 'Reverse Repo', 'Repo') as Side_C,

        asssec.Name as Security_Name_D,

        iif(sec.isprocent = 'y', cur.Name, curmrk.name) as Instrument_CCY_E,

        iif(sec.isprocent = 'y', crsBAS.bid/crs.Bid, crsEQ.bid/crs.bid) as FX_Rate_Instrument_CCY_Call_CCY_F,

        tra.TradeDate as Start_Date_G,

        iif((SELECT * FROM GetIncludedFlags (tra.QFlags) where flagname = 'QF_OPENREPO') is not null, 'OPEN', cast(tra.PayPlannedDate as varchar(36))) as End_Date_H,

        iif(sec.isprocent = 'y', tra.Qty * asssec.BaseValue, tra.Qty) as Face_amount_I,

        iif(tra.BuySell = 2, tra.Volume1 * (-1), tra.Volume1) as Cash_Trade_CCY_J,

        iif(tra.BuySell = 2, (tra.RepoRate / 100 * dbo.fCalculateDaysDiff(tra.TradeDate) / @CalcBasis) * tra1.volume1 * (-1), 

                         (tra.RepoRate / 100 * dbo.fCalculateDaysDiff(tra.TradeDate) / @CalcBasis) * tra1.volume1) as Interest_Trady_CCY_K,

        mrk.mlastprice as Clean_MktPrice_L,

        iif(sec.isprocent = 'y', mrk.mLastPrice + ISNULL(ACI.Volume, 0) / asssec.BaseValue * 100, mrk.mLastPrice) as Dirty_MktPrice_M,

        tra.Discount as Haircut_N,

        1 / (1 - tra.Discount / 100) as Margin_Ratio_O,

        tra.RepoRate as Repo_Rate_P,

        iif(sec.isprocent = 'y', crsBAs.Bid, crsEQ.bid) / ISNULL(crsP.bid, -0.00001) as FX_Rate_Instrument_CCY_Trade_CCY_Q,

        iif(sec.isprocent = 'y', tra.Qty * asssec.BaseValue * mrk.mLastPrice/100 + ISNULL(ACI.Volume, 0) * tra.Qty,

                            tra.Qty * mrk.mLastPrice) as Market_Value_Instrument_CCY_R,

        (iif(sec.isprocent = 'y', tra.Qty * asssec.BaseValue * mrk.mLastPrice/100 + ISNULL(ACI.Volume, 0) * tra.Qty, 

             tra.Qty * mrk.mLastPrice)) * (iif(sec.isprocent = 'y', crsBAS.bid/crs.Bid ,  crsEQ.bid/crs.bid )) as Market_Value_Call_CCY_S,

        iif(sec.isprocent = 'y', tra.Qty * asssec.BaseValue * mrk.mLastPrice/100 + ISNULL(ACI.Volume, 0) * tra.Qty,

                            tra.Qty * mrk.mLastPrice) / iif(isnull(1 / (1 - tra.Discount / 100), 0) = 0, 1, 1 / (1 - tra.Discount / 100)) as Haircut_Value_Instrument_CCY_T

    FROM 

        QORT_BACK_DB_UAT.dbo.Trades tra

        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Firms frmCP ON frmCP.id = tra.CpFirm_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Subaccs sub ON sub.ID = tra.SubAcc_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Firms frm on frm.id = sub.OwnerFirm_ID

        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Securities sec ON sec.id = tra.Security_ID 

        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets asssec ON asssec.id = sec.Asset_ID

        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets cur ON cur.id = asssec.BaseCurrencyAsset_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets asscurPay on asscurPay.id = tra.CurrPayAsset_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets asscurPrice on asscurPrice.id = tra.CurrPriceAsset_ID	

        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.AccruedInt ACI ON ACI.asset_ID = asssec.ID AND ACI.AccruedDate = @ytdDateint 

        --LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.MarketInfoHist mrk ON mrk.asset_ID = asssec.ID AND mrk.OldDate = @ytdDateint - 1 AND mrk.TSSection_ID = 154

		--LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets curMrk on curMrk.id  = mrk.PriceAsset_ID

		    OUTER APPLY (

            SELECT MAX(mrk.lastprice) as mlastprice, mrk.PriceAsset_ID as PriceAsset_ID

            FROM QORT_BACK_DB_UAT.dbo.MarketInfoHist mrk 

            WHERE mrk.asset_ID = asssec.ID

            AND mrk.OldDate = @ytdDateint

			group by mrk.PriceAsset_ID

        ) AS mrk

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets curMrk on curMrk.id  = mrk.PriceAsset_ID

        OUTER APPLY (

            SELECT TOP 1 crs.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crs 

            WHERE crs.TradeAsset_ID = (SELECT TOP 1 id FROM QORT_BACK_DB_UAT.dbo.Assets WHERE NAME = @Currency AND Enabled = 0) 

            AND crs.OldDate = @ytdDateint

            AND crs.InfoSource = 'MainCurBank'

        ) AS crs

        OUTER APPLY (

            SELECT TOP 1 crsP.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crsP 

            WHERE crsP.TradeAsset_ID = tra.CurrPayAsset_ID

            AND crsP.OldDate = @ytdDateint

            AND crsP.InfoSource = 'MainCurBank'

        ) AS crsP

        OUTER APPLY (

            SELECT TOP 1 tra1.Volume1

            FROM QORT_BACK_DB_UAT.dbo.Trades tra1

            WHERE tra1.ID = tra.RepoTrade_ID

        ) AS tra1

        OUTER APPLY (

            SELECT TOP 1 crsEQ.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crsEQ 

            WHERE crsEQ.TradeAsset_ID = mrk.PriceAsset_ID

            AND crsEQ.OldDate = @ytdDateint

            AND crsEQ.InfoSource = 'MainCurBank'

        ) AS crsEQ

        OUTER APPLY (

            SELECT TOP 1 crsBAS.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crsBAS

            WHERE crsBAS.TradeAsset_ID = asssec.BaseCurrencyAsset_ID

            AND crsBAS.OldDate = @ytdDateint

            AND crsBAS.InfoSource = 'MainCurBank'

        ) AS crsBAS



		WHERE  tra.IsRepo2 = 'n' -- у второй ноги такой признак

		AND Tra.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND tra.NullStatus = 'n'

          AND tra.Enabled = 0

          AND tra.IsDraft = 'n'

          AND tra.IsProcessed = 'y'

          AND Tra.TT_Const IN (6,3) -- OTC repo (6); Exchange repo (3)

          AND tra.PutDate = 0 -- не закрытые по бумагам сделки

		  AND tra.CpFirm_ID = @FirmID

		  )

SELECT 

    Account_A,

    ISIN_B,

    Side_C,

    Security_Name_D,

    Instrument_CCY_E,

    FX_Rate_Instrument_CCY_Call_CCY_F,

    Start_Date_G,

    End_Date_H,

    Face_amount_I,

    Cash_Trade_CCY_J,

    Interest_Trady_CCY_K,

    Clean_MktPrice_L,

    Dirty_MktPrice_M,

    Haircut_N,

    Margin_Ratio_O,

    Repo_Rate_P,

    FX_Rate_Instrument_CCY_Trade_CCY_Q,

    Market_Value_Instrument_CCY_R,

    Market_Value_Call_CCY_S,

    Haircut_Value_Instrument_CCY_T,

    Haircut_Value_Instrument_CCY_T * FX_Rate_Instrument_CCY_Call_CCY_F as Haircut_Value_Call_CCY_U,

    (Cash_Trade_CCY_J + Interest_Trady_CCY_K) / (FX_Rate_Instrument_CCY_Trade_CCY_Q + Haircut_Value_Instrument_CCY_T)  as Exposure_Instrument_CCY_V,

    (Cash_Trade_CCY_J + Interest_Trady_CCY_K) / (FX_Rate_Instrument_CCY_Trade_CCY_Q + Haircut_Value_Instrument_CCY_T) * FX_Rate_Instrument_CCY_Call_CCY_F as Exposure_Call_CCY_W

INTO #r

FROM CalculatedValues;



	

	select * from #r --return



		insert into #r

		select  cast(frm.FirmShortName as varchar(256)) as Account_A

		, '-' as ISIN_B

		, '-' as Side_C

		, 'Collateral_'+ass.Name Security_Name_D

		, ass.Name Instrument_CCY_E

		, crs.Bid/crsBAS.Bid FX_Rate_Instrument_CCY_Call_CCY_F

		, coll.EmitDate Start_Date_G

		, iif(coll.CancelDate = 0,  'OPEN', cast(coll.CancelDate as varchar)) End_Date_H

		, 0 Face_amount_I

		, coll.BaseValue Cash_Trade_CCY_J 

		, coll.BaseValue/36600*coll.DepoRate*datediff(day, CAST(CONVERT(VARCHAR(8), coll.EmitDate) as DATE) , CAST(CONVERT(VARCHAR(8), @todayInt) as date)) Interest_Trady_CCY_K

		, 0 Clean_MktPrice_L

		, 0 Dirty_MktPrice_M 

		, 0 Haircut_N

		, 0 Margin_Ratio_O

		, coll.DepoRate Repo_Rate_P

		, crs.Bid/crsBAS.Bid FX_Rate_Instrument_CCY_Trade_CCY_Q

		, 0 Market_Value_Instrument_CCY_R

		, 0 Market_Value_Call_CCY_S

		, 0 Haircut_Value_Instrument_CCY_T

		, 0 Haircut_Value_Call_CCY_U

		, (coll.BaseValue/36600*coll.DepoRate*datediff(day, CAST(CONVERT(VARCHAR(8), coll.EmitDate) as DATE) , CAST(CONVERT(VARCHAR(8), @todayInt) as date)) + coll.BaseValue)/(crs.Bid/crsBAS.Bid) Exposure_Instrument_CCY_V

		, (coll.BaseValue/36600*coll.DepoRate*datediff(day, CAST(CONVERT(VARCHAR(8), coll.EmitDate) as DATE) , CAST(CONVERT(VARCHAR(8), @todayInt) as date)) + coll.BaseValue)/(crs.Bid/crsBAS.Bid) Exposure_Call_CCY_W

		FROM QORT_BACK_DB_UAT.dbo.Assets coll

		--LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Accounts ACC ON acc.ID = POS.Account_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets ass on ass.id = coll.BaseCurrencyAsset_ID

		LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Firms frm on frm.BOCode =  CASE 
																			 WHEN CHARINDEX('/', coll.NameAccount) > 0 
																			 THEN SUBSTRING(coll.NameAccount, 1, CHARINDEX('/', coll.NameAccount) - 1)
																			 ELSE c
oll.NameAccount end

		OUTER APPLY (

            SELECT TOP 1 crs.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crs 

            WHERE crs.TradeAsset_ID = (SELECT TOP 1 id FROM QORT_BACK_DB_UAT.dbo.Assets WHERE NAME = @Currency AND Enabled = 0) 

            AND crs.OldDate = @ytdDateint

            AND crs.InfoSource = 'MainCurBank'

        ) AS crs

		      OUTER APPLY (

            SELECT TOP 1 crsBAS.Bid

            FROM QORT_BACK_DB_UAT.dbo.CrossRatesHist crsBAS

            WHERE crsBAS.TradeAsset_ID = coll.BaseCurrencyAsset_ID

            AND crsBAS.OldDate = @ytdDateint

            AND crsBAS.InfoSource = 'MainCurBank'

        ) AS crsBAS

		WHERE coll.AssetSort_Const = 29

		and frm.id = @FirmID

		

		select * from #r --return





















	--select * from #r

		select cast(r.Account_A AS varchar(256)) Account

		, r.ISIN_B ISIN

		, r.Side_C Side

		, r.Security_Name_D Security_Name

		, r.Instrument_CCY_E Instrument_CCY

		, r.FX_Rate_Instrument_CCY_Call_CCY_F FX_Rate_Instrument_CCY_Call_CCY

		, r.Start_Date_G Start_Date

		, r.End_Date_H End_Date

		, dbo.fFloatToMoney2Varchar (r.Face_amount_I) Face_amount

		, r.Cash_Trade_CCY_J Cash_Trade_CCY

		, r.Interest_Trady_CCY_K Interest_Trady_CCY

		, r.Clean_MktPrice_L Clean_MktPrice

		, r.Dirty_MktPrice_M Dirty_MktPrice

		, r.Haircut_N Haircut

		, r.Margin_Ratio_O Margin_Ratio

		, r.Repo_Rate_P Repo_Rate

		, r.FX_Rate_Instrument_CCY_Trade_CCY_Q FX_Rate_Instrument_CCY_Trade_CCY

		, dbo.fFloatToMoney2Varchar (r.Market_Value_Instrument_CCY_R) Market_Value_Instrument_CCY

		, r.Market_Value_Call_CCY_S Market_Value_Call_CCY

		, dbo.fFloatToMoney2Varchar (r.Haircut_Value_Instrument_CCY_T) Haircut_Value_Instrument_CCY

		, r.Haircut_Value_Call_CCY_U Haircut_Value_Call_CCY

		, r.Exposure_Instrument_CCY_V Exposure_Instrument_CCY

		, r.Exposure_Call_CCY_W Exposure_Call_CCY



		into ##Template_01

		from #r r

		order by ISIN_B asc

		

		--where r.Account_A = 20240827

		select * from ##Template_01 order by ISIN asc --return

		

		--select SUM (t01.Exposure_Call_CCY) as 

		CREATE TABLE ##Template_02 (number INT, value VARCHAR(16));

					INSERT INTO ##Template_02 (number, value)
					VALUES 
						(1, CAST((SELECT SUM(Exposure_Call_CCY) FROM ##Template_01 WHERE ISIN <> '-') AS VARCHAR(16)) + @Currency),
						(2, CAST((SE
LECT SUM(Exposure_Call_CCY) FROM ##Template_01 WHERE ISIN = '-') AS VARCHAR(16))+ @Currency),
						(3, CAST(((SELECT SUM(Exposure_Call_CCY) FROM ##Template_01 WHERE ISIN = '-') + 
								  (SELECT SUM(Exposure_Call_CCY) FROM ##Template_01 WHERE ISIN <> 
'-')) AS VARCHAR(16))+ @Currency),
						(4, '50000' + @Currency),
						(5, ''),
						(6, CAST(IIF(ABS((SELECT ISNULL(SUM(Exposure_Call_CCY), 0) FROM ##Template_01 WHERE ISIN = '-') + 
										 (SELECT ISNULL(SUM(Exposure_Call_CCY), 0) FROM ##Template
_01 WHERE ISIN <> '-')) > 50000, 
										 (SELECT ISNULL(SUM(Exposure_Call_CCY), 0) FROM ##Template_01 WHERE ISIN = '-') + 
										 (SELECT ISNULL(SUM(Exposure_Call_CCY), 0) FROM ##Template_01 WHERE ISIN <> '-'), 0) AS VARCHAR(16))+ @Currency);

			
		SELECT * FROM ##Template_02;

		  select value from ##Template_02 order by number asc 



					SET @sql = 'INSERT INTO OPENROWSET (
					''Microsoft.ACE.OLEDB.12.0'',
					''Excel 12.0; Database=' + @TempFileName + '; HDR=NO;IMEX=0;MAXSCANROWS=0'',
					''SELECT * FROM [' + @Sheet1 + '$D1:D1]'')
					SELECT value 
					FROM ##Template_02 
				
	ORDER BY number ASC'

						print @sql

						exec(@sql)

	

				SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A9:w100]'')

			select * from ##Template_01 order by ISIN asc'

		print @sql

		exec(@sql)

	/*

		select r.Num_A

		

		, r.Code_B, r.ArmCode_C, r.AgreeNum_R_D, r.Time_D Time_E, RepoType_R_F, RepoType2_R_G

			, r.PriceType_F PriceType_H, r.ISIN_G ISIN_I, r.Emitent_H Emitent_J, r.BaseValueVolume_I BaseValueVolume_K

			, r.Qty_K Qty_L, r.Volume_L Volume_M, r.PayCurrency_M PayCurrency_N, r.RepoRate_R_O, r.RepoBackDate_R_P

			, RepoLocation_Q, /*r.TradeDate_P*/ r.TradeDate_R_R TradeDate_R, r.TradeDate_R_R, r.TransactionDate_R_T -- Алик 26/02/2024 поменял r.TradeDate2_R_S на r.TradeDate_R_R. выводим равное значение, до настройки механизма отражения РЕПО вендором

			, r.CPCode_R CPCode_U, r.ExternalBroker_S ExternalBroker_V

			

		into ##Template_02

		from #r r

		where r.tt = 2





		/*

		select * from #r r

		select * from ##42000_NY06_workTemplate_01

		select * from ##42000_NY06_workTemplate_02

		return --*/



		



		declare @i int = 0

		declare @s varchar(32) = ''



		while @s is not null begin

			select @i = @i + 1, @s = null

			select top 1 @s = DateLocation from @SheetDates where sdId = @i

			SET @sql = N'UPDATE t SET t.[²ðØ´ðàÎ ´´À] = ''' + @TradeDateToTXT + '''

				from OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @s + ']'') t'

			print @sql

			if @sql is not null exec(@sql)

		end



		--RETURN

		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A11:S11]'')

			select * from ##Template_01 order by Num_A'

		print @sql

		exec(@sql)



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet2 + '$A8:V8]'')

			select * from ##Template_02 order by Num_A'

		print @sql

		exec(@sql)



		/*

		SET @sql = N'UPDATE t SET t.[²ðØ´ðàÎ ´´À] = ''' + @TradeDateToTXT + '''

			from OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$D7:D8]'') t'

		print @sql

		exec(@sql)

		*/



		set @cmd = 'copy "' + @TempFileName + '" "' + @ResultFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))

		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @ResultFileName

			RAISERROR (@execres, 16, 1);

		end



		select 'Report Done: ' + @ResultFileName ResultStatus, 'green' ResultColor



		*/


        
       
            DECLARE @fileReport VARCHAR(512) = @TempFileName--'Asset_Check_Bloomberg_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '-') + '.xlsx';
			 DECLARE @NotifyMessage VARCHAR(MAX) = 'i
s an automatically generated message.';
            DECLARE @NotifyTitle VARCHAR(1024) = 'Collateral per counterparty Armbrok - instructions';

			

			--/*

		  -- Отправка email
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'qort-test-sql',--'qort-sql-mail',
                @recipients = @NotifyEmail,
                @subject = @NotifyTitle,
                @BODY_FORMAT = 'HTML',
 
               @body = @NotifyMessage,
                @file_attachments = @fileReport;


				--*/
/*
            -- Удаление старых отчетов
            SET @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"';
            EXEC master.dbo.xp_cmdshell
 @cmd, no_output;
--*/
            PRINT @NotifyTitle;
         -- Конец блока отправки сообщения

	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		select @Message ResultStatus, 'red' ResultColor

	end catch



END
