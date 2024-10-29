



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_TradeInstructions

/*

	exec QORT_ARM_SUPPORT_TEST.dbo.upload_TradeInstructions



	select top 100 *

	from QORT_ARM_SUPPORT_TEST.dbo.uploadLogs with (nolock)

	order by 1 desc



	exec upload_ProcessLog

*/



CREATE PROCEDURE [dbo].[upload_TradeInstructions]



AS



BEGIN



	begin try



		declare @lastTdbId int = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.ImportTradeInstrs t with (nolock)), 0)

		declare @NewOrders int = 0

		declare @WaitCount int

		declare @Message varchar(1024)



		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\test\Orders.xlsx'

		declare @SheetSec varchar(64) = 'Orders'

		declare @SheetFX varchar(64) = 'Currency'

		declare @sql varchar(max)



		if OBJECT_ID('tempdb..##ooSec', 'U') is not null drop table ##ooSec

		if OBJECT_ID('tempdb..##ooFX', 'U') is not null drop table ##ooFX

		if OBJECT_ID('tempdb..#tSec', 'U') is not null drop table #tSec

		if OBJECT_ID('tempdb..#tFX', 'U') is not null drop table #tFX



		SET @sql = 'SELECT * INTO ##ooSec

		FROM OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @SheetSec + '$A2:ZZ100000]'')'



		print @sql

		exec(@sql)





		SET @sql = 'SELECT * INTO ##ooFX

		FROM OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @SheetFX + '$A3:ZZ100000]'')'



		print @sql

		exec(@sql)





		select BONum BONum

			, ConstitutorCode

			, cast(null as varchar(64)) AuthorSubAccCode

			, cast(null as int) SubAccId

			, RegisterNum RegisterNum

			, cast(convert(varchar, Date, 112) as int) InstrDate

			, cast(replace(convert(varchar, Time, 114), ':', '') as int) InstrTime

			, [Security_ID] ISIN

			, [CurrencyAsset_ID] Currency

			, [Type (Buy= 7, Sell=8)] TypeTXT

			, [Qty] Qty

			, replace([Price (если CurrencyAsset_ID = AMD) + PriceType = 2], ',', '') PriceAMD

			, [Price (если CurrencyAsset_ID = USD + PriceType = 2] PriceUSD

			, [Price (если CurrencyAsset_ID = EUR + PriceType = 2] PriceEUR

			, [Price (если CurrencyAsset_ID = RUR + PriceType = 2] PriceRUR

			, [PRC_Const, где Limit =2, Market 3] PRC_Const_TXT

			, cast(convert(varchar, try_convert(DateTime, [Date2, если есть дата, то проставляем, если нет, то пустое поле]), 112) as int) Date2

			, [AuthorComment] AuthorComment

			, [AgentCommission] AgentCommission

			, cast(convert(varchar, try_convert(DateTime, [Date1]), 112) as int) Date1

			, [Section_ID] Section_ID

			, [Price + PriceType = 1] PricePercent

			, [IS_Const] IS_Const_TXT

			, [QORT Y/N] IsInQort

			, cast(null as bigint) QortIdExisted 

			, cast(null as bigint) QortIdNew

		into #tSec

		from ##ooSec

		where BONum <> '' and ConstitutorCode <> ''





		select BONum BONum

			, ConstitutorCode

			, cast(null as varchar(64)) AuthorSubAccCode

			, cast(null as int) SubAccId

			, RegisterNum RegisterNum

			, cast(convert(varchar, Date, 112) as int) InstrDate

			, cast(replace(convert(varchar, Time, 114), ':', '') as int) InstrTime

			, [PRC_Const, где Limit =2, Market 3] PRC_Const_TXT

			, [Date2, если есть дата, то проставляем, если нет, то пустое поле] Date2

			, [Если заполнено Buy или SELL то Security_ID# Если не заполенено т] Sec1

			, [Если заполнено Buy или SELL то Security_ID# Если не заполенено 1] Sec2

			, [Qty (Type = 7)] QT7

			, [Qty (Type = 8)] QT8

			, [Section_ID] TSSectionName

			, [QORT Y/N] IsInQort

			, cast(null as bigint) QortIdExisted 

			, cast(null as bigint) QortIdNew

		into #tFX

		--select *

		from ##ooFX

		where BONum <> '' and ConstitutorCode <> ''





		update ti set ti.Date2 = NULL

		from #tFX ti

		where ti.Date2 = 'Open'



		update ti set ti.PRC_Const_TXT = case ti.PRC_Const_TXT when 'limit' then '2' when 'market' then '3' else ti.PRC_Const_TXT end

		from #tFX ti





		update t set t.Section_ID = t.Section_ID + '_Securities'

		from #tSec t

		where Section_ID in ('OTC', 'AIX', 'AMX')



		update t set t.IS_Const_TXT = 1 -- case IS_Const_TXT when 'Done' then 5 when 'Pending' then 2 else 1 end

		from #tSec t





		update t set t.AuthorSubAccCode = s.SubAccCode,	t.SubAccId = s.id

		from #tSec t

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.ConstitutorCode = t.ConstitutorCode and s.IsAnalytic = 'n' and s.Enabled = 0







		update t set t.AuthorSubAccCode = s.SubAccCode,	t.SubAccId = s.id

		from #tFX t

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.ConstitutorCode = t.ConstitutorCode and s.IsAnalytic = 'n' and s.Enabled = 0





		update t set t.QortIdExisted = i.id

		from #tSec t

		left outer join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.BONum = t.BONum



		update t set t.QortIdExisted = i.id

		from #tFX t

		left outer join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.BONum = t.BONum



		update t set t.QortIdExisted = i.id

		from #tSec t

		inner join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.AuthorPTS = t.BONum

		where t.QortIdExisted is null and t.BONum <> ''



		update t set t.QortIdExisted = i.id

		from #tFX t

		inner join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.AuthorPTS = t.BONum

		where t.QortIdExisted is null and t.BONum <> ''



		-- УДАЛЕНИЕ ДУБЛЕЙ

		update t2 set t2.BONum = ''

		from #tSec t1

		inner join #tSec t2 on t2.ConstitutorCode = t1.ConstitutorCode and t2.RegisterNum = t1.RegisterNum and t2.InstrDate = t1.InstrDate and t2.ISIN = t1.ISIN and t2.QTY = t1.Qty

		where t1.QortIdExisted > 0 and t1.BONum <> '' and t2.BONum <> ''

			and (t2.Bonum > t1.BONum or t2.QortIdExisted is null)



		update t2 set t2.BONum = ''

		from #tSec t1

		inner join #tSec t2 on t2.ConstitutorCode = t1.ConstitutorCode and t2.RegisterNum = t1.RegisterNum and t2.InstrDate = t1.InstrDate and t2.ISIN = t1.ISIN and t2.QTY = t1.Qty

		where t1.BONum <> '' and t2.BONum <> ''

			and (t2.Bonum > t1.BONum and t2.QortIdExisted is null)



		update t2 set t2.BONum = ''

		from #tFX t1

		inner join #tFX t2 on t2.ConstitutorCode = t1.ConstitutorCode and t2.RegisterNum = t1.RegisterNum and t2.InstrDate = t1.InstrDate and t2.Sec1 = t1.Sec1 and t2.Sec2 = t1.Sec2

			 and isnull(t2.QT7, 0) = isnull(t1.QT7, 0) and isnull(t2.QT8, 0) = isnull(t1.QT8, 0)

		where t1.QortIdExisted > 0 and t1.BONum <> '' and t2.BONum <> ''

			and (t2.Bonum > t1.BONum or t2.QortIdExisted is null)



		update t2 set t2.BONum = ''

		from #tFX t1

		inner join #tFX t2 on t2.ConstitutorCode = t1.ConstitutorCode and t2.RegisterNum = t1.RegisterNum and t2.InstrDate = t1.InstrDate and t2.Sec1 = t1.Sec1 and t2.Sec2 = t1.Sec2

			 and isnull(t2.QT7, 0) = isnull(t1.QT7, 0) and isnull(t2.QT8, 0) = isnull(t1.QT8, 0)

		where t1.BONum <> '' and t2.BONum <> ''

			and (t2.Bonum > t1.BONum and t2.QortIdExisted is null)

		-- УДАЛЕНИЕ ДУБЛЕЙ







		insert into QORT_BACK_TDB_TEST.dbo.ImportTradeInstrs(IsProcessed, ET_Const, /*BONum*/ AuthorPTS, RegisterNum, Date, Time, PRC_Const, TS_Code, Date2, AuthorSubAcc_Code

			, OwnerFirm_BOCode, Type, Qty, Security_Code, CurrencyAsset_ShortName

			, IS_Const, TYPE_Const, IsAgent, Section_Name, PriceType, AuthorFIO) -- */

		select 1 IsProcessed, 2 ET_Const, ti.BONum, ti.RegisterNum, ti.InstrDate, ti.InstrTime, ti.PRC_Const_TXT, ts.Code, ti.Date2

			, isnull(s.SubAccCode, ti.ConstitutorCode + ' NOT FOUND'), fo.BOCode

			, iif(QT7 > 0, 7, 8) Type

			, iif(QT7 > 0, Qt7, Qt8) Qty

			, replace(iif(QT7 > 0, Sec1, Sec2), 'RUB', 'RUR') SecCode

			, replace(iif(QT7 > 0, Sec2, Sec1), 'RUR', 'RUB') Currency

			, 1 IS_Const

			, 2 TYPE_Const, 'y' IsAgent, tss.Name, 15 PriceType, 'Import From Excel' AuthorFIO

		from #tFX ti

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.id = ti.SubAccId

		left outer join QORT_BACK_DB_TEST.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.TSSections tss with (nolock) on tss.Name = ti.TSSectionName

		left outer join QORT_BACK_DB_TEST.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		where ti.QortIdExisted is null

			and ti.BONum <> ''



		set @NewOrders = @NewOrders + @@ROWCOUNT



		--/*

		insert into QORT_BACK_TDB_TEST.dbo.ImportTradeInstrs(IsProcessed, ET_Const, /*BONum*/ AuthorPTS, RegisterNum, Date, Time, PRC_Const, TS_Code, Date2, FinishDate --Date1

			, AuthorSubAcc_Code, OwnerFirm_BOCode, Type, PriceType

			, Qty, Security_Code, CurrencyAsset_ShortName, IS_Const, Price, AuthorComment, TYPE_Const, IsAgent, Section_Name, AuthorFIO) -- */

		select 1 IsProcessed, 2 ET_Const, t.BONum, t.RegisterNum, t.InstrDate, t.InstrTime, case t.PRC_Const_TXT when 'Market' then 3 when 'Limit' then 2 end PRC_Const, ts.Code, t.Date2, t.Date1 FinishDate

			, isnull(s.SubAccCode, t.ConstitutorCode + ' NOT FOUND'), fo.BOCode, Case t.TypeTxt when 'Buy' then 7 when 'Sell' then 8 end Type, iif(PricePercent > 0, 1, 2) PriceType

			, t.Qty, isnull(sec.SecCode, t.ISIN + ' NOT FOUND'), replace(t.Currency, 'RUR', 'RUB'), t.IS_Const_TXT IS_Const, coalesce(t.PricePercent *100, t.PriceAMD, t.PriceUSD, t.PriceEUR, t.PriceRUR) Price, t.AuthorComment, 2 TYPE_Const

			, 'y' IsAgent, tss.Name, 'Import From Excel' AuthorFIO

			--, t.AgentCommission

		from #tSec t

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.id = t.SubAccId

		left outer join QORT_BACK_DB_TEST.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.TSSections tss with (nolock) on tss.Name = t.Section_ID

		left outer join QORT_BACK_DB_TEST.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		outer apply (select top 1 a.id Asset_ID, a.ISIN, a.ShortName from QORT_BACK_DB_TEST.dbo.Assets a with (nolock) where a.ISIN = t.ISIN and a.Enabled = 0 and t.ISIN <> '' order by 1) a

		outer apply (select top 1 sec.SecCode from QORT_BACK_DB_TEST.dbo.Securities sec with (nolock) where sec.Asset_ID = a.Asset_ID and sec.TSSection_ID = tss.id and sec.Enabled = 0 order by 1) sec

		where t.QortIdExisted is null

			and t.BONum <> ''

			--and bonum in ('3557', '3558')

	



		set @NewOrders = @NewOrders + @@ROWCOUNT





		set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.ImportTradeInstrs t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end



		--select @lastTdbId, @NewOrders



		if @NewOrders > 0 begin set @Message = 'File Uploaded - "'+@filename+'": ' + cast(@NewOrders as varchar) + ' new instructions'; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) select @message, 2001, @NewOrders; end;




		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

		select 'TDB Instr Error: ' + isnull(cast(Date as varchar), '') +' BONum ' + isnull(cast(BONum as varchar), '') + ', RegisterNum ' + isnull(cast(RegisterNum as varchar), '') + ', SubAccCode ' + isnull(AuthorSubAcc_Code, '') + ', AuthorPTS ' + isnull(Auth
orPTS, '') + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

		from QORT_BACK_TDB_TEST.dbo.ImportTradeInstrs a with (nolock)

		where aid > @lastTdbId

			and IsProcessed = 4



		update t set t.QortIdNew = i.id -- надо попробовать записать обратно в файл - [QORT Y/N] IsInQort

		from #tSec t

		left outer join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.BONum = t.BONum

		where t.QortIdExisted is null



		update t set t.QortIdNew = i.id -- надо попробовать записать обратно в файл - [QORT Y/N] IsInQort

		from #tFX t

		left outer join QORT_BACK_DB_TEST.dbo.TradeInstrs i with (nolock) on i.AuthorSubAcc_ID = t.SubAccId and i.Enabled = 0 and i.BONum = t.BONum

		where t.QortIdExisted is null





	end try

	begin catch

		--while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

