













-- exec QORT_ARM_SUPPORT.dbo.CheckClientsTerminated

CREATE PROCEDURE [dbo].[CheckClientsTerminated]

	--@SelectData bit = 0

      @SendMail bit = 0

	 

	 ,@NotifyEmail varchar(1024) = 'backoffice@armbrok.am;accounting@armbrok.am;depo@armbrok.am;onboarding@armbrok.am;sales@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;aleksandr.mironov@armbrok.am;'

AS



BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках

		declare @CuridSubaccsHist int -- текущее значение ID таблицы dbo.TradeHist		

		declare @OldidSubaccsHist int -- предыдущее значение ID таблицы dbo.TradeHist

		declare @SendMail1 bit = 0



		--IF OBJECT_ID('QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated', 'U') IS NOT NULL delete from QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated;

		--insert into QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated (idSubaccsHist) values (5036) -- временно для тестов



		select  @OldidSubaccsHist = r.idSubaccsHist					-- забираем из внешней таблицы последнее значение ID

		from QORT_ARM_SUPPORT ..IDSubaccsHistForCheckTerminated r

			

		select @CuridSubaccsHist = max(h.id)

		from QORT_BACK_DB.dbo.SubaccsHist h -- определяем текущее значение ID

	

		if @CuridSubaccsHist = @OldidSubaccsHist begin -- прерывание, если нет изменений

		print 'новых нет'

		return 

		end

		



-- Список изменений с нумерацией. Таблица #SubAcc.

	

		IF OBJECT_ID('tempdb.dbo.#SubAcc ', 'U') IS NOT NULL DROP TABLE #SubAcc;

		select

			ROW_NUMBER() OVER(PARTITION BY Founder_ID ORDER BY id ASC) as Num

			,Founder_ID

			,id

			,ACSTAT_Const

		into #SubAcc

		from QORT_BACK_DB..SubaccsHist q

		where

			id>@OldidSubaccsHist and ACSTAT_Const in (7,12)--берем только с типом счета закрыт или планируется закрытие

		order by 

			Founder_ID

			

			select * from #SubAcc

			--return



-- Нумерация истории изменений по Subacc которые попали в Hist(были изменения) за весь период по счету. Новая таблица #SubAccNum



		IF OBJECT_ID('tempdb.dbo.#SubAccNum', 'U') IS NOT NULL DROP TABLE #SubAccNum;

		select

			ROW_NUMBER() OVER(PARTITION BY Founder_ID ORDER BY id ASC) as Num

			,Founder_ID

			, id

			, ACSTAT_Const

		into #SubAccNum

		from QORT_BACK_DB..SubaccsHist q

		 --left join #SubAcc su on su.id = q.id

		where

			Founder_ID in (select Founder_ID from #SubAcc group by Founder_ID) 

		order by 

			Founder_ID



		 delete from #SubAccnum where id in (select id from #SubAcc where Num>1) -- удаляем из списка записи, кроме одной самой первой в периоде.



			select * from #SubAccNum 

 

-- Сделки, в которых в последней записи в истории было изменение инструмента отличного от предпоследней записи. Таблица #TradesSec

			select

				Founder_ID as FID

				into #TradesSec

			from

				(select distinct

					a.Founder_ID

					,a.ACSTAT_Const

				from #SubAccNum a

					outer apply

					(select  MAX(Num)-1 as Num, Founder_ID from #SubAccNum group by Founder_ID) b

					outer apply

					(select MAX(Num) as Num, Founder_ID from #SubAccNum group by Founder_ID) c		

				where 

					(a.Num = b.Num and a.Founder_ID = b.Founder_ID) 

					or (a.Num = c.Num and a.Founder_ID = c.Founder_ID)	

				) t

			group by

				t.Founder_ID

			having

				count(t.Founder_ID) > 1 

	select * from #TradesSec

	

	set @SendMail = 0

	if exists (select FID from #TradesSec) begin set @SendMail = 1 end-- else return



	if @SendMail = 1 begin

		declare @NotifyMessage varchar(max)

				declare @NotifyTitle varchar(1024)

		select @NotifyTitle = STRING_AGG(s.SubaccName, ', ') 

		from #TradesSec ab

		left outer join QORT_BACK_DB..Subaccs s on s.id = ab.FID

		--print @NotifyTitle

	set @NotifyMessage = cast(

		(

			select '//1\\' + cast(s.SubaccName as varchar) collate Cyrillic_General_CI_AS 

				+ '//2\\' + cast (s.SubAccCode as varchar) 

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT_TEST.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + cast(s.ConstitutorCode as varchar)

				+ '//2\\' + cast (s.Comment as varchar)

				+ '//2\\' + isnull(cast (f2.DEPODivisionCode as varchar),'-')

				+ '//2\\' + isnull(cast(f2.DEPOCode as varchar),'-')

				+ '//2\\' + case s.ACSTAT_Const when 7 then 'Terminated'

												when 12 then 'In the process of terminating'

												else 'other type'

												end

				+ '//2\\' + isnull(cast (u.last_name as varchar),'') + isnull(cast (u.first_name as varchar),'')

				+ '//2\\' + cast(f.Email as varchar) 

				+ '//2\\' + cast(f.Phones as varchar) 			

				--+ '//2\\' + cast(s.OwnerFirm_ID as varchar) 	

				+ '//2\\' + isnull(cast(f1.Name as varchar),'-')--collate Cyrillic_General_CI_AS

				

				 --Operation

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

			from #TradesSec tt

			left outer join QORT_BACK_DB..Subaccs s on s.id = tt.FID

			left outer join QORT_BACK_DB..Firms f on f.id = s.OwnerFirm_ID

			left outer join QORT_BACK_DB..Users u on u.id = s.user_modified

			left outer join QORT_BACK_DB..Firms f1 on f1.id = f.Sales_ID

			left outer join QORT_BACK_DB..FirmDEPOAccs f2 on f2.Code = s.SubAccCode collate Cyrillic_General_CI_AS

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'Dear Colleagues,<br/><br/><b>The following customer account is in the process of being closed. Please, check the client’s balance and take appropriate actions.<br/><br/><br/><br/><b> Client details below:<br/>'

			+'<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Client'

			+ '</td><td>SubAccCode'

			+ '</td><td>CustomerCode'

			+ '</td><td>ArmsoftCode'

			+ '</td><td>DEPOLiteAccount'

			+ '</td><td>CDA_Account'

			+ '</td><td>NEW_Status'

			+ '</td><td>Modifying user'

			+ '</td><td>Email'

			+ '</td><td>Pnones'

			+ '</td><td>Sales'

			/*+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage + '</table>'



	set @NotifyTitle = 'Customer account closing - ' + @NotifyTitle 

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'--'qort-test-sql'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



			end -- конец блока отправки сообщения

		

	--return

			--Обновляем значение в счетчике текущего ID таблицы изменений сделок.

	--IF OBJECT_ID('QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated', 'U') IS NOT NULL delete from QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated;

	--insert into QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated (idSubaccsHist) values (@CuridSubaccsHist)

	update QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated set idSubaccsHist = @CuridSubaccsHist

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END



