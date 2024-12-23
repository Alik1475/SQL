

--exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1



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

		declare @NotifyEmail varchar(1024) = 'backoffice@armbrok.am;QORT@armbrok.am;aleksey.yudin@armbrok.am;'--;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;''aleksandr.mironov@armbrok.am'





				-- Удаляем временную таблицу перед первым использованием

				IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;



				-- Создаём временную таблицу один раз

				CREATE TABLE #t (

					id INT,

					RepoTrade_ID INT,

					CpName VARCHAR(255),

					Insrument VARCHAR(255),

					EmitentAsset VARCHAR(255),

					ISIN VARCHAR(255),

					RepoType VARCHAR(50),

					Qty DECIMAL(18, 2),

					Volume1 DECIMAL(18, 2),

					Cname VARCHAR(50),

					RepoRate DECIMAL(10, 2),

					RedemtionDate int,

					EventType VARCHAR(50),

					PayAmountCoupon float,

					CurCoupon VARCHAR(50)

				);



				-- Добавляем строки в таблицу

				INSERT INTO #t

				SELECT tr.id

					, Tr.RepoTrade_ID

					, fcp.Name CpName	

					, ass.ViewName Insrument

					, f.Name EmitentAsset

					, ass.ISIN

					, IIF((tr.IsRepo2 = 'n' AND Tr.BuySell = 1) OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 2), 'Reverse', 'Direct') RepoType

					, Tr.Qty

					, Tr.Volume1

					, AssCur.Name Cname

					, Tr.RepoRate

					, cp.EndDate RedemtionDate

					, 'Coupon' as EventType

					, cp.Volume*Tr.Qty PayAmountCoupon

					, f1.Name CurCoupon

				FROM QORT_BACK_DB.dbo.Coupons CP

				INNER JOIN QORT_BACK_DB.dbo.Assets ass ON ass.id = CP.Asset_ID

				INNER JOIN QORT_BACK_DB.dbo.Firms f ON f.id = ass.EmitentFirm_ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets f1 ON f1.id = ass.BaseCurrencyAsset_ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Securities sec ON sec.Asset_ID = CP.Asset_ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Trades Tr ON Tr.Security_ID = sec.id

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms fcp ON fcp.ID = Tr.CpFirm_ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets AssCur ON AssCur.id = Tr.CurrPayAsset_ID

				WHERE CP.EndDate >= @todayInt AND CP.EndDate <= @WeekInt and

				 Tr.VT_Const NOT IN(12, 10)

				AND Tr.Enabled <> Tr.id

				AND Tr.TT_Const IN (6, 3)

				AND Tr.PutDate = 0

				AND Tr.IsDraft = 'n'

				AND ((tr.IsRepo2 = 'n' AND Tr.BuySell = 1) OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 2));

			

				-- Добавляем строки второй частью запроса

				INSERT INTO #t

				SELECT tr.id

					, Tr.RepoTrade_ID

					, fCp.Name	CpName

					, a.ViewName Insrument

					, '-' EmitentAsset

					, a.ISIN

					, IIF(Tr.BuySell = 1, 'Buy', 'Sell') RepoType

					, Tr.Qty

					, Tr.Volume1

					, AssCur.Name Cname

					, 0 as RepoRate

					, a.CancelDate RedemtionDate

					, 'Option' as EventType

					, 0 PayAmountCoupon

					, '-' CurCoupon

				FROM QORT_BACK_DB.dbo.Assets a

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Securities secA ON secA.Asset_ID = a.ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Trades Tr ON Tr.Security_ID = secA.id

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets AssCur ON AssCur.id = Tr.CurrPayAsset_ID

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms fcp ON fcp.ID = Tr.CpFirm_ID

				WHERE a.AssetClass_Const IN (4)

				AND a.CancelDate >= @todayInt

				AND a.CancelDate <= @WeekInt

				AND Tr.VT_Const NOT IN (12, 10)

				AND Tr.Enabled <> Tr.id

				--AND Tr.TT_Const IN (6, 3)

				--AND Tr.PutDate = 0

				AND Tr.IsDraft = 'n';



				-- Выводим результаты

				SELECT * FROM #t; 















	-- начало блока отпраки сообщений

	

	

	if exists (select id from #t) and @SendMail = 1  begin





		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + cast(t.id as varchar(16))+'/'+iif(t.RepoTrade_ID <= 0, '', cast(t.RepoTrade_ID  as varchar(16)))

			--iif(tt.Issue_date is NULL, 'NULL', cast(convert(tt.Issue_date,105 ) as varchar))

				--+ '//2\\' + t.id--+'/'+t.RepoTrade_ID

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + isnull(t.CpName, '-')

				+ '//2\\' + t.Insrument

				+ '//2\\' + t.EmitentAsset

				+ '//2\\' + t.ISIN

				+ '//2\\' + t.RepoType

				+ '//2\\' + cast(t.Qty as varchar(16))

				+ '//2\\' + cast(t.Volume1 as varchar(16))+cast(t.Cname as varchar(16))

				+ '//2\\' + iif(t.RepoRate = 0, '-', (cast(t.RepoRate as varchar(16))+'%'))

				+ '//2\\' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar (cast(try_convert(int,t.RedemtionDate,105) as varchar))

				+ '//2\\' + t.EventType	

				+ '//2\\' + iif(t.PayAmountCoupon = 0, '', cast(t.PayAmountCoupon  as varchar(16))) + cast(t.CurCoupon as varchar(16))

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

			+ '</td><td>EmitentAsset'

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
