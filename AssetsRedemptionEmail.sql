









-- exec QORT_ARM_SUPPORT_test.dbo.AssetsRedemptionEmail

CREATE PROCEDURE [dbo].[AssetsRedemptionEmail]





AS



BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)



		declare @Message varchar(1024)



		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Firms_ARM\Clients_from_register_apgrade.xlsx';

		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\test\Copy of Clients_from_register_apgrade.xlsx';

		--declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Copy of Clients_from_register_apgrade.xlsx'

	   -- declare @Sheet1 varchar(64) = 'Sheet1' 



		declare @SendMail bit = 0

		declare @Result varchar(128) 

		declare @NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;'--sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;armine.khachatryan@armbrok.am;dianna.petrosyan@armbrok.am;anahit.titanyan@armbrok.am'





		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



		select 'Coupon' as EventType, cp.EndDate RedemtionDate, ass.ISIN,ass.ViewName Insrument, f.Name EmitentAsset, ass.Country Country

	

		into #t

		from QORT_BACK_DB_UAT.dbo.Coupons CP

		inner join QORT_BACK_DB_UAT.dbo.Assets ass on ass.id = CP.Asset_ID

		inner join QORT_BACK_DB_UAT.dbo.Firms f on f.id = ass.EmitentFirm_ID

		where CP.EndDate = @todayInt

		select * from #t 



	-- начало блока отпраки сообщений

	--declare @SendMail bit = 0

	set @SendMail = 0 

	if exists (select redemtionDate from #t) begin

	set @SendMail = 1

	end

	print @sendmail



	if @SendMail = 1 begin



		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(t.EventType,'NULL')

			--iif(tt.Issue_date is NULL, 'NULL', cast(convert(tt.Issue_date,105 ) as varchar))

				+ '//2\\' + cast(try_convert(int,t.RedemtionDate,105) as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + isnull(a.ConstitutorCode,t.CustomerCode)

				+ '//2\\' + t.ISIN

				+ '//2\\' + t.Insrument 

				+ '//2\\' + t.EmitentAsset

				+ '//2\\' + t.Country 

			--	+ '//2\\' + t.EngName

			--	+ '//2\\' + tt.Result

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

			--	+ '//2\\' + tt.ResultColor

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

			+ '<td>EventType'

			+ '</td><td>RedemtionDate'

			+ '</td><td>ISIN'

			+ '</td><td>Instrument'

			+ '</td><td>EmitentAsset'

			+ '</td><td>Country'

		--	+ '</td><td>Nominal(Bloomberg)'

		--	+ '</td><td>Nominal(Qort)'

		--	+ '</td><td>MaturityDate(Bloomberg)'

		--	+ '</td><td>MaturityDate(Qort)'

		--	+ '</td><td>Issuer(Bloomberg)'

		--	+ '</td><td>Issuer(Qort)'

		--	+ '</td><td>Sanction'

		--	+ '</td><td>SanctionQ'

		--	+ '</td><td>Result' 

			+ '</tr>' + @NotifyMessage + '</table>'



	--		set @fileReport = @FilePath + @fileReport

	set @NotifyTitle = 'Alert!!! Assets with redemtion today'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-test-sql' --'qort-sql-mail'

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

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END

