









-- exec QORT_ARM_SUPPORT.dbo.exportTrades_RegulatoryNY06BuySellREPO '20231208'



CREATE PROCEDURE [dbo].[exportTrades_RegulatoryNY06BuySellREPO_BACKUP]

	@TradeDate date

AS

BEGIN



	begin try



		SET NOCOUNT ON



		declare @Message varchar(1024)

		--declare @TradeDateFrom int = cast(convert(varchar, dateadd(day, -1, @TradeDate), 112) as int)

		declare @TradeDateFrom int = cast(convert(varchar, QORT_ARM_SUPPORT.dbo.fGetPrevBusinessDay(@TradeDate), 112) as int)

		declare @TradeDateTo int = cast(convert(varchar, @TradeDate, 112) as int)

		declare @TradeTimeFrom int = 160000000 --(16:00:00.000)

		declare @ArmBrokFirmShortName varchar(16) = 'ArmBrok'



		declare @TradeDateToTXT varchar(32) = QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(@TradeDateTo)



		declare @sql nvarchar(max)

		/*declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\test_42000_NY06_workTemplate.xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\temp\42000_NY06_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY06_'+cast(@TradeDateTo as varchar)+'.xls'*/

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\template\42000_NY06_workTemplate (2).xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\archive\42000_NY06_workTemplate_'+cast(@TradeDateTo as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, g
etdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY06_workTemplate\42000_NY06_'+cast(@TradeDateTo as varchar)+'.xls'

		declare @Sheet1 varchar(32) = '1.buy-sell'

		declare @Sheet2 varchar(32) = '2.repo-r.repo'



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

		if OBJECT_ID('tempdb..##42000_NY06_workTemplate_01', 'U') is not null drop table ##42000_NY06_workTemplate_01

		if OBJECT_ID('tempdb..##42000_NY06_workTemplate_02', 'U') is not null drop table ##42000_NY06_workTemplate_02





		select t.id TradeId, row_number() over(partition by tt.tt order by t.TradeDate, t.TradeTime, t.id) Num_A

			, iif(fo.IsResident = 'y', isnull(fpo.MIC, ''), N'áã é»½Ç¹»Ýï') Code_B

			--, '$$$' + isnull(fpo.MIC, '') Code_B

			, '42000' ArmCode_C

			, iif(t.TradeTime <= 1000, '', QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(TradeTime)) Time_D

			, iif(t.BuySell = 1, '³éù', 'í³×³éù') BuySell_E

			, iif(t.PT_Const=1, N'áã µ³ÅÝ³ÛÇÝ', N'µ³ÅÝ³ÛÇÝ') PriceType_F -- 1 - %, 2 - abs

			, a.ISIN ISIN_G

			--, '??? - ' + fEmit.Name + iif(EmitCountry.Name <> '', ', ' + EmitCountry.Name, '') Emitent_H

			, isnull(fEmitProp.NameU, '') + iif(a.Country = 'Armenia', '', iif(AssetCountry.NameU <> '', ', ' + AssetCountry.NameU, '')) Emitent_H

			, iif(a.BaseValueOrigin * t.QTY <> 0, QORT_ARM_SUPPORT.dbo.fFloatToCurrency(a.BaseValueOrigin * t.QTY), '') BaseValueVolume_I

			, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Price) Price_J

			, iif(a.Country = 'Armenia', '', QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Qty)) [Qty_K]

			, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Volume1) Volume_L

			, aPay.ShortName PayCurrency_M

			, iif(t.Yield > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.Yield * 100)+'%', '') Yield_N

			--, '$$$' TradePlace_O

			, isnull(fpts.NameU, '') TradePlace_O

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.TradeDate) TradeDate_P

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(iif(t.PutDate > 0, t.PutDate, t.PutplannedDate)) PutDate_Q

			--, '$$$'  + isnull(fpcp.MIC, '') CPCode_R

			, iif(cpts.code is not null, N'Ï³½Ù³Ï»ñåí³Í ßáõÏ³', iif(fcp.IsResident = 'y', isnull(fpcp.MIC, ''), N'áã é»½Ç¹»Ýï')) CPCode_R

			, isnull(fExtBro.FirmShortName, '') ExternalBroker_S

			, tt.tt

			, t.AgreeNum AgreeNum_R_D

			, iif(tt.tt=2, N'é»åá', '') RepoType_R_F

			, iif(tt.tt=2, iif(p.TransactionDate > 0, N'»ñÏ³ñ³Ó·í³Í', N'Ýáñ ÏÝùí³Í'), '') RepoType2_R_G

			, iif(tt.tt=2 and t.RepoRate > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToCurrency5(t.RepoRate) + '%' + ' ???', '???') RepoRate_R_O

			, iif(tt.tt=2, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.BackDate) + ' ???', '') RepoBackDate_R_P

			, iif(tt.tt=2, iif(t.TT_Const = 3, N'86100', N'ãÏ³ñ·³íáñíáÕ ßáõÏ³'), '') RepoLocation_Q

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(t.TradeDate) + ' ???' TradeDate2_R_S

			, iif(tt.tt=2 and p.TransactionDate > 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(p.TransactionDate), '') TransactionDate_R_T

		into #r

		from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fpo with (nolock) on fpo.Firm_ID = fo.id

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		--left outer join QORT_BACK_DB.dbo.Firms fEmit with (nolock) on fEmit.id = a.EmitentFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fEmitProp with (nolock) on fEmitProp.Firm_ID = a.EmitentFirm_ID

		--left outer join QORT_BACK_DB.dbo.Countries EmitCountry with (nolock) on EmitCountry.id = fEmit.Country_ID

		left outer join QORT_BACK_DB.dbo.Countries AssetCountry with (nolock) on AssetCountry.Name = a.Country

		left outer join QORT_BACK_DB.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fpcp with (nolock) on fpcp.Firm_ID = fcp.id

		left outer join QORT_BACK_DB.dbo.TSs cpts with (nolock) on cpts.Code = fcp.FirmShortName

		left outer join QORT_BACK_DB.dbo.Firms fExtBro with (nolock) on fExtBro.id = t.ExtBrokerFirm_ID



		left outer join QORT_BACK_DB.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_BACK_DB.dbo.Firms fts with (nolock) on fts.FirmShortName = ts.Name and fts.Enabled = 0

		left outer join QORT_BACK_DB.dbo.FirmProperties fpts with (nolock) on fpts.Firm_ID = fts.id



		outer apply(select case when t.TT_Const in (5) then 1 when t.TT_Const in (3,6) then 2 end tt) tt

		outer apply(select top 1 p.PhaseDate TransactionDate from QORT_BACK_DB.dbo.Phases p with (nolock) where p.Trade_ID = t.RepoTrade_ID and p.IsCanceled = 'n' order by 1 desc) p

		where t.TradeDate between @TradeDateFrom and @TradeDateTo

			and NOT (t.TradeDate = @TradeDateFrom and t.TradeTime < @TradeTimeFrom)

			and NOT (t.TradeDate = @TradeDateTo and t.TradeTime >= @TradeTimeFrom)

			and t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y'

			--and t.TT_Const in (5) -- 	OTC buy/sell securities

			and t.TT_Const in (5, 3, 6) -- 5 - OTC buy/sell securities, 3,6 - Repo

			and not (t.IsRepo2 = 'y') -- для РЕПО только 1-ая нога???

	

		select r.Num_A, r.Code_B, r.ArmCode_C, r.Time_D, r.BuySell_E, r.PriceType_F, r.ISIN_G, r.Emitent_H, r.BaseValueVolume_I, r.Price_J, r.Qty_K, r.Volume_L

			, r.PayCurrency_M, r.Yield_N, r.TradePlace_O, r.TradeDate_P, r.PutDate_Q, r.CPCode_R, r.ExternalBroker_S

		into ##42000_NY06_workTemplate_01

		from #r r

		where r.tt = 1



		select r.Num_A, r.Code_B, r.ArmCode_C, r.AgreeNum_R_D, r.Time_D Time_E, RepoType_R_F, RepoType2_R_G

			, r.PriceType_F PriceType_H, r.ISIN_G ISIN_I, r.Emitent_H Emitent_J, r.BaseValueVolume_I BaseValueVolume_K

			, r.Qty_K Qty_L, r.Volume_L Volume_M, r.PayCurrency_M PayCurrency_N, r.RepoRate_R_O, r.RepoBackDate_R_P

			, RepoLocation_Q, r.TradeDate_P TradeDate_R, r.TradeDate2_R_S, r.TransactionDate_R_T

			, r.CPCode_R CPCode_U, r.ExternalBroker_S ExternalBroker_V

		into ##42000_NY06_workTemplate_02

		from #r r

		where r.tt = 2





		/*

		select * from #r r

		select * from ##42000_NY06_workTemplate_01

		select * from ##42000_NY06_workTemplate_02

		return --*/



		declare @SheetDates table(sdId int identity primary key, DateLocation varchar(32))

		insert into @SheetDates(DateLocation) values ('1.buy-sell$D7:D8'), ('2.repo-r.repo$E4:E5'), ('3.Forward (FX)$F4:F5'), ('4.Futures (FX)$D5:D6')

			, ('5.Forward (SEC)$E4:E5'), ('6.Futures (SEC)$E5:E6'), ('7.Forward (AYL)$D4:D5'), ('8.Futures(AYL)$E5:E6'), ('9.OPTION (FX)$D4:D5'), ('10.OPTION (SEC)$D4:D5')

			, ('11.OPTION(AYL)$E5:E6'), ('12# Swap(POXAJEQ)$D5:D6'), ('13# Swap (FX)$D5:D6'), ('14.Swap(INTRATE)$D5:D6'), ('15# CFD (FX)$D5:D6'), ('16# CFD (SEC)$D5:D6')



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

			''SELECT * FROM [' + @Sheet1 + '$A10:S10]'')

			select * from ##42000_NY06_workTemplate_01 order by Num_A'

		print @sql

		exec(@sql)



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet2 + '$A7:v7]'')

			select * from ##42000_NY06_workTemplate_02 order by Num_A'

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





	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		select @Message ResultStatus, 'red' ResultColor

	end catch



END

