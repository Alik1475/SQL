





--exec QORT_ARM_SUPPORT.dbo.reportDelayedTradesOTC @SelectData = 1

--exec QORT_ARM_SUPPORT.dbo.reportDelayedTradesOTC @SendMail = 0



CREATE PROCEDURE [dbo].[reportDelayedTradesOTC]

	@SelectData bit = 0

	, @SendMail bit = 1 -- включена отправка

	, @NotifyEmail varchar(1024) = 'Aram.Kayfajyan@armbrok.am;samvel.sahakyan@armbrok.am;settlements@armbrok.am;tradingdesk@armbrok.am;backoffice@armbrok.am;dealing@armbrok.am;armine.khachatryan@armbrok.am;qortsupport@armbrok.am;Qort@armbrok.am'--;qortsuppor
t@armbrok.am;

	, @IsClient bit = null

	--, @NotifyEmail1 varchar(1024) = 'qortsupport@armbrok.am;aleksandr.mironov@armbrok.am;'

AS

BEGIN



	SET NOCOUNT ON



	if nullif(@NotifyEmail, '') is null set @NotifyEmail = 'Aram.Kayfajyan@armbrok.am;samvel.sahakyan@armbrok.am;settlements@armbrok.am;tradingdesk@armbrok.am;backoffice@armbrok.am;dealing@armbrok.am;armine.khachatryan@armbrok.am;qortsupport@armbrok.am;Qort@
armbrok.am'--;qortsupport@armbrok.am;

	--set @cmd = 'del "' + @FilePath + 'Report_Opened_OTC_Trades_*.*"'

	--exec master.dbo.xp_cmdshell @cmd, no_output

	declare @NotifyEmail1 varchar(1024) --='aleksandr.mironov@armbrok.am;ashot.minasyan@armbrok.am;tigran.gevorgyan@armbrok.am;viktor.dolzhenko@armbrok.am;sona.nalbandyan@armbrok.am;aleksandr.mironov@armbrok.am;'



	declare @tt table(tradeId int primary key, DaysDelayed int, IsClient bit, SalesID int)



	declare @ReportDate date = getdate()

	--set @ReportDate = '20230701'

	declare @ReportDateInt int = cast(convert(varchar, @ReportDate, 112) as int)

	declare @MaxDaysPercent int = 28

	declare @NotifyMessage varchar(max)

	declare @NotifyMessage1 varchar(max)

	declare @NotifyTitle varchar(1024) = null

	declare @NotifyTitle1 varchar(1024) = null

	declare @delayedTradesDealer int 

	declare @NonDelayedTradesDealer int 

	declare @delayedTradesClient int 

	declare @NonDelayedTradesClient int

	declare @FilePath varchar(255) --= '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

	--if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

	declare @SheetClient varchar(32) = 'Opened_OTC_Trades_Dealer'

	declare @SheetDealer varchar(32) = 'Opened_OTC_Trades_Client'

	declare @fileTemplate varchar(512) = 'template_Opened_OTC_Trades6.xlsx'

	declare @fileReport varchar(512) = 'Report_Opened_OTC_Trades_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '.xlsx'

	declare @cmd varchar(512)

	declare @sql varchar(1024)



	insert into @tt(tradeId, DaysDelayed, IsClient, SalesID)

	select t.id, datediff(day, cast(cast(iif(t.Isrepo2 = 'y',t.PayPlannedDate, t.PutPlannedDate) as varchar) as date), @ReportDate) DaysDelayed

		--, iif(fo.BOCode = '00001', 0, 1)

		, iif(t.CpTrade_ID <= 0, 1, 0) IsClient -- клиентские = одноногие

		, fo.Sales_ID SalesID

	from QORT_BACK_DB.dbo.Trades t with (nolock, index = I_Trades_PutDate)

	left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

	left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

	inner join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

	where t.PutDate = 0 and t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y' and t.CloseDate = 0

		and tss.MT_Const in (5,6,-1)

		--and not (t.CpTrade_ID < t.ID and t.CpTrade_ID > 0)

		and t.QFlags & 268435456 = 0 -- not terminated

		--and t.AgreeNum in ('1453', '2192', '2300', '2369', '2373', '2402', '2401') 

		and s.SubAccCode not in ('AS_test') -- исключения счетов из отчета

	delete t

	from @tt t

	where t.DaysDelayed <= 0

	--select * from @tt

	if @SelectData = 1 and @IsClient = 1 waitfor delay '00:00:05'



	if OBJECT_ID('tempdb..##opened_otc2', 'U') is not null drop table ##opened_otc2



	select t.AgreeNum /*isnull(tp.ExternalNum, '')*/ AgreeNum, t.id ID, DaysDelayed DaysDelayed, cast(cast(iif(t.Isrepo2 = 'y',t.PayPlannedDate, t.PutPlannedDate) as varchar) as date) PlannedDelivery, cast(cast(t.TradeDate as varchar) as date) TradeDate

		, a.ISIN, a.ShortName Asset, cast(t.Qty as decimal(32,0)) Qty, t.Price, isnull(aPrice.ShortName, '') PriceCurrency

		, cast(t.Volume1 as decimal(32,2)) Volume1, s.SubAccCode SubaccName, iif(t.BuySell = 1, 'Buy', 'Sell') Operation, isnull(fCP.FirmShortName, '') Counterparty, @ReportDate ReportDate

		, DelayPercent

		, QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) BGColor

		, iif(tt.IsClient = 1, 'yes', 'no') isClientDeal

		, nullif(t.CpTrade_ID, -1) CpTrade_ID

		, tt.IsClient

		, fo.FirmShortName OwnerName

		, QORT_ARM_SUPPORT.dbo.fFloatToCurrency(t.Volume1) Volume11

		,isnull(fSl.Name, '-') Sales

	into ##opened_otc2

	from @tt tt

	inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

	left outer join QORT_BACK_DB.dbo.TradeProperties tp with (nolock) on tp.Trade_ID = t.id

	left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

	left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

	left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

	left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

	left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

	left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

	left outer join QORT_BACK_DB.dbo.Firms fSl with (nolock) on fSl.id = fo.Sales_ID

	outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

						when DaysDelayed < -@MaxDaysPercent then 0

						else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

						end * 100 / 2 / @MaxDaysPercent DelayPercent 

				) DelayPercent

	order by DaysDelayed desc, t.AgreeNum, isnull(tp.ExternalNum, ''), tt.tradeId



	delete t

	from ##opened_otc2 t

	where t.IsClient = 0 and SubaccName = 'ARMBR_Subacc'--t.CpTrade_ID < t.ID and t.CpTrade_ID > 0--





	if @SelectData = 1 begin

	

		select *

		from ##opened_otc2

		where @IsClient is null or IsClient = @IsClient

		order by DaysDelayed desc, AgreeNum, Id



	end



	if @SendMail = 1 and isnull(@IsClient, 0) = 0 begin



		/*declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @SheetClient varchar(32) = 'Opened_OTC_Trades_Dealer'

		declare @SheetDealer varchar(32) = 'Opened_OTC_Trades_Client'

		declare @fileTemplate varchar(512) = 'template_Opened_OTC_Trades6.xlsx'

		declare @fileReport varchar(512) = 'Report_Opened_OTC_Trades_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '.xlsx'

		declare @cmd varchar(512)

		declare @sql varchar(1024)*/

		set @FilePath = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'



		set @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		--select AgreeNum, ID, DaysDelayed, PlannedDelivery, TradeDate, ISIN, Asset, Qty, Price, PriceCurrency, Volume1, SubaccName, Operation, CounterParty, ReportDate'

		--+ ', IsClientDeal, CpTrade_ID'



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FilePath + @fileReport + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @SheetClient + '$A1:Q1000000]'')

			select AgreeNum, ID, DaysDelayed, PlannedDelivery, TradeDate

				, ISIN, Asset, Qty, Price, PriceCurrency, Volume11, Operation, SubaccName, OwnerName, CounterParty, Sales'

			+ ' from ##opened_otc2 where IsClient = 1 order by DaysDelayed desc, AgreeNum, Id'

		exec(@sql)



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FilePath + @fileReport + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @SheetDealer + '$A1:Q1000000]'')

			select AgreeNum, ID, isnull(nullif(cast(CpTrade_ID as varchar), ''-1''), ''''), DaysDelayed, PlannedDelivery, TradeDate

				, ISIN, Asset, Qty, Price, PriceCurrency, Volume11, Operation, SubaccName, OwnerName, CounterParty, Sales'

			+ ' from ##opened_otc2 where IsClient = 0 order by DaysDelayed desc, AgreeNum, Id'

		exec(@sql)



		--declare @NotifyEmail varchar(1024) = null

		--declare @NotifyMessage varchar(max)

		--declare @NotifyTitle varchar(1024) = null



		set @NotifyMessage = cast(

		(

			select --'//1\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//1\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + iif(tt.IsClient = 0, 'no', 'yes')-- isClientDeal

				+ '//1\\' + isnull(t.AgreeNum,'') collate Cyrillic_General_CI_AS

				--+ '//1\\' + isnull(tp.ExternalNum,'') collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(cast(t.id as int) as varchar)

				--+ '//2\\' + isnull(nullif(cast(t.CpTrade_ID as varchar), '-1'), '')

				+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + cast(cast(cast(iif(t.Isrepo2 = 'y',t.PayPlannedDate, t.PutPlannedDate) as varchar) as date) as varchar) --PlannedDelivery

				+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + iif(t.BuySell = 1, 'Buy', 'Sell') --Operation

				+ '//2\\' + a.ISIN

				+ '//2\\' + a.ShortName collate Cyrillic_General_CI_AS --Asset

				+ '//2\\' + cast(t.Qty as varchar)

				+ '//2\\' + cast(cast(t.Price as decimal(32,2)) as varchar)

				+ '//2\\' + isnull(aPrice.ShortName, '') collate Cyrillic_General_CI_AS --PriceCurrency

				--+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

				+ '//2\\' + QORT_ARM_SUPPORT.dbo.fFloatToCurrency(t.Volume1)

				+ '//2\\' + s.SubAccCode collate Cyrillic_General_CI_AS

				+ '//2\\' + fo.FirmShortName collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				+ '//2\\' + isnull(fSl.Name, '') collate Cyrillic_General_CI_AS --Sales

				+ '//3\\'

				--, iif(fo.BOCode = '00001', 0, 1) isClientDeal

				--, t.CpTrade_ID

			from @tt tt

			inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

			left outer join QORT_BACK_DB.dbo.TradeProperties tp with (nolock) on tp.Trade_ID = t.id

			left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

			left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

			left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

			left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

			left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

			left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

			left outer join QORT_BACK_DB.dbo.Firms fSl with (nolock) on fSl.id = fo.Sales_ID

			--outer apply (select datediff(day, cast(cast(t.PutPlannedDate as varchar) as date), @ReportDate) DaysDelayed) dd

			outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

								when DaysDelayed < -@MaxDaysPercent then 0

								else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

								end * 100 / 2 / @MaxDaysPercent DelayPercent 

						) DelayPercent

			where tt.IsClient = 1 or (tt.IsClient = 0 and s.SubAccCode <> 'ARMBR_Subacc')

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

			--+ '<td>Report Date'

			--+ '</td><td>Counter Party'

			--+ '<td>Counter Party'

			--+ '</td><td>Is Client Trade'

			+ '<td>AgreeNum'

			--+ '<td>ExternalNum'

			+ '</td><td>Trade_ID'

			--+ '</td><td>Dealer Trade Id'

			+ '</td><td>Days Delayed'

			+ '</td><td>Planned Delivery'

			+ '</td><td>Trade Date'

			+ '</td><td>Operation'

			+ '</td><td>ISIN'

			+ '</td><td>Asset'

			+ '</td><td>Quantity'

			+ '</td><td>Price'

			+ '</td><td>Price Currency'

			+ '</td><td>Volume'

			+ '</td><td>Subacc'

			+ '</td><td>OwnerName'

			+ '</td><td>Counterparty'

			+ '</td><td>Sales'

			+ '</td></tr>' + @NotifyMessage + '</table>'





		set @delayedTradesDealer = (select count(*) from @tt tt where tt.DaysDelayed > 0 and IsClient = 1)

		set @NonDelayedTradesDealer = (select count(*) from @tt tt where tt.DaysDelayed <= 0 and IsClient = 1)

		set @delayedTradesClient = (select count(*) from @tt tt where tt.DaysDelayed > 0 and IsClient = 0)

		set @NonDelayedTradesClient = (select count(*) from @tt tt where tt.DaysDelayed <= 0 and IsClient = 0)



		--print @delayedTrades

		--print @NonDelayedTrades





		-- ЗАГЛУШКА - ПОКА ОТСЫЛАЕМ ТОЛЬКО НАМ

		

		set @NotifyTitle = 'OTC Opened Trades on ' + cast(@ReportDate as varchar) + ': ' 

			+ cast(@delayedTradesDealer + @NonDelayedTradesDealer + @delayedTradesClient + @NonDelayedTradesClient as varchar)

			+ iif(@delayedTradesDealer + @delayedTradesClient > 0, ', DELAYED: ' + cast(@delayedTradesDealer + @delayedTradesClient as varchar), '')



		-- само HTML-письмо

		set @NotifyMessage = '<html><body><p>'

			+ '<font color="red"/>' + iif(@delayedTradesDealer > 0, 'Delayed Dealer Trades: '+cast(@delayedTradesDealer as varchar)+'<br>', '')

			+ '<font color="red"/>' + iif(@delayedTradesClient > 0, 'Delayed Client Trades: '+cast(@delayedTradesClient as varchar)+'<br>', '')

			+ '<font color="green"/>' + iif(@NonDelayedTradesDealer > 0, 'On Time Dealer Trades: '+cast(@NonDelayedTradesDealer as varchar)+'<br>', '')

			+ '<font color="green"/>' + iif(@NonDelayedTradesClient > 0, 'On Time Client Trades: '+cast(@NonDelayedTradesClient as varchar)+'<br>', '')

			+ '<font color="black"/>Send notifications to: ' + @NotifyEmail + '</p>'

			+ @NotifyMessage

			+ '</body></html>'





		



		set @fileReport = @FilePath + @fileReport

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage

			, @file_attachments = @fileReport

			



		set @cmd = 'del "' + @FilePath + 'Report_Opened_OTC_Trades_*.*"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		print @NotifyTitle

		--print @NotifyMessage



	end



	

	if @SendMail = 1 and isnull(@IsClient, 0) = 0 



	begin



	Select distinct ROW_NUMBER () over (order by k.SalesID asc) as Num, 

	k.SalesID

	 into #tk 

	 from (select distinct salesID from @tt where salesID > 0) k

			--select * from #tk 

	declare @n int = cast ((select max (num) from #tk) as int)

	declare @salesID int

	declare @salesName varchar (250)

	--print @n



	while @n > 0



		begin



	set @salesID = CAST ((select salesID from #tk where num = @n) as int)

	set @salesName = CAST ((select name from QORT_BACK_DB.dbo.Firms where id = @salesID) as varchar (250))



	set	@NotifyEmail1 = cast (isnull((select email from QORT_BACK_DB.dbo.FirmContacts 

			where Contact_ID = @salesID and firm_ID = 2 and fct_const = 2),'') as varchar (1024))+';aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am'



		set @NotifyMessage1 = cast(

		(

			select --'//1\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//1\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + iif(tt.IsClient = 0, 'no', 'yes')-- isClientDeal

				+ '//1\\' + isnull(fSl.Name, '') collate Cyrillic_General_CI_AS

				--+ '//1\\' + isnull(tp.ExternalNum,'') collate Cyrillic_General_CI_AS

				+ '//2\\' + s.SubAccCode collate Cyrillic_General_CI_AS

				--+ '//2\\' + isnull(nullif(cast(t.CpTrade_ID as varchar), '-1'), '')

				+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + fo.FirmShortName collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(cast(cast(iif(t.Isrepo2 = 'y',t.PayPlannedDate, t.PutPlannedDate) as varchar) as date) as varchar) --PlannedDelivery

				+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + iif(t.BuySell = 1, 'Buy', 'Sell') --Operation

				+ '//2\\' + a.ISIN

				+ '//2\\' + a.ShortName collate Cyrillic_General_CI_AS --Asset

				+ '//2\\' + cast(t.Qty as varchar)

				+ '//2\\' + cast(cast(t.Price as decimal(32,2)) as varchar)

				+ '//2\\' + isnull(aPrice.ShortName, '') collate Cyrillic_General_CI_AS --PriceCurrency

				--+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

				+ '//2\\' + QORT_ARM_SUPPORT.dbo.fFloatToCurrency(t.Volume1)

				--+ '//2\\' + s.SubAccCode collate Cyrillic_General_CI_AS			

				+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				+ '//2\\' + isnull(t.AgreeNum,'') collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(cast(t.id as int) as varchar)

				+ '//3\\'

				--, iif(fo.BOCode = '00001', 0, 1) isClientDeal

				--, t.CpTrade_ID

			from @tt tt

			inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = tt.tradeId

			left outer join QORT_BACK_DB.dbo.TradeProperties tp with (nolock) on tp.Trade_ID = t.id

			left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

			left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

			left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

			left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

			left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

			left outer join QORT_BACK_DB.dbo.Firms fCp with (nolock) on fCp.id = t.CpFirm_ID

			left outer join QORT_BACK_DB.dbo.Firms fSl with (nolock) on fSl.id = fo.Sales_ID

			--outer apply (select datediff(day, cast(cast(t.PutPlannedDate as varchar) as date), @ReportDate) DaysDelayed) dd

			outer apply (select case when DaysDelayed > @MaxDaysPercent then @MaxDaysPercent + @MaxDaysPercent

								when DaysDelayed < -@MaxDaysPercent then 0

								else @MaxDaysPercent + @MaxDaysPercent * DaysDelayed / @MaxDaysPercent

								end * 100 / 2 / @MaxDaysPercent DelayPercent 

						) DelayPercent

			where s.SubAccCode <> 'ARMBR_Subacc' and tt.SalesID = @salesID

			order by DaysDelayed desc, AgreeNum, tt.tradeId

			for xml path('')

		) as varchar(max))



		set @NotifyMessage1 = replace(@NotifyMessage1, '//1\\', '<tr><td>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//2\\', '</td><td>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//3\\', '</td></tr>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//4\\', '</td><td ')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//5\\', '>')



		-- заголовки HTML-таблицы

		set @NotifyMessage1 = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			--+ '<td>Report Date'

			--+ '</td><td>Counter Party'

			--+ '<td>Counter Party'

			--+ '</td><td>Is Client Trade'

			+ '<td>Sales'

			--+ '<td>ExternalNum'

			+ '</td><td>ID'

			--+ '</td><td>Dealer Trade Id'

			+ '</td><td>Days Delayed'

			+ '</td><td>Client'

			+ '</td><td>Planned Delivery'

			+ '</td><td>Trade Date'

			+ '</td><td>Operation'

			+ '</td><td>ISIN'

			+ '</td><td>Asset'

			+ '</td><td>Quantity'

			+ '</td><td>Price'

			+ '</td><td>Price Currency'

			+ '</td><td>Volume'

			+ '</td><td>Counterparty'

			+ '</td><td>AgreeNum'

			+ '</td><td>Trade_ID'

			+ '</td></tr>' + @NotifyMessage1 + '</table>'





		set @delayedTradesDealer = (select count(*) from @tt tt where tt.DaysDelayed > 0 and IsClient = 1)

		set @NonDelayedTradesDealer = (select count(*) from @tt tt where tt.DaysDelayed <= 0 and IsClient = 1)

		set @delayedTradesClient = (select count(*) from @tt tt where tt.DaysDelayed > 0 and IsClient = 0)

		set @NonDelayedTradesClient = (select count(*) from @tt tt where tt.DaysDelayed <= 0 and IsClient = 0)



		--print @delayedTrades

		--print @NonDelayedTrades





		-- ЗАГЛУШКА - ПОКА ОТСЫЛАЕМ ТОЛЬКО НАМ

		

		set @NotifyTitle1 = 'INFO for '+@salesName+': DELAYED Trades on ' + cast(@ReportDate as varchar)-- + ': ' 

			--+ cast(@delayedTradesDealer + @NonDelayedTradesDealer + @delayedTradesClient + @NonDelayedTradesClient as varchar)

			--+ iif(@delayedTradesDealer + @delayedTradesClient > 0, ', DELAYED: ' + cast(@delayedTradesDealer + @delayedTradesClient as varchar), '')



		-- само HTML-письмо

		set @NotifyMessage1 = '<html><body><p>'

			--+ '<font color="red"/>' + iif(@delayedTradesDealer > 0, 'Delayed Dealer Trades: '+cast(@delayedTradesDealer as varchar)+'<br>', '')

			--+ '<font color="red"/>' + iif(@delayedTradesClient > 0, 'Delayed Client Trades: '+cast(@delayedTradesClient as varchar)+'<br>', '')

			--+ '<font color="green"/>' + iif(@NonDelayedTradesDealer > 0, 'On Time Dealer Trades: '+cast(@NonDelayedTradesDealer as varchar)+'<br>', '')

			--+ '<font color="green"/>' + iif(@NonDelayedTradesClient > 0, 'On Time Client Trades: '+cast(@NonDelayedTradesClient as varchar)+'<br>', '')

			--+ '<font color="black"/>Send notifications to: ' + @NotifyEmail + '</p>'

			+ @NotifyMessage1

			+ '</body></html>'





		



	--	set @fileReport = @FilePath + @fileReport

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail1

			, @subject = @NotifyTitle1

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage1

			--, @file_attachments = @fileReport



			set @n = @n - 1

			end



	end



	if OBJECT_ID('tempdb..##opened_otc2', 'U') is not null drop table ##opened_otc2



END

