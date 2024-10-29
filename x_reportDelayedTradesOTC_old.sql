



--exec QORT_ARM_SUPPORT.dbo.reportDelayedTradesOTC @SelectData = 1

--exec QORT_ARM_SUPPORT.dbo.reportDelayedTradesOTC @SendMail = 1



CREATE PROCEDURE [dbo].[x_reportDelayedTradesOTC_old]

	@SelectData bit = 0

	, @SendMail bit = 0

	, @NotifyEmail varchar(1024) = 'qortsupport@armbrok.am;aleksandr.mironov@armbrok.am;'

	--, @NotifyEmail varchar(1024) = 'qortsupport@armbrok.am;'--aleksandr.mironov@armbrok.am;'

AS

BEGIN



	SET NOCOUNT ON



	if nullif(@NotifyEmail, '') is null set @NotifyEmail = 'qortsupport@armbrok.am;aleksandr.mironov@armbrok.am;'

	--set @cmd = 'del "' + @FilePath + 'Report_Opened_OTC_Trades_*.*"'

	--exec master.dbo.xp_cmdshell @cmd, no_output





	declare @tt table(tradeId int primary key, DaysDelayed int)



	declare @ReportDate date = getdate()

	--set @ReportDate = '20230701'

	declare @ReportDateInt int = cast(convert(varchar, @ReportDate, 112) as int)

	declare @MaxDaysPercent int = 28



	insert into @tt(tradeId, DaysDelayed)

	select t.id, datediff(day, cast(cast(t.PutPlannedDate as varchar) as date), @ReportDate) DaysDelayed

	from QORT_BACK_DB.dbo.Trades t with (nolock, index = I_Trades_PutDate)

	inner join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

	where t.PutDate = 0 and t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y' and t.CloseDate = '0'

		and tss.MT_Const in (5,6,-1)

		--and t.AgreeNum in ('1453', '2192', '2300', '2369', '2373', '2402', '2401') 

	

	if OBJECT_ID('tempdb..##opened_otc', 'U') is not null drop table ##opened_otc



	select t.AgreeNum, t.id ID, DaysDelayed DaysDelayed, cast(cast(t.PutPlannedDate as varchar) as date) PlannedDelivery, cast(cast(t.TradeDate as varchar) as date) TradeDate

		, a.ISIN, a.ShortName Asset, cast(t.Qty as decimal(32,0)) Qty, t.Price, isnull(aPrice.ShortName, '') PriceCurrency

		, cast(t.Volume1 as decimal(32,2)) Volume1, s.SubaccName, iif(t.BuySell = 1, 'Buy', 'Sell') Operation, isnull(fCP.FirmShortName, '') CounterParty, @ReportDate ReportDate

		, DelayPercent

		, QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) BGColor

	into ##opened_otc

	from @tt tt

	inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

	left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

	left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

	left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

	left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

	left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

	outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

						when DaysDelayed < -@MaxDaysPercent then 0

						else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

						end * 100 / 2 / @MaxDaysPercent DelayPercent 

				) DelayPercent

	order by DaysDelayed desc, AgreeNum, tt.tradeId



	if @SelectData = 1 begin

	

		select *

		from ##opened_otc

		order by DaysDelayed desc, AgreeNum, Id

		/*

		select t.AgreeNum, t.id ID, DaysDelayed DaysDelayed, cast(cast(t.PutPlannedDate as varchar) as date) PlannedDelivery, cast(cast(t.TradeDate as varchar) as date) TradeDate

			, a.ISIN, a.ShortName Asset, t.Qty, t.Price, isnull(aPrice.ShortName, '') PriceCurrency

			, t.Volume1, s.SubaccName, iif(t.BuySell = 1, 'Buy', 'Sell') Operation, isnull(fCP.FirmShortName, '') CounterParty, @ReportDate ReportDate

			, DelayPercent

			, QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) BGColor

		from @tt tt

		inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

		left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

		outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

							when DaysDelayed < -@MaxDaysPercent then 0

							else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

							end * 100 / 2 / @MaxDaysPercent DelayPercent 

					) DelayPercent

		order by DaysDelayed desc, AgreeNum, tt.tradeId

		*/

	end



	if @SendMail = 1 begin



		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @Sheet varchar(32) = 'Opened_OTC_Trades'

		declare @fileTemplate varchar(512) = 'template_Opened_OTC_Trades.xlsx'

		declare @fileReport varchar(512) = 'Report_Opened_OTC_Trades_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '.xlsx'

		declare @cmd varchar(512)

		declare @sql varchar(1024)





		set @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FilePath + @fileReport + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A1:O1000000]'')

			select AgreeNum, ID, DaysDelayed, PlannedDelivery, TradeDate, ISIN, Asset, Qty, Price, PriceCurrency, Volume1, SubaccName, Operation, CounterParty, ReportDate from ##opened_otc order by DaysDelayed desc, AgreeNum, Id'



		exec(@sql)



		--declare @NotifyEmail varchar(1024) = null

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null



		set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(t.AgreeNum,'') collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(cast(t.id as int) as varchar)

				+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + a.ISIN

				+ '//2\\' + a.ShortName collate Cyrillic_General_CI_AS --Asset

				+ '//2\\' + cast(t.Qty as varchar)

				+ '//2\\' + cast(cast(t.Price as decimal(32,2)) as varchar)

				+ '//2\\' + isnull(aPrice.ShortName, '') collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

				+ '//2\\' + s.SubaccName collate Cyrillic_General_CI_AS

				+ '//2\\' + iif(t.BuySell = 1, 'Buy', 'Sell') --Operation

				+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

				+ '//3\\'

			from @tt tt

			inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

			left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

			left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

			left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

			left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

			left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

			--outer apply (select datediff(day, cast(cast(t.PutPlannedDate as varchar) as date), @ReportDate) DaysDelayed) dd

			outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

								when DaysDelayed < -@MaxDaysPercent then 0

								else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

								end * 100 / 2 / @MaxDaysPercent DelayPercent 

						) DelayPercent

			order by DaysDelayed desc, AgreeNum, tt.tradeId

			for xml path('')

		) as varchar(max))



		set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		-- заголовки HTML-таблицы

		set @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>AgreeNum'

			+ '</td><td>ID'

			+ '</td><td>DaysDelayed'

			+ '</td><td>PlannedDelivery'

			+ '</td><td>TradeDate'

			+ '</td><td>ISIN'

			+ '</td><td>Asset'

			+ '</td><td>Quantity'

			+ '</td><td>Price'

			+ '</td><td>PriceCurrency'

			+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate'

			+ '</tr>' + @NotifyMessage + '</table>'





		declare @delayedTrades int = (select count(*) from @tt tt where tt.DaysDelayed > 0)

		declare @NonDelayedTrades int = (select count(*) from @tt tt where tt.DaysDelayed <= 0)



		print @delayedTrades

		print @NonDelayedTrades





		-- ЗАГЛУШКА - ПОКА ОТСЫЛАЕМ ТОЛЬКО НАМ

		

		set @NotifyTitle = 'OTC Opened Trades on ' + cast(@ReportDate as varchar) + ': ' + cast(@delayedTrades + @NonDelayedTrades as varchar)

			+ iif(@delayedTrades > 0, ', DELAYED: ' + cast(@delayedTrades as varchar), '')



		-- само HTML-письмо

		set @NotifyMessage = '<html><body><p>'

			+ '<font color="red"/>' + iif(@delayedTrades > 0, 'Delayed Trades: '+cast(@delayedTrades as varchar)+'<br>', '')

			+ '<font color="green"/>' + iif(@NonDelayedTrades > 0, 'On Time Trades: '+cast(@NonDelayedTrades as varchar)+'<br>', '')

			+ '<font color="black"/>Send notifications to: ' + @NotifyEmail + '</p>'

			+ @NotifyMessage

			+ '</body></html>'





		--/*



		set @fileReport = @FilePath + @fileReport

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage

			, @file_attachments = @fileReport

			--*/



		set @cmd = 'del "' + @FilePath + 'Report_Opened_OTC_Trades_*.*"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		print @NotifyTitle

		--print @NotifyMessage



	end



	if OBJECT_ID('tempdb..##opened_otc', 'U') is not null drop table ##opened_otc



END

