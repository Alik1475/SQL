









-- exec QORT_ARM_SUPPORT.dbo.CorrectPositionForAlertMoney

CREATE PROCEDURE [dbo].[CorrectPositionForAlertMoney]

	--@SelectData bit = 0

      @SendMail bit = 0

	 --,@NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;' --'backoffice@armbrok.am;accounting@armbrok.am;QORT@armbrok.am;viktor.dolzhenko@armbrok.am;' --aleksandr.mironov@armbrok.am; '

AS



BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках

		declare @CurIDTradeHist int -- текущее значение ID таблицы dbo.CorrectPositions		

		declare @OldIDTradeHist int -- предыдущее значение ID таблицы dbo.CorrectPositions

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

		declare @NotifyEmail varchar(1024)

		--insert into QORT_ARM_SUPPORT.dbo.IDCorrectPositionForAlertMoney (IDCorrectPositionHist) values (10000) -- временно для тестов



		select  @OldIDTradeHist = r.IDCorrectPositionHist  -- забираем из внешней таблицы последнее значение ID

		from QORT_ARM_SUPPORT..IDCorrectPositionForAlertMoney r

			

		select @CurIDTradeHist = max(h.id)

		from QORT_BACK_DB.dbo.CorrectPositions h -- определяем текущее значение ID

	

		if @CurIDTradeHist = @OldIDTradeHist begin -- прерывание, если нет изменений

		print 'новых нет'

		return 

		end



-- Список сделок, в которых менялся инструмент. Все сделки за весь период!

IF OBJECT_ID('tempdb.dbo.#Trades', 'U') IS NOT NULL DROP TABLE #Trades;



		-- блок формирования уведомления корректировках зачисления денег на счет клиента---

	declare @result table (Date varchar(32), SubAccCode varchar (32), Client_Name varchar (150), Type_Qort varchar(32), Type varchar(256), Size varchar (256), Sales varchar (250)

	, Correct_ID int, /*Comment2  varchar(256),*/ User_Created varchar(32), salesID int)

	insert into @result (Date, SubAccCode, Client_Name, Type_Qort, Type, Size, Sales

	, Correct_ID, /*Comment2,*/ User_Created, salesID)

select QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(corr.Date) Date

		, sub.SubAccCode SubAccCode

		, sub.SubaccName Client_Name

		, cast ((case when CT_Const = 6

				then 'Cash deposit'

				else '' 

				end) 

				as varchar (32)) Type_Qort

		, corr.Comment Type 

		, cast(cast(QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar (corr.Size) as varchar(32))+CAST(ass.Name as varchar(32)) as varchar(32)) Size

		, isnull(firS.Name, 'Unknow') Sales

		, corr.id Correct_ID

		--, corr.Comment2 Comment2

		, isnull(cast(users.first_name+users.last_name as varchar (32)), '') User_Created

		, IIF (ISNULL(fir.Sales_ID, 1) < 0, 1, ISNULL(fir.Sales_ID, 1))  salesID 

from QORT_BACK_DB..CorrectPositions corr

left outer join QORT_BACK_DB..Subaccs sub on sub.id = corr.Subacc_ID

left outer join QORT_BACK_DB..Assets ass on ass.id = corr.Asset_ID

left outer join QORT_BACK_DB..Firms fir on fir.id = sub.OwnerFirm_ID

left outer join QORT_BACK_DB..Firms firS on firS.id = fir.Sales_ID

left outer join QORT_BACK_DB..Users users on users.id = corr.CorrectedUser_ID

where 

	corr.id > @OldIDTradeHist

	and corr.created_date = @todayInt

	and corr.CT_Const in (6) -- 	Cash deposit

	and corr.IsCanceled = 'n'

	and sub.SubAccCode not in ('AB0001','AB0002')

	and corr.BackID not in (
			SELECT par.IntradayOperationId
			FROM QORT_ARM_SUPPORT.dbo.IntradayOperationId par
		)

	--and firS.Name in ('Viktor Dolzhenko', 'Elena Voronova')



select * from @result

	

	set @SendMail = 0

	if exists (select Correct_ID from @result) begin set @SendMail = 1 end



	if @SendMail = 1 begin

	Select distinct ROW_NUMBER () over (order by k.SalesID asc) as Num, 

	k.SalesID

	 into #tk 

	 from (select distinct salesID from @result where salesID > 0) k

			--select * from #tk 

	declare @n int = cast ((select max (num) from #tk) as int)

	declare @salesID int

	declare @salesName varchar (250)

	print @n

while @n > 0



		begin

		

	set @salesID = CAST ((select salesID from #tk where num = @n) as int)

	set @salesName = CAST ((select name from QORT_BACK_DB.dbo.Firms where id = @salesID) as varchar (250))

	set	@NotifyEmail = cast (isnull((select email from QORT_BACK_DB.dbo.FirmContacts 

			where Contact_ID = @salesID and firm_ID = 2 and fct_const = 2),'') as varchar (1024))+';backoffice@armbrok.am;accounting@armbrok.am;QORT@armbrok.am;'

	set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(tt.Date, '')

				+ '//2\\' + cast(tt.SubAccCode as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + isnull(tt.Client_Name, '')-- collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull(tt.Type_Qort, '') --collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Type, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Size, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Sales, '') -- collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + cast(isnull(tt.Correct_ID, '') as varchar (32)) -- collate Cyrillic_General_CI_AS

				--+ '//2\\' + isnull(tt.Comment2, '') --collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull (tt.User_Created, '') 

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

			from @result tt

			where salesID = @salesID

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport



	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'Client accounts have just been replenished:

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Date'

			+ '</td><td>SubAccCode'

			+ '</td><td>ClientName'

			+ '</td><td>Type_Qort'

			+ '</td><td>Description'

			+ '</td><td>Volume'

			+ '</td><td>Sales'

			+ '</td><td>ID_Correction'

		--	+ '</td><td>Comment'

			+ '</td><td>CorrectedUser'

			/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage + '</table>'



	set @NotifyTitle = 'Alert! Client accounts have been credited for sales '+ ISNULL(@salesName , '')

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

			--, @file_attachments = @fileReport

			set @n = @n - 1

	end -- конец блока отправки сообщения

 end

			

       --/*

			--Обновляем значение в счетчике текущего ID таблицы изменений сделок.

	IF OBJECT_ID('QORT_ARM_SUPPORT.dbo.IDCorrectPositionForAlertMoney', 'U') IS NOT NULL delete from QORT_ARM_SUPPORT.dbo.IDCorrectPositionForAlertMoney;

	insert into QORT_ARM_SUPPORT.dbo.IDCorrectPositionForAlertMoney (IDCorrectPositionHist) values (@CurIDTradeHist)

	--*/

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END
