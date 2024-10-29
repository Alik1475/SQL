













-- exec QORT_ARM_SUPPORT.dbo.CheckClientsTariff

CREATE PROCEDURE [dbo].[CheckClientsTariff]

	--@SelectData bit = 0

      @SendMail bit = 0

	 

	 ,@NotifyEmail varchar(1024) = 'backoffice@armbrok.am;accounting@armbrok.am;onboarding@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;aleksandr.mironov@armbrok.am;'

AS



BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках

		declare @CuridClientsTariffHist int -- текущее значение ID таблицы dbo.TradeHist		

		declare @OldidClientsTariffHist int -- предыдущее значение ID таблицы dbo.TradeHist

		declare @SendMail1 bit = 0



		--IF OBJECT_ID('QORT_ARBACK_DB_TEST.dbo.IDSubaccsHistForCheckTerminated', 'U') IS NOT NULL delete from QORT_ARBACK_DB_TEST.dbo.IDSubaccsHistForCheckTerminated;

		--update  QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated set idClientsTariffHist = 3416 -- временно для тестов



		select  @OldidClientsTariffHist = r.idClientsTariffHist					-- забираем из внешней таблицы последнее значение ID

		from QORT_ARM_SUPPORT..IDSubaccsHistForCheckTerminated r

			

		select @CuridClientsTariffHist = max(h.id)

		from QORT_BACK_DB.dbo.ClientTariffsHist h -- определяем текущее значение ID

	

		if @CuridClientsTariffHist = @OldidClientsTariffHist begin -- прерывание, если нет изменений

		print 'новых нет'

		return 

		end

		



-- Список изменений с нумерацией. Таблица #SubAcc.

	

		IF OBJECT_ID('tempdb.dbo.#SubAcc ', 'U') IS NOT NULL DROP TABLE #SubAcc;

		IF OBJECT_ID('tempdb.dbo.#t3 ', 'U') IS NOT NULL DROP TABLE #t3;

		select

			ROW_NUMBER() OVER(PARTITION BY Firm_ID ORDER BY id ASC) as Num

			,Founder_ID

			,id

			,Firm_ID

			,Tariff_ID

		into #SubAcc

		from QORT_BACK_DB..ClientTariffsHist q

		where

			id>@OldidClientsTariffHist --and ACSTAT_Const in (7,12)--берем только с типом счета закрыт или планируется закрытие

		order by 

			Firm_ID;



WITH RankedData AS (

    SELECT 

        a.Num,

        a.Founder_ID,

        a.id,

        a.Firm_ID,

        a.Tariff_ID,     

        b.id AS MatchingID,

        b.Founder_ID AS Founder_IDold,

        b.Tariff_ID AS Tariff_IDold,

        ROW_NUMBER() OVER (PARTITION BY a.ID ORDER BY b.id desc) AS rn

    FROM 

        #SubAcc a  -- Замените на название вашей верхней таблицы

    LEFT JOIN 

        QORT_BACK_DB..ClientTariffsHist b  -- Замените на название вашей нижней таблицы

    ON 

        a.Firm_ID = b.Firm_ID

    WHERE 

       a.id >= b.id

),

MaxNum AS (

    SELECT 

        id,

        MAX(rn) AS MaxRN

    FROM 

        RankedData

    GROUP BY 

        id

)



SELECT 

    r.rn,

    r.Founder_ID,

    r.id,

    r.Firm_ID,

    r.Tariff_ID,

r.MatchingID,

    r.Founder_IDold,

    r.Tariff_IDold,

    COALESCE(m.MaxRN, 0) AS Num  -- Помещаем максимальное значение rn или 0, если его нет

INTO #t3

FROM 

    RankedData r

LEFT JOIN 

    MaxNum m ON r.id = m.id;





select * from #SubAcc 

	select * from #t3 order by id

	delete from #t3 where not (rn = 2 or (rn = 1 and Num = 1));

	

	select * from #t3 



	set @SendMail = 0





	if exists (select ID from #T3) begin set @SendMail = 1 end-- else return



	if @SendMail = 1 begin

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024)

		select @NotifyTitle = STRING_AGG(s.FirmShortName, ', ') 

		from #t3 ab

		left outer join QORT_BACK_DB..Firms s on s.id = ab.Firm_ID

		

		--print @NotifyTitle

	set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(cast(f.FirmShortName as varchar) collate Cyrillic_General_CI_AS ,'-')

				+ '//2\\' + cast (isnull(sub.SubAccCode,'pls add!') as varchar) 

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + isnull(cast(sub.ConstitutorCode as varchar),'pls add!')

				+ '//2\\' + isnull(cast (sub.Comment as varchar),'pls add!')

				+ '//2\\' + case when tt.Founder_ID <> tt.Founder_IDold

								then 'New tariff for client: ' + isnull(tar.Name,'-') + ' '

								else '' end

						  + case when tt.Tariff_ID <> tt.Tariff_IDold

								then 'Tariff plan change(without change tariff): ' + '"' + isnull(tar1.Name,'-') + '"' + ' to ' + '"' + isnull(tar.Name,'-') + '"'

								else '' end	

						+ case when tt.Num  = 1

								then 'Tariff plan for new client: ' + '"' + isnull(tar.Name,'-') + '"'

								else '' end	

						+ case when tt.Num  <> 1 and tt.Tariff_ID = tt.Tariff_IDold and tt.Founder_ID = tt.Founder_IDold

								then 'Other changes'

								else '' end	

				+ '//2\\' + 'From: ' + dbo.fIntToDateVarcharShort(isnull(Hst.StartDate,0))+ ' to ' + iif(isnull(cast(Hst.EndDate as varchar), 0) = 0, ' "Indef."', dbo.fIntToDateVarcharShort(isnull(Hst.EndDate, 0)))

				--+ '//2\\' + isnull(cast(tt.Founder_ID as varchar),'-')

				+ '//2\\' + isnull(cast (u.last_name as varchar),'') + isnull(cast (u.first_name as varchar),'')

				+ '//2\\' + cast(dbo.fIntToDateVarcharShort(isnull(Hst.modified_date, 0)) as varchar)

				+ '//2\\' + cast(dbo.fIntToTimeVarchar(isnull(Hst.modified_time, 0)) as varchar)		

				--+ '//2\\' + cast(s.OwnerFirm_ID as varchar) 	

				+ '//2\\' + isnull(cast(f1.Name as varchar),'pls add!')--collate Cyrillic_General_CI_AS

				

				 --Operation

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARBACK_DB_TEST.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARBACK_DB_TEST.dbo.CheckTradeAssetsSanction

			from #t3 tt

			left outer join QORT_BACK_DB..ClientTariffsHist Hst on Hst.id = tt.id

			left outer join QORT_BACK_DB..Subaccs sub on sub.id = Hst.PutSubacc_ID

			left outer join QORT_BACK_DB..Firms f on f.id = tt.Firm_ID

			left outer join QORT_BACK_DB..ClientTariffsHist tr on tr.id = tt.id

			left outer join QORT_BACK_DB..Firms f1 on f1.id = f.Sales_ID

			left outer join QORT_BACK_DB..Tariffs  tar on tar.id = Hst.Tariff_ID

			left outer join QORT_BACK_DB..Tariffs  tar1 on tar1.id = tt.Tariff_IDold

			left outer join QORT_BACK_DB..Users  u on u.id = Hst.user_modified

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'Dear Colleagues,<br/><br/><b>The following customer accounts have undergone a change in their tariff plans. Please check the accuracy of the changes and take note accordingly.<br/><br/><br/><br/><b> Client details below:<br/>'

			+'<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Client'

			+ '</td><td>SubAccCode'

			+ '</td><td>CustomerCode'

			+ '</td><td>ArmsoftCode'

			+ '</td><td>Modification History'

			+ '</td><td>Validity period'

			--+ '</td><td>NEW_Status'

			+ '</td><td>Modifying user'

			+ '</td><td>Modified date'

			+ '</td><td>Modified time'

			+ '</td><td>Sales'

			/*+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage + '</table>'



	set @NotifyTitle = 'Changes to Customer Account Tariff Plans - ' + @NotifyTitle 

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'--'qort-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



			end -- конец блока отправки сообщения

		

	--return

			--Обновляем значение в счетчике текущего ID таблицы изменений сделок.

	--IF OBJECT_ID('QORT_ARBACK_DB_TEST.dbo.IDSubaccsHistForCheckTerminated', 'U') IS NOT NULL delete from QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated;

	update QORT_ARM_SUPPORT.dbo.IDSubaccsHistForCheckTerminated set idClientsTariffHist = @CuridClientsTariffHist

	

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END



