

--exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 0



CREATE PROCEDURE [dbo].[CheckRepoFor7daysCoupon]



	@SendMail bit 



	AS





BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @WeekDate date = DATEADD(DAY, +7, getdate())

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @WeekInt int = cast(convert(varchar, @WeekDate, 112) as int)



		declare @Message varchar(1024)



		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Firms_ARM\Clients_from_register_apgrade.xlsx';

		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\test\Copy of Clients_from_register_apgrade.xlsx';

		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Copy of Clients_from_register_apgrade.xlsx'

	   -- declare @Sheet1 varchar(64) = 'Sheet1' 



		declare @Result varchar(128) 

		declare @NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;aleksey.yudin@armbrok.am;QORT@armbrok.am'--;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;'





		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



		select tr.id

		, Tr.RepoTrade_ID

		, fcp.Name CpName	

		, ass.ViewName Insrument

		, f.Name EmitentAsset

		, ass.ISIN

		, iif((tr.IsRepo2 = 'n' and Tr.BuySell = 1) or (tr.IsRepo2 = 'y' and Tr.BuySell = 2), 'Reverse', 'Direct') RepoType

		, Tr.Qty

		, Tr.Volume1

		, AssCur.Name Cname

		, Tr.RepoRate

	    , cp.EndDate RedemtionDate

		, 'Coupon' as EventType

		, cp.Volume*Tr.Qty PayAmountCoupon

		, f1.Name CurCoupon

		into #t

		from QORT_BACK_DB.dbo.Coupons CP

		inner join QORT_BACK_DB.dbo.Assets ass on ass.id = CP.Asset_ID

		inner join QORT_BACK_DB.dbo.Firms f on f.id = ass.EmitentFirm_ID

		left outer join QORT_BACK_DB.dbo.Assets f1 on f1.id = ass.BaseCurrencyAsset_ID

		left outer join QORT_BACK_DB.dbo.Securities sec on sec.Asset_ID = CP.Asset_ID

		left outer join QORT_BACK_DB.dbo.Trades Tr on Tr.Security_ID = sec.id

		left outer join QORT_BACK_DB.dbo.Firms fcp on fcp.ID = Tr.CpFirm_ID

		left outer join QORT_BACK_DB.dbo.Assets AssCur on AssCur.id = Tr.CurrPayAsset_ID

		where CP.EndDate >= @todayInt and CP.EndDate <= @WeekInt

		and Tr.VT_Const not in(12,10) --сделка не расторгнута

		and Tr.Enabled <> Tr.id

		and Tr.TT_Const in(6,3) --OTC repo(6);Exchange repo(3)

		and Tr.PutDate = 0 -- не закрытые по бумагам сделки

		and Tr.IsDraft = 'n'

		and ((tr.IsRepo2 = 'n' and Tr.BuySell = 1) or (tr.IsRepo2 = 'y' and Tr.BuySell = 2))-- только сделки типа Reverse(когда бумаги у нас)

		select * from #t 



	-- начало блока отпраки сообщений

	

	

	if exists (select id from #t) and @SendMail = 1  begin





		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + cast(t.id as varchar(16))+'/'+cast(t.RepoTrade_ID as varchar(16))

			--iif(tt.Issue_date is NULL, 'NULL', cast(convert(tt.Issue_date,105 ) as varchar))

				--+ '//2\\' + t.id--+'/'+t.RepoTrade_ID

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + t.CpName

				+ '//2\\' + t.Insrument

				+ '//2\\' + t.EmitentAsset

				+ '//2\\' + t.ISIN

				+ '//2\\' + t.RepoType

				+ '//2\\' + cast(t.Qty as varchar(16))

				+ '//2\\' + cast(t.Volume1 as varchar(16))+cast(t.Cname as varchar(16))

				+ '//2\\' + cast(t.RepoRate as varchar(16))+'%'

				+ '//2\\' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar (cast(try_convert(int,t.RedemtionDate,105) as varchar))

				+ '//2\\' + t.EventType	

				+ '//2\\' + cast(t.PayAmountCoupon as varchar(16))+cast(t.CurCoupon as varchar(16))

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

		

			from #t t

				

			for xml path('')

		) as varchar(max))

		

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'is an automatically generated message.<br/><br/><b>'--Below is the result of reconciliation Register.xlsx VS Qort.<br/><br/><b> http://192.168.14.20/reports/report/QORT_PROD/Reconciliation/Reconciliatio_Clients_Statics'

		+ '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Trade_ID'

			+ '</td><td>Counterparty'

			+ '</td><td>Instrument'

			+ '</td><td>Instrument'

			+ '</td><td>ISIN'

			+ '</td><td>RepoType'

			+ '</td><td>Qty'

			+ '</td><td>Volume'

			+ '</td><td>RepoRate'

			+ '</td><td>RecordDate'

			+ '</td><td>EventType'

			+ '</td><td>Payment amount'

		--	+ '</td><td>Issuer(Qort)'

		--	+ '</td><td>Sanction'

		--	+ '</td><td>SanctionQ'

		--	+ '</td><td>Result' 

			+ '</tr>' + @NotifyMessage + '</table>'



	--		set @fileReport = @FilePath + @fileReport

	set @NotifyTitle = 'Alert!!! Trades with redemtion on 7 days'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



		--set @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"'

		--exec master.dbo.xp_cmdshell @cmd, no_output



		print @NotifyTitle

		--print @NotifyMessage

			end -- конец блока отправки сообщения

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END
