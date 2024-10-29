









--exec QORT_ARM_SUPPORT.dbo.reportForSales @SelectData = 1

--exec QORT_ARM_SUPPORT.dbo.reportForSales @SendMail = 0



CREATE PROCEDURE [dbo].[reportForSales]

	@SelectData bit = 0

	, @SendMail bit = 1 -- включена отправка

	, @NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;qort@armbrok.am;viktor.dolzhenko@armbrok.am;'

	, @IsClient bit = null

	--, @NotifyEmail1 varchar(1024) = 'qortsupport@armbrok.am;aleksandr.mironov@armbrok.am;'

AS

BEGIN



begin try



		if nullif(@NotifyEmail, '') is null set @NotifyEmail = 'aleksandr.mironov@armbrok.am'--;qortsupport@armbrok.am;

	--set @cmd = 'del "' + @FilePath + 'Report_Opened_OTC_Trades_*.*"'

	--exec master.dbo.xp_cmdshell @cmd, no_output

	

	declare @Message varchar (max)



	declare @ReportDate date = getdate()

	--set @ReportDate = '20230701'

	declare @ReportDateInt int = cast(convert(varchar, @ReportDate, 112) as int)

	

	declare @NotifyMessage varchar(max)



	declare @NotifyTitle varchar(1024) = null



	declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports'

	if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

	declare @Sheet varchar(32) = 'Trades'

	declare @fileTemplate varchar(512) = 'templateTradesWeekly#.xlsx'

	declare @fileReport varchar(512) = 'TradesWeekly#'+cast(DATEPART(week,dateadd(DAY, -8, GETDATE())) as varchar(12))+'.xlsx'

	declare @cmd varchar(512)

	declare @sql varchar(1024)





declare @date as int = cast(convert(varchar, dateadd(DAY, -8, GETDATE()), 112) as int)



if OBJECT_ID('tempdb..##t', 'U') is not null drop table ##t



select frs.Name Sales

, iif(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(isnull(tri.Date,'')) = '','-', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(isnull(tri.Date,''))) OrderDate

, ISNULL(tri.RegisterNum,'-') OrderNum

, sa.SubAccCode ClientCode 

, fr.name Client

, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar (tr.TradeDate) TradeDate

, IIF(tr.BuySell = 1, 'BUY', 'SELL') Operation

, iif(ass.ISIN = '','-', ass.ISIN )ISIN

, ass.ShortName Asset

, iif(ass.isin = '', format(cast(tr.Qty as float),'F2'), format(cast(tr.Qty as float),'F0')) Quantity

, tr.Price Price

, asss.ShortName PriceCurrency

, cast(tr.Volume1 as decimal (32,2)) Volume

, frss.Name Counterparty

, tr.id Trade_ID

, iif(tr.AgreeNum = '','-', tr.AgreeNum) AgreeNum

into ##t

from QORT_BACK_DB..Trades tr



left outer join QORT_BACK_DB..Subaccs sa on sa.id = tr.SubAcc_ID

left outer join QORT_BACK_DB..Firms fr on fr.id = sa.OwnerFirm_ID

left outer join QORT_BACK_DB..Firms frs on frs.id = fr.Sales_ID

left outer join QORT_BACK_DB..Securities sec on sec.id = tr.Security_ID

left outer join QORT_BACK_DB..Assets ass on ass.id = sec.Asset_ID

left outer join QORT_BACK_DB..Assets asss on asss.id = tr.CurrPriceAsset_ID

left outer join QORT_BACK_DB..Firms frss on frss.id = tr.CpFirm_ID

left outer join QORT_BACK_DB..TradeInstrLinks trl on trl.Trade_ID = tr.id

left outer join QORT_BACK_DB..TradeInstrs tri on tri.id = trl.TradeInstr_ID

where fr.Sales_ID = 618 -- ID Viktor Dolzhenko

	and tr.TradeDate > @date

	and trl.Trade_ID is not null

	select * from ##t



	set @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FilePath + @fileReport + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A1:P1000000]'')

			select Sales, OrderDate, OrderNum, ClientCode, Client, TradeDate, Operation, ISIN, Asset, Quantity, Price, PriceCurrency, Volume, Counterparty, Trade_ID, AgreeNum'

			+ ' from ##t'

		exec(@sql)



				set @NotifyMessage = cast(

		(

			select --'//1\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//1\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + iif(tt.IsClient = 0, 'no', 'yes')-- isClientDeal

				+ '//1\\' + tt.Sales collate Cyrillic_General_CI_AS
				--+ '//1\\' + isnull(tp.ExternalNum,'') collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.OrderDate as varchar)

				+ '//2\\' + tt.OrderNum collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.ClientCode collate Cyrillic_General_CI_AS

				--+ '//2\\' + isnull(nullif(cast(t.CpTrade_ID as varchar), '-1'), '')

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + tt.Client collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.TradeDate as varchar) collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Operation collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.ISIN collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Asset collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.Quantity as varchar) collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.Price as varchar) collate Cyrillic_General_CI_AS

				--+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

				+ '//2\\' + tt.PriceCurrency collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.Volume as varchar) collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Counterparty collate Cyrillic_General_CI_AS

				+ '//2\\' + cast(tt.Trade_ID as varchar)

				+ '//2\\' + tt.AgreeNum collate Cyrillic_General_CI_AS

				+ '//3\\'

				--, iif(fo.BOCode = '00001', 0, 1) isClientDeal

				--, t.CpTrade_ID

			from ##t tt

			

			

			order by TradeDate desc

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

			+ '<td>Sale'

			--+ '<td>ExternalNum'

			+ '</td><td>OrderDate'

			+ '</td><td>OrderNum'

			+ '</td><td>ClientCode'

			+ '</td><td>Client'

			+ '</td><td>TradeDate'

		--	+ '</td><td>Operation'

			+ '</td><td>Operation'

			+ '</td><td>ISIN'

			+ '</td><td>Asset'

			+ '</td><td>Quantity'

			+ '</td><td>Price'

			+ '</td><td>Price Currency'

			+ '</td><td>Volume'

			+ '</td><td>Counterparty'

			+ '</td><td>Trade_ID'

			+ '</td><td>AgreeNum'

		--	+ '</td><td>Sales'

			+ '</td></tr>' + @NotifyMessage + '</table>'

			set @fileReport = @FilePath + @fileReport

			set @NotifyTitle = 'Weekly Report #'+cast(DATEPART(week,dateadd(DAY, -8, GETDATE())) as varchar(12))

			     +' ('+QORT_ARM_SUPPORT.dbo.fIntToDateVarchar (@date)

			     +'-'+QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(convert(varchar, GETDATE(), 112)-1)+') for sales: Viktor Dolzhenko'



		

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'qort-sql-mail'--'qort-test-sql'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage

			, @file_attachments = @fileReport





	



end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END

