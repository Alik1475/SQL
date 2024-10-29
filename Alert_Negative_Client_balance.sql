
-- exec QORT_ARM_SUPPORT.dbo.Alert_Negative_Client_balance @SendMail = 0

CREATE PROCEDURE [dbo].[Alert_Negative_Client_balance]
  	@SelectData bit = 0

	, @SendMail bit = 1 -- включена отправка

	, @NotifyEmail varchar(1024) = 'qort@armbrok.am;samvel.sahakyan@armbrok.am;lida.tadeosyan@armbrok.am'

	, @IsClient bit = null



AS

BEGIN



begin try



		if nullif(@NotifyEmail, '') is null set @NotifyEmail = 'aleksandr.mironov@armbrok.am'--;qortsupport@armbrok.am;



	

	declare @Message varchar (max)

	declare @ReportDate date = getdate()

	declare @ReportDateInt int = cast(convert(varchar, @ReportDate, 112) as int)

	

	declare @NotifyMessage varchar(max) 



	declare @NotifyTitle varchar(1024) = null



	



	declare @sql varchar(1024)





declare @date as int = cast(convert(varchar, dateadd(DAY, -8, GETDATE()), 112) as int)



if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



select sa.SubAccCode, fr.name ClientName, pos.VolFree,  ass.Name, acc.name accname, crs.Bid*pos.VolFree VolumeUSD, isnull(frs.Name,'-') Sales, cast(0 as float) TotalVolumeUSD, '' as Position



into #t

from QORT_BACK_DB..Position pos



left outer join QORT_BACK_DB..Subaccs sa on sa.id = pos.SubAcc_ID

left outer join QORT_BACK_DB..Firms fr on fr.id = sa.OwnerFirm_ID

left outer join QORT_BACK_DB..Firms frs on frs.id = fr.Sales_ID

left outer join QORT_BACK_DB..Assets ass on ass.id = pos.Asset_ID

left outer join QORT_BACK_DB..CrossRates crs on crs.TradeAsset_ID = pos.Asset_ID and InfoSource = 'MainCurBank'

left outer join QORT_BACK_DB..Accounts acc on acc.id = pos.Account_ID

	where ass.AssetType_Const in(3)-- 	Cash market

		and pos.VolFree not in (0)

		and LEFT(sa.SubAccCode,2) <> 'AB'

		and acc.name not in('ARMBR_MONEY_BLOCK')

	select * from #t



	SELECT 
  SubAccCode, ClientName, 
    SUM(VolumeUSD) AS TotalVolumeUSD, 
    STRING_AGG(CAST(dbo.fFloatToMoney2Varchar(VolFree) AS VARCHAR(50)) + Name, '; ') AS AllCurrencyPosition,
	Sales Sales
into #t2
     FROM #t
	-- where TotalVolumeUSD < 0
GROUP B
Y 
    SubAccCode, ClientName, Sales;

	select * from #t2 --return



				set @NotifyMessage = cast(

		(

			select --'//1\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//1\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + iif(tt.IsClient = 0, 'no', 'yes')-- isClientDeal

				+ '//1\\' + tt.ClientName collate Cyrillic_General_CI_AS

				--+ '//1\\' + isnull(tp.ExternalNum,'') collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.Sales collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.OrderNum collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.SubAccCode as varchar)

				--+ '//2\\' + isnull(nullif(cast(t.CpTrade_ID as varchar), '-1'), '')

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + tt.Client collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(dbo.fFloatToMoney2Varchar(tt.TotalVolumeUSD) as varchar) collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.Operation collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.ISIN collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.Asset collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.AllCurrencyPosition as varchar) collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Sales collate Cyrillic_General_CI_AS

				--+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

				--+ '//2\\' + tt.PriceCurrency collate Cyrillic_General_CI_AS

				--+ '//2\\' + cast(tt.Volume as varchar) collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.Counterparty collate Cyrillic_General_CI_AS

				--+ '//2\\' + cast(tt.Trade_ID as varchar)

				--+ '//2\\' + tt.AgreeNum collate Cyrillic_General_CI_AS

				+ '//3\\'

				--, iif(fo.BOCode = '00001', 0, 1) isClientDeal

				--, t.CpTrade_ID

			from #t2 tt

			where tt.TotalVolumeUSD < 0

			

			order by SubAccCode desc

			for xml path('')

		) as varchar(max))



		set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		-- заголовки HTML-таблицы

		set @NotifyMessage = 'This is an automatically generated message.</td><td>

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			--+ '<td>Report Date'

			--+ '</td><td>Counter Party'

			--+ '<td>Counter Party'

			--+ '</td><td>Is Client Trade'

			+ '<td>Owner of sub-account'

			--+ '<td>ExternalNum'

			+ '</td><td>Sub-account'

		--	+ '</td><td>OrderNum'

		--	+ '</td><td>ClientCode'

		--	+ '</td><td>Client'

		--	+ '</td><td>TradeDate'

		--	+ '</td><td>Operation'

		--	+ '</td><td>Operation'

		--	+ '</td><td>ISIN'

		--	+ '</td><td>Asset'

			+ '</td><td>Estimate position(USD)'

			+ '</td><td>AllCurrencyPosition'

			+ '</td><td>Sales'

		--	+ '</td><td>Volume'

		--	+ '</td><td>Counterparty'

		--	+ '</td><td>Trade_ID'

		--	+ '</td><td>AgreeNum'

		--	+ '</td><td>Sales'

			+ '</td></tr>' + @NotifyMessage + '</table>'

		--	set @fileReport = @FilePath + @fileReport

			set @NotifyTitle = 'Alert – Current Negative Balance – Client Positions'



		

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'qort-sql-mail'--'qort-test-sql'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body =  @NotifyMessage

			--, @file_attachments = @fileReport





	



end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END
