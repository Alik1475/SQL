

--exec QORT_ARM_SUPPORT_TEST.dbo.DraftChangeCurrent



CREATE PROCEDURE [dbo].[DraftChangeCurrent]

	@taskName varchar(32) = null

AS

BEGIN



	SET NOCOUNT ON



	begin try



		set @taskName = nullif(@taskName, '')

		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int

		declare @CurOrder table (Currency varchar(8), OrderBy int)

		declare @Trades table (rnum int, n int, SubAcc_Code varchar(32), Security_Code varchar(64), Qty float, CurrPriceAsset_ShortName varchar(48), Volume1 float, Price float)

		declare @TradesWithRowNum table (rnum int, n int, SubAcc_Code varchar(32), Security_Code varchar(64), Qty float, CurrPriceAsset_ShortName varchar(48), Volume1 float, Price float)

		declare @Position table (SubAcc_Code varchar(32), Security_Code varchar(64), Qty float, Frozen bit)

		declare @CurencyTrade varchar(8)

		declare @CurencyComm varchar(8)

		declare @VolumeComm float

		declare @n int = 0

		declare @n1 int = 0

		declare @n3 int = 0 



		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

-------------------------------------------------------------ФОРМИРУЕМ ТАБЛИЦУ С НАЧИСЛЕННЫМИ КОМИССИЯМИ--------------------------------

		select row_number() over(order by bc.Trade_ID) rn

		, bc.Subacc_ID Subacc_ID

		, sub.SubAccCode SubAccCode

		, bc.Asset_ID Asset_ID

		, AssC.Name CurrencyComm

		, bc.balance sumBalance

		, bc.Account_ID 

		, bc.Trade_ID

		, Tr.CurrPayAsset_ID

		, IIF(AssC.AssetClass_Const in (6,7,9,18), secu.Name, AssT.Name) CurrencyTrade

		into #t

		from QORT_BACK_DB_UAT..BlockCommissionOnTrades bc

		left outer join QORT_BACK_DB_UAT..Trades Tr on Tr.id = bc.Trade_ID

		left outer join QORT_BACK_DB_UAT..Assets AssC on AssC.id = bc.Asset_ID

		left outer join QORT_BACK_DB_UAT..Assets AssT on AssT.id = Tr.CurrPayAsset_ID

		left outer join QORT_BACK_DB_UAT..Securities secu on secu.id = Tr.Security_ID

		left outer join QORT_BACK_DB_UAT..Assets AssN on AssN.id = secu.Asset_ID

		left outer join QORT_BACK_DB_UAT..Subaccs sub with (nolock)  on sub.id = bc.Subacc_ID 

		where bc.Enabled <> bc.id and bc.Balance > 0

		select * from #t

		

-------------------------------------------------------------посделочно формируем данные для сделок конвертации--------------------

		



	set @n = (select max(rn) from #t) 

	--------------------------------------------начало цикла посделочного формирования сделок конвертации----------------------------------------

	While @n > 0 begin

		if OBJECT_ID('tempdb..#t1', 'U') is not null drop table #t1

		delete from @CurOrder

		delete from @Trades

		delete from @TradesWithRowNum 

		set @CurencyTrade = (select CurrencyTrade from #t where rn = @n)-- берем одну сделку

	

		insert into @CurOrder (Currency, OrderBy) values (@CurencyTrade, 6), ('USD', 5), ('EUR', 4), ('AMD',3), ('RUB',2)-- формируем приоритет по валютам, с учетом того, что первая валюта из сделки.

		

		------------формируем таблицу с позицией клиента

		

		set @VolumeComm = 0 -- сбрасываем счетчик сколько денег получили от конвертаций по сформированным сделкам



		SELECT t.Subacc_ID

		, t.SubAccCode SubAccCode

		, t.Asset_ID CurID_Need

		, t.sumBalance

		, iif(po.frozen is not null, 0, ph.VolFree) VolFree

		, ph.Asset_ID curBalance

		, ass.Name CurrencyBal

		, iif(ph.Asset_ID = t.Asset_ID , 0 ,(select top 1 OrderBy from @CurOrder where Currency = ass.Name collate Cyrillic_General_CS_AS)) OrderBy

		, po.Frozen

		into #t1

		FROM #t t

		left outer join QORT_BACK_DB_UAT..Position ph with (nolock) on ph.Subacc_ID = t.Subacc_ID --and ph.Date = @todayInt

		left outer join QORT_BACK_DB_UAT..Assets Ass with (nolock) on Ass.id = ph.Asset_ID

		left outer join @Position po on po.SubAcc_Code = t.SubAccCode collate Cyrillic_General_CS_AS and po.Security_Code = ass.Name collate Cyrillic_General_CS_AS

		where  ass.AssetType_Const = 3-- только валюты 

			and t.rn = @n 

			and ph.Account_ID in(3) -- только на физ счете ARMBROK_MONEY

			and ass.Name in('AMD','USD','RUB','EUR')

		

--------- проверяем, что позицию клиента еще не записывали, и тогда формируем (для заморозки позиций по другим сделкам, если сделок несколько)

		if (select top 1 SubAcc_Code from @Position where (select top 1 SubAccCode from #t1) = SubAcc_Code collate Cyrillic_General_CS_AS) is null

		begin

		insert into @Position (SubAcc_Code, Security_Code, Qty, Frozen)-- записываем позицию клиента

		select SubAccCode, CurrencyBal, VolFree, NULL as Frozen

		from #t1

		end



		select * from #t1

		

------------ формируем вторую расчетную таблицу, апгрейдом первой #t

		if OBJECT_ID('tempdb..#t2', 'U') is not null drop table #t2

		select row_number() over(order by t1.OrderBy) rn1

		, t1.OrderBy OrderBy

		, t1.Subacc_ID

		, t1.SubAccCode

		, t1.CurID_Need

		, ass.ShortName CurName_Need

		, t1.sumBalance-isnull((select VolFree from #t1 where CurrencyBal = ass.ShortName collate Cyrillic_General_CS_AS),0) sumBalance_need

		, t1.VolFree

		, t1.CurrencyBal CurrencyBal_pos

		, isnull(cr2.Bid, 1) bid

		into #t2

		from #t1 t1

		left outer join QORT_BACK_DB_UAT..CrossRatesHist cr2 with (nolock) on t1.curBalance = cr2.TradeAsset_ID and cr2.Date = @todayInt and cr2.InfoSource = 'CBA'

		left outer join QORT_BACK_DB_UAT..Assets ass with (nolock) on t1.CurID_Need = ass.id

		--where ass1.AssetType_Const = 3 -- только валюты

		where (t1.sumBalance-isnull((select VolFree from #t1 where CurrencyBal = ass.ShortName collate Cyrillic_General_CS_AS),0)) > 0

		

		----------------сохраняем значение той валюты, которую ищем

		set @CurencyComm = (select CurName_Need from #t2 where CurrencyBal_pos = CurName_Need collate Cyrillic_General_CS_AS)





		select * from #t2





		--------------------------------------запускаем этап формирования сделок конвертаций внутри цикла начисленных комиссий по сделкам--------------------------



		

		

		set @n1 = (select max(rn1) from #t2)-- из таблицы находим максимальное порядковое значение и откручиваем по нему вниз. 



		while @n1 > 1 -- на последней строчке будет валюта, которой не хватает (OrderBy = 6)

			begin 

			if OBJECT_ID('tempdb..#trades', 'U') is not null drop table #trades



			------- формируем таблицу планируемой сделки по первой доступной валюте

			select t2.Subacc_ID

			, t2.SubAccCode

			, t2.CurID_Need

			, t2.CurName_Need

			, (select bid from #t2 where CurName_Need = CurrencyBal_pos collate Cyrillic_General_CS_AS) bid_curneed

			, isnull(t2.sumBalance_need,0)-@VolumeComm PosNeed

			, t2.VolFree PosFree

			, t2.CurrencyBal_pos CurrPosFree

			, t2.bid bidPosFree

			, round((t2.sumBalance_need -@VolumeComm)*(select bid from #t2 where CurName_Need = CurrencyBal_pos collate Cyrillic_General_CS_AS)/t2.bid, 2) VolumForTrade

			, round(t2.VolFree - t2.sumBalance_need*(select bid from #t2 where CurName_Need = CurrencyBal_pos collate Cyrillic_General_CS_AS)/t2.bid, 2) VolFreeNow

			into #trades

			from #t2 t2 

			where rn1 = @n1 and t2.VolFree > 0 and (isnull(t2.sumBalance_need,0)-@VolumeComm) > 0

			select * from #trades		



				if (select volfreenow from #trades as float)>= 0

					begin

					insert into @Trades (rnum, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price) -- записываем сделки конвертации

					select null as rnum

					, @n1 as n

					, SubAccCode

					, CurrPosFree

					, iif(VolFreeNow >= 0, VolumForTrade, posfree)

					, CurName_Need

					, round(iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree),2)

					, IIF(CurName_Need = 'AMD', bidPosFree,	

					      round(IIF(iif(VolFreeNow >= 0, VolumForTrade, posfree)/iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree) > 

						  iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree)/iif(VolFreeNow >= 0, VolumForTrade, posfree),

						  iif(VolFreeNow >= 0, VolumForTrade, posfree)/iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree),

						  iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree)/iif(VolFreeNow >= 0, VolumForTrade, posfree)),2)

						  )

					from #trades

					set @n1 = 1 --конец цикла(завершаем)

					end

			    else

			        begin

					if (select volfreenow from #trades as float)<= 0 and @n1 = 2 -- если денег по валютам не хватило, то не формируем сделки, удаляем черновики и сбрасываем переменную валюты комиссии, чтобы не заморозить

						begin

						delete @Trades where SubAcc_Code = (select top 1 SubAccCode from #t1) collate Cyrillic_General_CS_AS

						set @CurencyComm = ''--сбросили валюту комисии которую искали, чтобы не замораживать, потому что денег на всех денежных позициях недостаточно

						end

					else

						begin

						insert into @Trades (rnum, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price) -- записываем сделки конвертации

						select null as rnum

						, @n1 as n

						, SubAccCode

						, CurrPosFree

						, iif(VolFreeNow >= 0, VolumForTrade, posfree)

						, CurName_Need

						, round(iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree), 2)

						, round(IIF(iif(VolFreeNow >= 0, VolumForTrade, posfree)/iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree) > 

							  iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree)/iif(VolFreeNow >= 0, VolumForTrade, posfree),

							  iif(VolFreeNow >= 0, VolumForTrade, posfree)/iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree),

							  iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree)/iif(VolFreeNow >= 0, VolumForTrade, posfree)), 2)

						from #trades

						set @VolumeComm = @VolumeComm + round(isnull((select top 1 iif(VolFreeNow >= 0, posneed, posfree/bid_curneed*bidPosFree) from #trades),0), 2)

						end

				end--начало на 179 строке(else)



			set @n1 = @n1 - 1

		end

		------------------------------------------конец цикла формирования таблицы сделок---------------------------------------------



		-----------------------------------обновляем таблицу сделок - нумеруем- чтобы загружать посделочно сделки в Корт----------------------------

		insert into @TradesWithRowNum (rnum, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price)

		select ROW_NUMBER() OVER (ORDER BY n) as rnum

			, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price

		from @Trades



		select * from @TradesWithRowNum 



----------------------- формирование сделОК в Корт---------------------------------------------------



		set @n3 = (select max(rnum) from @TradesWithRowNum) 

			

				while @n3 > 0

				begin



				set @WaitCount = 1200 -------------------- задержка, не передаем в ТДБ сделку, пока предыдущая не закончила грузиться----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_UAT.dbo.ImportTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end



	--/*	---------------------------- добавление сделки в Корт----------------------------

			insert into QORT_BACK_TDB_UAT.dbo.ImportTrades (

			IsProcessed, ET_Const, IsDraft

			, TradeDate, TradeTime, TSSection_Name

			, BuySell, Security_Code, Qty, Price

			, Volume1

			, CurrPriceAsset_ShortName, PutPlannedDate, PayPlannedDate

			, PutAccount_ExportCode, PayAccount_ExportCode, SubAcc_Code

			--, AgreeNum

			, TT_Const

			--, Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, PT_Const

			--, TSCommission, IsAccrued

			, IsSynchronize

			, CpSubacc_Code

			--, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, TradeNum

			, CpFirm_BOCode

		

		) --*/

		select 1 as IsProcessed, 2 as ET_Const, 'n' as IsDraft

			, @todayInt as TradeDate, replace(convert(varchar,getdate(),108), ':', '')+'000' TradeTime, 'OTC_FX' TSSection_Name

			, 2 as BuySell, Security_Code as Security_Code, Qty as Qty, Price as Price

			, Volume1 as Volume1

			, CurrPriceAsset_ShortName as CurrPriceAsset_ShortName, @todayInt PutPlannedDate, @todayInt PayPlannedDate

			, 'ARMBR_MONEY' PutAccount_ExportCode, 'ARMBR_MONEY' PayAccount_ExportCode, SubAcc_Code as SubAcc_Code

		--	, AgreeNum

			, 8 as TT_Const

			--, Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, 2 as PT_Const

			--, TSCommission, IsAccrued

			, 'y' IsSynchronize

			, 'AB0001' as CpSubacc_Code

			--, SS_Const

			, 0 as FunctionType

			, CurrPriceAsset_ShortName as CurrPayAsset_ShortName

			--, right(replace(replace(replace(replace(convert(varchar, getdate(),121), ':', ''), '-', ''), ' ', ''), '.', ''),15) TradeNum

			, cast(

				(cast(

						right(SubAcc_Code,4) as varchar(8))+cast(isnull((select max(ID) from QORT_BACK_DB_UAT.dbo.Trades with (nolock))+1,0) as varchar(8))) as int) TradeNum

			, '00001' CpFirm_BOCode

			from @TradesWithRowNum

			where rnum = @n3



			set @n3 = @n3 - 1



					end



		--return





		update @Position -- замораживаем позицию клиента для следующих сделок

		set Frozen = 1 where Security_Code = @CurencyComm

		select * from @Position



		set @n = @n - 1 

	end -- конец цикла прохода по начисленным комиссиям



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

