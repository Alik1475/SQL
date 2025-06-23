



-- exec QORT_ARM_SUPPORT.dbo.Portfolio_Valuation_email



CREATE PROCEDURE [dbo].[Portfolio_Valuation_email]



AS



BEGIN
	BEGIN TRY
		if OBJECT_ID('tempdb..#Recipients', 'U') is not null drop table #Recipients
		CREATE TABLE #Recipients (number INT, SubAccount VARCHAR(10), Email VARCHAR(100) );
					INSERT INTO #Recipients (number, SubAccount, Email )
					VALUES 
			
			  (1, 'AS1358' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
					--/*	
						, (2, 'AS1937' , 'maxim.biryukov@armbrok.am;QORT@ARMBROK.AM')
						, (3, 'AS1061' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (4, 'AS1063' , 'marine.zakharya
n@armbrok.am;QORT@ARMBROK.AM')
						, (5, 'AS1614' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (6, 'AS1697' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (7, 'AS1752' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (8, 'A
S1806' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (9, 'AS1918' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						, (10, 'AS1919' , 'marine.zakharyan@armbrok.am;QORT@ARMBROK.AM')
						--*/

		DECLARE @todayDate DATE = GETDATE()
		DECLAR
E @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)
		DECLARE @ytdDate DATE

		DECLARE @n INT = 0

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\Asset_Value.xlsx'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\archive\Asset_Value.xlsx'+cast(@todayInt as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xls
x'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\REPO\Asset_Value_'+cast(@todayInt as varchar)+'.xlsx'

		declare @Sheet1 varchar(32) = 'Client_portfolio'

		declare @SubAccount varchar(10) 

        declare @sql nvarchar(max)

		DECLARE @NotifyEmail VARCHAR(1024) = 'aleksandr.mironov@armbrok.am'--.sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am';

        -- Определяем вчерашний рабочий день

        WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, @todayDate)) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

        SET @ytdDate = (DATEADD(DAY, -1-@n, @todayDate)) -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);

        declare @ytdDatevarch varchar(32) = dbo.fIntToDateVarchar_dd_MMM_yyyy (@ytdDateint);

		PRINT @ytdDatevarch
				declare @res table(r varchar(255))

		declare @cmd varchar(512)



		declare @execres varchar(1024)

		--/*



	select @n = MAX(number) from #Recipients;



	while @n > 0

	begin



	select @NotifyEmail = email from #Recipients where number = @n

	select @SubAccount = SubAccount from #Recipients where number = @n



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

		SELECT
             sub.SubAccCode COLLATE Cyrillic_General_CI_AS + '/' + sub.SubaccName COLLATE Cyrillic_General_CI_AS  as SubAccCode
			 --, sub.SubaccName as SubaccNam
e
			 , ass.isin as isin 
			 , ass.ShortName as Ticker
			 , dbo.fFloatToMoney2Varchar (pos.VolFree) as Qty
			 , isnull(dbo.fFloatYieldToVarchar(mrkt.LastPrice) + iif (mrkt.IsProcent = 'y', '%', mrkt.currency),'-') as LastPrice
			 , isnull(dbo.fFloatTo
Money2Varchar(ACI.Vol_ACI* pos.VolFree)  + AssCur.name , '-') as ACI
			-- , mrkt.IsProcent as IsProcent		
			 , isnull(dbo.fFloatToMoney2Varchar(mrkt.LastPrice * isnull(FX.FX_Coefficient,1) * (iif (mrkt.IsProcent = 'y', ass.BaseValue/100 , 1)) * pos.VolF
ree + isnull(ACI.Vol_ACI* pos.VolFree , 0) ) + iif (mrkt.IsProcent = 'y', AssCur.name , mrkt.currency), '-') as Asset_Value
			 , iif (mrkt.IsProcent = 'y', AssCur.name , mrkt.currency) as currency
			 , isnull(mrkt.LastPrice * isnull(FX.FX_Coefficient,1)
 * (iif (mrkt.IsProcent = 'y', ass.BaseValue/100 , 1)) * pos.VolFree + isnull(ACI.Vol_ACI* pos.VolFree , 0), 0) as Asset_Value_Float
			 , ass.AssetClass_Const as AssetClass_Const
			 , FX.FX_Coefficient

			--, pos.*			
			
		INTO #r
		FROM QORT_BACK_DB.
dbo.Subaccs sub WITH (NOLOCK)
	--	QORT_BACK_DB.dbo.Assets ass WITH (NOLOCK)
		LEFT JOIN QORT_BACK_DB.dbo.PositionHist pos ON pos.Subacc_ID = sub.ID and pos.Date = @todayInt
		LEFT JOIN QORT_BACK_DB.dbo.Assets ass ON ass.ID = pos.Asset_ID
		LEFT JOIN QORT_
BACK_DB.dbo.Assets AssCur ON AssCur.ID = ass.BaseCurrencyAsset_ID
		outer apply (select top 1 
						  mrkt.LastPrice  as LastPrice
						, mrkt.IsProcent as IsProcent
						, AssCr.name as currency
						, mrkt.PriceAsset_ID as PriceAsset_ID
								from
 QORT_BACK_DB.dbo.MarketInfoHist mrkt 
								LEFT JOIN QORT_BACK_DB.dbo.Assets AssCr ON AssCr.ID = mrkt.PriceAsset_ID
								where mrkt.Asset_ID = ass.id and mrkt.OldDate = @ytdDateint and mrkt.LastPrice > 0 and mrkt.TSSection_ID in (154,165)
								o
rder by mrkt.TSSection_ID asc
								) as mrkt
		outer apply (select top 1 
					 aci.Volume as Vol_ACI
								from QORT_BACK_DB.dbo.AccruedInt aci 
								where aci.Asset_ID = ass.id and aci.AccruedDate = @ytdDateint							
								) as ACI
		OUTER AP
PLY (

			SELECT 

				CRH.Bid AS Price_Quote,

				CRH_ass.Bid AS Price_ASS,

				CASE 

					WHEN CRH_ass.Bid IS NOT NULL AND CRH.Bid IS NOT NULL THEN CRH.Bid / CRH_ass.Bid

					ELSE NULL

				END AS FX_Coefficient

			FROM 

				QORT_BACK_DB.dbo.CrossRatesHist CRH

				

			LEFT JOIN 

				QORT_BACK_DB.dbo.CrossRatesHist CRH_ass

				ON CRH_ass.TradeAsset_ID = ass.BaseCurrencyAsset_ID

				AND CRH_ass.OldDate = @ytdDateint and CRH_ass.InfoSource = 'MainCurBank'

			WHERE 

				CRH.TradeAsset_ID = mrkt.PriceAsset_ID 

				AND CRH.OldDate = @ytdDateint 

				and CRH.InfoSource = 'MainCurBank'

		) AS FX

		WHERE sub.SubAccCode =  @SubAccount
		AND pos.VolFree <> 0
		--and ass.AssetType_Const = 1

		select * from #r 
		--return

		CREATE TABLE ##Template_02 (number INT, value VARCHAR(100));
					INSERT INTO ##Template_02 (number, value)
					VAL
UES 
						(1, ''),
						(2, CAST((SELECT top 1 SubAccCode COLLATE Cyrillic_General_CI_AS FROM #r)  AS VARCHAR(100))),
						(3, ''),
						(4, CAST(@ytdDatevarch COLLATE Cyrillic_General_CI_AS AS VARCHAR(16))),
						(5, ''),
						(6, '');

					SELECT
 * FROM ##Template_02;

		  select value from ##Template_02 order by number asc 

			select CASE r.AssetClass_Const

    WHEN 2 THEN ' Cash market'

    WHEN 3 THEN 'Futures'

    WHEN 4 THEN 'Options'

    WHEN 5 THEN 'Equity'

    WHEN 6 THEN 'Bonds'

    WHEN 7 THEN 'Debt Instruments RF'

    WHEN 8 THEN 'Equity'

    WHEN 9 THEN 'Debt instruments'

    WHEN 10 THEN 'Non-equity securities'

    WHEN 11 THEN 'Funds'

    WHEN 12 THEN 'Indices'

    WHEN 13 THEN 'Limits'

    WHEN 14 THEN 'Commodities'

    WHEN 15 THEN 'Loans and deposits'

    WHEN 16 THEN 'ADR'

    WHEN 17 THEN 'OTC derivatives'

    WHEN 18 THEN 'Exchange Traded Funds'

    WHEN 19 THEN 'Structured Finance Products'

    ELSE 'Unknown'

END AS Asset_Class

		, r.ISIN ISIN

		, r.Ticker Ticker

		, r.Qty Qty

		, r.LastPrice LastPrice

		, r.ACI ACI

		, r.Asset_Value Asset_Value

		/*, r.Start_Date_G Start_Date

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

		, r.Exposure_Call_CCY_W Exposure_Call_CCY*/



		into ##Template_01

		from #r r

		order by Asset_Class

		

		--where r.Account_A = 20240827

		select * from ##Template_01 order by ISIN asc --return


							SET @sql = 'INSERT INTO OPENROWSET (
					''Microsoft.ACE.OLEDB.12.0'',
					''Excel 12.0; Database=' + @TempFileName + '; HDR=NO;IMEX=0;MAXSCANROWS=0'',
					''SELECT * FROM [' + @Sheet1 +
 '$B1:B1]'')
					SELECT value 
					FROM ##Template_02 
					ORDER BY number ASC'

						print @sql

						exec(@sql)

	

				SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A9:G100]'')

			select * from ##Template_01 order by Asset_Class asc'

		print @sql

		exec(@sql)
           
		   DECLARE @fileReport VARCHAR(512) = @TempFileName--'Asset_Check_Bloomberg_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '-') + '.xlsx';
			 DECLARE @NotifyMessage VARCHAR(MAX) = 'i
s an automatically generated message.';
            DECLARE @NotifyTitle VARCHAR(1024) = 'Client Portfolio Valuation Report ' + CAST((SELECT top 1 value COLLATE Cyrillic_General_CI_AS FROM ##Template_02 where number = 4)  AS VARCHAR(12)) + ' for client: '
 + CAST((SELECT top 1 value COLLATE Cyrillic_General_CI_AS FROM ##Template_02 where number = 2)  AS VARCHAR(100));

								INSERT INTO ##Template_02 (number, value)
					VALUES 
						(1, ''),
						(2, CAST((SELECT top 1 SubAccCode COLLATE Cyrillic_General_CI_AS FROM #r)  AS VARCHAR(100))),
						(3, ''),
						(4, CAST(@ytdDatevarch COLLATE Cyrillic_General_CI_AS AS
 VARCHAR(16))),
						(5, ''),
						(6, '');

			--/*

		  -- Отправка email

		   --set @NotifyEmail = 'aleksandr.mironov@armbrok.am' -- for test
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'qort-sql-mail',--'qort-test-sql',
                @recipients = @NotifyEmail,
           
     @subject = @NotifyTitle,
                @BODY_FORMAT = 'HTML',
                @body = @NotifyMessage,
                @file_attachments = @fileReport;


				--*/
			set @n = @n - 1
		end
	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSA
CTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

