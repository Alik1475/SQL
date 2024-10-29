







-- exec QORT_ARM_SUPPORT_TEST.dbo.CheckTradeAssetsSanction

CREATE PROCEDURE [dbo].[CheckTradeAssetsSanction]

	--@SelectData bit = 0

      @SendMail bit = 0

	 ,@NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am'--;sona.nalbandyan@armbrok.am;'

AS



BEGIN



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках

		declare @CurIDTradeHist int -- текущее значение ID таблицы dbo.TradeHist		

		declare @OldIDTradeHist int -- предыдущее значение ID таблицы dbo.TradeHist

	



		--insert into QORT_ARM_SUPPORT_TEST.dbo.IDTradeHistForCheckInstr (idtradehist) values (64000) -- временно для тестов



		select  @OldIDTradeHist = r.IDTradehist					-- забираем из внешней таблицы последнее значение Founder_ID

		from QORT_ARM_SUPPORT_TEST..IDTradeHistForCheckInstr r

			

		select @CurIDTradeHist = max(h.id)

		from QORT_BACK_DB_UAT.dbo.TradesHist h -- определяем текущее значение ID

	

		if @CurIDTradeHist = @OldIDTradeHist begin -- прерывание, если нет изменений

		print 'новых нет'

		return 

		end



-- Список сделок, в которых менялся инструмент. Все сделки за весь период!

IF OBJECT_ID('tempdb.dbo.#Trades', 'U') IS NOT NULL DROP TABLE #Trades;

select 

	Founder_ID

	into #Trades 

from QORT_BACK_DB_UAT..TradesHist 



where 

	Corrected_Date = @todayInt and id > @OldIDTradeHist



	



select * from #Trades order by Founder_ID



-- Нумерация истории изменений по найденным сделкам



IF OBJECT_ID('tempdb.dbo.#TradesNum', 'U') IS NOT NULL DROP TABLE #TradesNum;

select

	ROW_NUMBER() OVER(PARTITION BY Founder_ID ORDER BY id ASC) as Num

	,Founder_ID

	,Security_ID

	,Corrected_Date

	, id

into #TradesNum

from QORT_BACK_DB_UAT..TradesHist q

 

where

	Founder_ID in (select Founder_ID from #Trades group by Founder_ID) --having count(Founder_ID) > 1

order by 

	Founder_ID

 

	select * from #TradesNum -- сделки в которых менялся инструмент

 



-- Сделки, в которых в последней записи в истории было изменение инструмента отличного от предпоследней записи.

select

	Founder_ID as FID

	

	into #TradesSec

from

	(select distinct

		a.Founder_ID

		,a.Security_ID



	from #TradesNum a

		outer apply

		(select  MAX(Num)-1 as Num, Founder_ID from #TradesNum group by Founder_ID) b

		outer apply

		(select MAX(Num) as Num, Founder_ID from #TradesNum group by Founder_ID) c

		

	where 

		(a.Num = b.Num and a.Founder_ID = b.Founder_ID) 

		or (a.Num = c.Num and a.Founder_ID = c.Founder_ID)

		

	) t



group by

	t.Founder_ID

having

	count(t.Founder_ID) > 1 



	-------- добавляем сделки, которые имеют 1 изменение. это признак новой сделки---------

	insert into #TradesSec (FID) select Founder_ID from #TradesNum u where u.Num = 1 and u.Corrected_Date = @todayInt and u.id > @OldIDTradeHist

	

		

		-- блок формирования уведомления о сделке с бумагой в санкционном списке

			declare @result table (TradeDate int, TradeID int, ISIN varchar(16), AssetName varchar(32), IssueName varchar(256), ClientName varchar (256), SubAccCode varchar (40), CustomerCode varchar (30) )

insert into @result (TradeDate, TradeID, ISIN, AssetName, IssueName, ClientName, SubAccCode, CustomerCode)

	select TradeDate

	 ,f.ID TradeID

	 , k.ISIN ISIN

	 , k.ViewName AssetName

	 , v1.Name IssueName

	 , v.Name ClientName

	 , l.SubAccCode SubAccCode

	 , l.ConstitutorCode CustomerCode

	 

	from QORT_BACK_DB_UAT.dbo.Trades f

	inner join #TradesSec j on j.FID = f.id

	left outer join QORT_BACK_DB_UAT.dbo.Securities m on m.id = f.Security_ID

	left outer join QORT_BACK_DB_UAT.dbo.Assets k on k.id = m.Asset_ID

	left outer join QORT_BACK_DB_UAT.dbo.Subaccs l on f.SubAcc_ID = l.id

	left outer join QORT_BACK_DB_UAT.dbo.Firms v on l.OwnerFirm_ID = v.id

	left outer join QORT_BACK_DB_UAT.dbo.OrgCathegories o on o.id = v.OrgCathegoriy_ID

	left outer join QORT_BACK_DB_UAT.dbo.Firms v1 on k.EmitentFirm_ID = v1.id

	where k.IsInSanctionList = 'y'

	select * from @result-- order by ID



	set @SendMail = 0

	if exists (select tradeID from @result) begin set @SendMail = 1 end



	if @SendMail = 1 begin

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + cast(cast(cast(tt.TradeDate as varchar) as date) as varchar)

				+ '//2\\' + cast(tt.TradeID as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + cast (tt.ISIN as varchar)-- collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Assetname collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.IssueName collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.ClientName collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.SubAccCode collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + tt.CustomerCode collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.ClientName --collate Cyrillic_General_CI_AS

				--+ '//2\\' + iif(t.BuySell = 1, 'Buy', 'Sell') --Operation

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT_TEST.dbo.CheckTradeAssetsSanction

			from @result tt

			

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>TradeDate'

			+ '</td><td>TradeID'

			+ '</td><td>ISIN'

			+ '</td><td>AssetName'

			+ '</td><td>IssueName'

			+ '</td><td>ClientName'

			+ '</td><td>SubAccCode'

			+ '</td><td>CustomerCode'

			/*+ '</td><td>Price'

			+ '</td><td>PriceCurrency'

			+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage + '</table>'



	set @NotifyTitle = 'Alert!!! Securities for sanction list'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-test-sql'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



			end -- конец блока отправки сообщения



			-- блок формирования уведомления о сделке с бумагой выпущенной после 12.04.2022 и клиентом с признаком "Russian Person"

			declare @result2 table (TradeDate int, TradeID int, ISIN varchar(16), AssetName varchar(32), IssueName varchar(256), ClientName varchar (256), SubAccCode varchar (40), CustomerCode varchar (30) )

insert into @result2 (TradeDate, TradeID, ISIN, AssetName, IssueName, ClientName, SubAccCode, CustomerCode)

	select TradeDate

	 ,f.ID TradeID

	 , k.ISIN ISIN

	 , k.ViewName AssetName

	 , v1.Name IssueName

	 , v.Name ClientName

	 , l.SubAccCode SubAccCode

	 , l.ConstitutorCode CustomerCode

	 

	from QORT_BACK_DB_UAT.dbo.Trades f

	inner join #TradesSec j on j.FID = f.id

	left outer join QORT_BACK_DB_UAT.dbo.Securities m on m.id = f.Security_ID

	left outer join QORT_BACK_DB_UAT.dbo.Assets k on k.id = m.Asset_ID

	left outer join QORT_BACK_DB_UAT.dbo.Subaccs l on f.SubAcc_ID = l.id

	left outer join QORT_BACK_DB_UAT.dbo.Firms v on l.OwnerFirm_ID = v.id

	left outer join QORT_BACK_DB_UAT.dbo.OrgCathegories o on o.id = v.OrgCathegoriy_ID

	left outer join QORT_BACK_DB_UAT.dbo.Firms v1 on k.EmitentFirm_ID = v1.id

	where o.Name = 'Russian person' and k.EmitDate > 20220412

	select * from @result2-- order by ID



	set @SendMail = 0

	if exists (select tradeID from @result2) begin set @SendMail = 1 end



	if @SendMail = 1 begin

		declare @NotifyMessage2 varchar(max)

		declare @NotifyTitle2 varchar(1024) = null

	set @NotifyMessage2 = cast(

		(

			select '//1\\' + cast(cast(cast(tt.TradeDate as varchar) as date) as varchar)

				+ '//2\\' + cast(tt.TradeID as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + cast (tt.ISIN as varchar)-- collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Assetname collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.IssueName collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.ClientName collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.SubAccCode collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + tt.CustomerCode collate Cyrillic_General_CI_AS

				--+ '//2\\' + tt.ClientName --collate Cyrillic_General_CI_AS

				--+ '//2\\' + iif(t.BuySell = 1, 'Buy', 'Sell') --Operation

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT_TEST.dbo.CheckTradeAssetsSanction

			from @result2 tt



			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage2 = replace(@NotifyMessage2, '//1\\', '<tr><td>')

		set @NotifyMessage2 = replace(@NotifyMessage2, '//2\\', '</td><td>')

		set @NotifyMessage2 = replace(@NotifyMessage2, '//3\\', '</td></tr>')

		set @NotifyMessage2 = replace(@NotifyMessage2, '//4\\', '</td><td ')

		set @NotifyMessage2 = replace(@NotifyMessage2, '//5\\', '>')



		set @NotifyMessage2 = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>TradeDate'

			+ '</td><td>TradeID'

			+ '</td><td>ISIN'

			+ '</td><td>AssetName'

			+ '</td><td>IssueName'

			+ '</td><td>ClientName'

			+ '</td><td>SubAccCode'

			+ '</td><td>CustomerCode'

			/*+ '</td><td>Price'

			+ '</td><td>PriceCurrency'

			+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage2 + '</table>'



	set @NotifyTitle = 'Alert!!! Securities after 12.04.2022 and Client - "Russian person"'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-test-sql'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage2 --*/

			--, @file_attachments = @fileReport



			end -- конец блока отправки сообщения



			--Обновляем значение в счетчике текущего ID таблицы изменений сделок.

	IF OBJECT_ID('QORT_ARM_SUPPORT_TEST.dbo.IDTradeHistForCheckInstr', 'U') IS NOT NULL delete from QORT_ARM_SUPPORT_TEST.dbo.IDTradeHistForCheckInstr;

	insert into QORT_ARM_SUPPORT_TEST.dbo.IDTradeHistForCheckInstr (idtradehist) values (@CurIDTradeHist)



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END



