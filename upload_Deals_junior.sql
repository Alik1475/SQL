





 -- exec QORT_ARM_SUPPORT_TEST.dbo.upload_Deals



CREATE PROCEDURE [dbo].[upload_Deals_junior]

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @TradeNumStart bigint = 1006000

		select @TradeNumStart = isnull(max(tradeNum), @TradeNumStart) from QORT_BACK_DB_TEST.dbo.Trades with (nolock) where TradeNum >= @TradeNumStart



		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int

		declare @rowsDone int

		declare @rowsError int

		declare @rowsInDraft int



		--/*

		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Deals_junior.xlsx'

		declare @Sheet varchar(64) = 'Deals' 

		declare @sql varchar(1024)



		if OBJECT_ID('tempdb..##deals', 'U') is not null drop table ##deals

	

		SET @sql = 'SELECT * INTO ##deals

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



		exec(@sql)





		alter table ##deals add a1 varchar(32), a2 varchar(32)

		update d set d.a1 = isnull(cast(TRY_CONVERT(bigint, d.Agreement) as varchar), cast(d.Agreement as varchar))

			, d.a2 = isnull(cast(TRY_CONVERT(bigint, d.Agreement2) as varchar), cast(d.Agreement2 as varchar))

		from ##deals d



		alter table ##deals alter column Agreement varchar(32) collate Cyrillic_General_CS_AS

		alter table ##deals alter column Agreement2 varchar(32) collate Cyrillic_General_CS_AS



		update d set d.Agreement = a1, d.Agreement2 = a2

		from ##deals d



		-- */

		-- select * from ##deals



		-- select top 100 aid, IsProcessed, ErrorLog, * from QORT_BACK_TDB_TEST.dbo.ImportTrades it with (nolock)

		-- select top 100 * from QORT_ARM_SUPPORT_TEST.dbo.uploadLogs with (nolock) order by 1 desc



		set @aid = isnull((select max(aid) from QORT_BACK_TDB_TEST.dbo.ImportTrades with (nolock)), 0)



		--update d set aci = replace(aci, ',', ''), price = replace(price, ',', ''), Amount = replace(Amount, ',', '')

		update d set aci = iif(charindex(',', aci) > 0, replace(aci, ',', ''), aci)

			, price = iif(charindex(',', price) > 0, replace(price, ',', ''), price)

			, Amount = iif(charindex(',', Amount) > 0, replace(Amount, ',', ''), Amount)

		FROM ##deals d



		--/*

		insert into QORT_BACK_TDB_TEST.dbo.ImportTrades (

			IsProcessed, ET_Const, IsDraft

			, TradeDate, TradeTime, TSSection_Name

			, BuySell, Security_Code, Qty, Price

			, Volume1

			, Volume1Nom

			, CurrPriceAsset_ShortName, PutPlannedDate, PayPlannedDate

			, PutAccount_ExportCode, PayAccount_ExportCode, SubAcc_Code

			, AgreeNum, TT_Const, CpFirm_ShortName

			, Comment

			, AgreePlannedDate, Accruedint

			, TraderUser_ID, SalesManager_ID

			, PT_Const, TSCommission, IsAccrued

			, IsSynchronize, CpSubacc_Code

			, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, CrossRate

			--, ExternalNum

			, TradeNum

			, Yield

		) --*/

		SELECT 1 as IsProcessed, 2 as ET_Const, 'y' as IsDraft 

			, cast(convert(varchar, d.Date, 112) as int) TradeDate, replace(replace(convert(varchar, d.[Trade Time], 108), ':', ''), '?', '') + '000' TradeTime, d.Section TSSection

			, tt.BuySell, d.Instrument SecCode, d.Amount Qty, round(d.Price, 8, 0) Price

			, case when a.AssetType_Const = 3 then round(case when a.AssetClass_Const in (6,7,9) then (d.Amount*d.Price*cast(isnull(d.CrossRate, 1) as float) * a.BaseValueOrigin/100) + case when tt.AccInVolume = 'y' then cast(dACI * cast(isnull(d.CrossRate,1) as f
loat) as float) else 0 end else d.Amount * cast(isnull(d.CrossRate,1) as float)*d.Price end, 2, 0)

				else round(case when a.AssetClass_Const in (6,7,9) then (d.Amount*d.Price*cast(isnull(d.CrossRate,1) as float)*a.BaseValueOrigin/100) + case when tt.AccInVolume = 'y' then cast(dACI*cast(isnull(d.CrossRate,1) as float) as float) else 0 end else d.Amou
nt * cast(isnull(d.CrossRate,1) as float)*d.Price end, 2, 0)

				end Volume1

			, case when a.AssetType_Const = 3 then round(case when a.AssetClass_Const in (6,7,9) then (d.Amount*d.Price*cast(isnull(d.CrossRate,1) as float)*a.BaseValueOrigin/100) + case when tt.AccInVolume = 'y' then cast(dACI*cast(isnull(d.CrossRate,1) as float)
 as float) else 0 end end, 2, 0)

				else round(case when a.AssetClass_Const in (6,7,9) then (d.Amount*d.Price*cast(isnull(d.CrossRate,1) as float)*a.BaseValueOrigin/100) + case when tt.AccInVolume = 'y' then cast(dACI*cast(isnull(d.CrossRate,1) as float) as float) else 0 end end, 2, 0)


				end Volume1Nom

			, d.[Price Currency] PriceCurrency, cast(convert(varchar, d.PlannedDeliveryDate, 112) as int), cast(convert(varchar, d.PlannedPaymentDate, 112) as int)

			, aPut.ExportCode PutAccount, aPay.ExportCode PayAccount, left(d.[Sub-Account], 32) SubAccount

			, isnull(cast(d.AgreeMent as varchar), 'N/A') AgreeNum, tss.TT_Const, d.Counterparty CpFirm_ShortName

			--, case when d.Comment is null then 'DealsFromExcel' else cast(d.Comment as varchar(300)) + ' DealsFromExcel' end as Comment

			, d.Comment

			, cast(convert(varchar, d.Date, 112) as int) AgreePlannedDate, round(dACI*cast(d.CrossRate as float), 2) Accruedint

			, uTrader.id TraderUser_ID, uSales.id SalesManager_ID

			, IIF(sec.IsProcent = 'y',1,2) PT_Const, cast(d.[Settl Fees] as float) TSCommission, tt.AccInVolume IsAccrued

			, iif(d.[Counterparty Subaccount] <> '', 'y', 'n') IsSynchronize, d.[Counterparty Subaccount] CpSubacc_Code

			, case when d.[Settlement Type] is null or d.[Settlement Type] = '' then 1

				  when d.[Settlement Type] in ('Поставка против платежа','DVP') then 2

				  when d.[Settlement Type] in ('Предпоставка','Pre-delivery') then 3

				  when d.[Settlement Type] in ('Предоплата','Prepayment') then 4

				  when d.[Settlement Type] in ('Свободная поставка','FOP') then 5

				  when d.[Settlement Type] in ('Свободная поставка первая поставка/платеж контрагента','FOP - counterparty predelivery/prepayment') then 6

				  when d.[Settlement Type] in ('Свободная поставка первая поставка/платеж брокера','FOP - broker predelivery/prepayment') then 7

				  end SS_Const

			, case cast(d.Type as varchar(200)) when 'Обычная заявка' then 0

				when 'Аннулирование обязательств и прав' then 9

				when 'Исполнение/экспирация' then 7

				end FunctionType

			, iif(isnull(d.[Payment Currency],'') = '', d.[Price Currency], d.[Payment Currency]) CurrPayAsset_ShortName

			, cast(d.CrossRate as float) CrossRate

			--, isnull(cast(d.AgreeMent as varchar), 'N/A') ExternalNum

			, @TradeNumStart + ROW_NUMBER() over(order by d.AgreeMent) TradeNum

			, d.Yield

		FROM ##deals d

		outer apply (select case when [Buy/Sell] in ('Покупка', 'Buy') then 1 when [Buy/Sell] in ('Продажа', 'Sell') then 2 end as BuySell

			, iif(cast(d.[ACI in Volume] as varchar) in ('Да','y'), 'y', 'n') AccInVolume

			, isnull(cast(d.ACI as float), 0) dACI) tt

		outer apply (select top 1 uTrader.id from QORT_BACK_DB_TEST.dbo.Users uTrader with (nolock) where uTrader.last_name + ' ' + uTrader.first_name = d.[Execution Trader] and uTrader.Enabled = 0 order by 1 desc) uTrader

		outer apply (select top 1 uSales.id from QORT_BACK_DB_TEST.dbo.Users uSales with (nolock) where uSales.last_name + ' ' + uSales.first_name = d.[Investment Decision] and uSales.Enabled = 0 order by 1 desc) uSales

		left outer join QORT_BACK_DB_TEST.dbo.TSSections tss with (nolock) on tss.Name = d.Section and tss.Enabled = 0

		left join QORT_BACK_DB_TEST.dbo.Trades t with (nolock) on t.TradeDate = cast(convert(varchar, d.Date, 112) as int) and t.BuySell = tt.BuySell and t.AgreeNum = cast(d.AgreeMent as varchar) and t.Enabled = 0 and t.nullstatus = 'n'

		--outer apply (select top 1 * from QORT_BACK_DB_TEST.dbo.Trades t with (nolock) where t.id = tp.Trade_ID and t.TradeDate = cast(convert(varchar, d.Date, 112) as int) and t.BuySell = tt.BuySell /*and t.AgreeNum = cast(d.AgreeMent as varchar)*/ and t.Enab
led = 0 and t.nullstatus = 'n') t

		/*outer apply (

			select top 1 t.* 

			from QORT_BACK_DB_TEST.dbo.TradeProperties tp with (nolock) 

			inner join QORT_BACK_DB_TEST.dbo.Trades t with (nolock) on t.id = tp.Trade_ID and t.TradeDate = cast(convert(varchar, d.Date, 112) as int) and t.BuySell = tt.BuySell /*and t.AgreeNum = cast(d.AgreeMent as varchar)*/ and t.Enabled = 0 and t.nullstatus 
= 'n'

			where tp.ExternalNum = cast(d.AgreeMent as varchar)

		) t*/

		left join QORT_BACK_DB_TEST.dbo.Securities sec with (nolock) on sec.SecCode = d.Instrument and sec.TSSection_ID = tss.id

		left join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left join QORT_BACK_DB_TEST.dbo.Accounts aPut with (nolock) on aPut.AccountCode = d.DeliveryAccount collate Cyrillic_General_CS_AS

		left join QORT_BACK_DB_TEST.dbo.Accounts aPay with (nolock) on aPay.AccountCode = d.[Payment Account] collate Cyrillic_General_CS_AS

		where d.Date is not null

			and t.id is null

			--and tp.id is null

--return



		set @rows = @@ROWCOUNT; if @rows > 0 begin set @Message = 'File Uploaded - "'+@filename+'": ' + cast(@rows as varchar) + ' new deals'; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) values (@message, 2001, @rows); e
nd;





		set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.ImportTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		

		insert into QORT_BACK_TDB_TEST.dbo.ImportTrades (ET_Const, IsProcessed, SystemID, AgreeNum)

		select 4 ET_Const, 1 IsProcessed, t2.id SystemID, ltrim(d.Agreement2) AgreeNum

		from ##deals d

		outer apply (select case when [Buy/Sell] in ('Покупка', 'Buy') then 1 when [Buy/Sell] in ('Продажа', 'Sell') then 2 end as BuySell) tt

		inner join QORT_BACK_DB_TEST.dbo.Trades t with (nolock) on t.TradeDate = cast(convert(varchar, d.Date, 112) as int) and t.BuySell = tt.BuySell and t.AgreeNum = cast(d.AgreeMent as varchar) and t.Enabled = 0 and t.nullstatus = 'n'

		inner join QORT_BACK_DB_TEST.dbo.Trades t2 with (nolock) on t2.id = t.CpTrade_ID and t2.AgreeNum = cast(d.Agreement as varchar) and t2.Enabled = 0 and t2.nullstatus = 'n'

		where ltrim(d.Agreement) <> '' and ltrim(d.Agreement2) <> '' and d.Agreement2 <> d.Agreement

			and t.CpTrade_ID > 0



		set @rows = @@ROWCOUNT; if @rows > 0 begin set @Message = 'File Uploaded - "'+@filename+'": ' + cast(@rows as varchar) + ' AgreeNum2 modified'; insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords) values (@message, 2001, 
@rows); end;



		set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.ImportTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end





		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

		select 'TDB Trades Error: ' + cast(TradeDate as varchar) +' AgreeNum ' + isnull(cast(AgreeNum as varchar), '') collate Cyrillic_General_CS_AS + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

		from QORT_BACK_TDB_TEST.dbo.ImportTrades a with (nolock)

		where aid > @aid

			and IsProcessed = 4

			and ErrorLog not like 'The trade with ID=% is not processed yet.'





		IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;



		select t.id TradeId, d.BrokComm Amount, d.[Commission Currency] Currency, d.SubAccForCrediting SubAccForCrediting

			, t.TradeDate Date

			, cast(null as int) AssetId

			, cast(null as int) SubAccId, cast(null as int) AccountId

			, cast(null as int) GetSubAccId, cast(null as int) GetAccountId

			, cast(null as varchar(64)) backId

			, cast(null as varchar(128)) AssetShortName

			, cast(null as varchar(128)) collate Cyrillic_General_CS_AS SubAccCode

			, cast(null as varchar(128)) collate Cyrillic_General_CI_AS AccountExportCode

			, cast(null as varchar(128)) collate Cyrillic_General_CS_AS GetSubAccCode

			, cast(null as varchar(128)) collate Cyrillic_General_CI_AS GetAccountExportCode

			, row_number() over(order by isnull(t.id, 0)*0) rn

			, cast(null as bigint) trueTradeId

			, t.IsDraft

		into #comms 

		from ##deals d

		outer apply (select case when [Buy/Sell] in ('Покупка', 'Buy') then 1 when [Buy/Sell] in ('Продажа', 'Sell') then 2 end as BuySell

			, iif(cast(d.[ACI in Volume] as varchar) in ('Да','y'), 'y', 'n') AccInVolume

			, isnull(cast(d.ACI as float), 0) dACI) tt

		inner join QORT_BACK_DB_TEST.dbo.Trades t with (nolock) on t.TradeDate = cast(convert(varchar, d.Date, 112) as int) and t.BuySell = tt.BuySell and t.AgreeNum = cast(d.AgreeMent as varchar) and t.Enabled = 0 and t.nullstatus = 'n'

		where try_convert(float, d.BrokComm) > 0 and d.[Commission Currency] <> '' and d.SubAccForCrediting <> ''





		set @rowsInFile = @@ROWCOUNT



		select @rowsInDraft = count(*) from #comms where IsDraft = 'y'



		update t set t.AssetId = a.Id, t.AssetShortName = isnull(a.ShortName, isnull(t.Currency, 'NULL') + ' - asset not found')

			, t.SubAccId = s.id, t.SubAccCode = s.SubAccCode

			, t.GetSubAccId = gs.id, t.GetSubAccCode = isnull(gs.SubAccCode, isnull(t.SubAccForCrediting, 'NULL') + ' - NOT FOUND')

			, t.AccountId = acc.id, t.AccountExportCode = acc.ExportCode

			, t.GetAccountId = acc.id, t.GetAccountExportCode = acc.ExportCode

			, t.trueTradeId = tt.id

		from #comms t

		left outer join QORT_BACK_DB_TEST.dbo.Trades tt with (nolock) on tt.id = t.TradeId-- * 1000

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.id = tt.SubAcc_ID

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs gs with (nolock) on gs.SubAccCode = t.SubAccForCrediting collate Cyrillic_General_CS_AS

		left outer join QORT_BACK_DB_TEST.dbo.Accounts acc with (nolock) on acc.id = tt.PayAccount_ID

		outer apply (

			select top 1 a.id, a.ShortName

			from QORT_BACK_DB_TEST.dbo.Assets a with (nolock) 

			where a.ShortName = t.Currency and a.AssetType_Const = 3

				and a.Enabled = 0 and a.IsTrading = 'y'

			order by 1

		) a





		update t set t.BackId = left(

				'Commission_on_Trade ' + isnull(cast(t.TradeId as varchar), 'NULL')

				+ ', line ' + cast(rn as varchar) 

				+ '_from_' + cast(cast(convert(varchar, getdate(), 112) as int) as varchar)

				+ '_' + convert(varchar, getdate(), 114)

				, 64)

		from #comms t



		declare @InfoSource varchar(64) = isnull(object_name(@@procid), 'NULL')

		--/*

		insert into QORT_BACK_TDB_TEST.dbo.Phases( IsProcessed, ET_Const, PC_Const, BackID, Date

			, InfoSource, PhaseAccount_ExportCode, Subacc_Code, PhaseAsset_ShortName, CurrencyAsset_ShortName

			, QtyBefore, QtyAfter, GetSubacc_Code, GetAccount_ExportCode, Trade_SID, SystemID

			, Comment) --*/

		select distinct 1 IsProcessed, 2 ET_Const, 9 PC_Const, t.BackID, cast(convert(varchar, t.Date, 112) as int) PhaseDate

			, left(@InfoSource, 64) InfoSource, t.AccountExportCode, t.SubaccCode, t.AssetShortName, t.AssetShortName CurrencyShortName

			, cast(t.Amount as decimal(32,2)) QtyBefore, -1 QtyAfter, t.GetSubaccCode, t.GetAccountExportCode, t.TradeId, -1 SystemID

			, left(@FileName, 64) Comment

		from #comms t

		left outer join QORT_BACK_DB_TEST.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.PC_Const = 9 and p.IsCanceled = 'n' and p.Enabled = 0

		where (p.id is null or t.trueTradeId is null)

			and isnull(t.IsDraft, 'n') = 'n'





		set @rowsNew = @@ROWCOUNT



		set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_TEST.dbo.Phases t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end





		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel)

		select 'TDB Commission Error: ' + @FileName +', ' + isnull(BackId, '') + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

		from QORT_BACK_TDB_TEST.dbo.Phases a with (nolock)

		where aid > @aid

			and IsProcessed = 4

			and InfoSource = @InfoSource



		set @rowsError = @@ROWCOUNT



		select @rowsDone = count(*)

		from #comms t

		inner join QORT_BACK_DB_TEST.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.BackId = t.BackId and p.IsCanceled = 'n'



		if @rowsInFile > 0 and (@rowsNew > 0 or @rowsInDraft > 0) begin

			insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel, logRecords)

			select 'File uploaded: ' + @FileName + ', comissions: ' + cast(@rowsInFile as varchar) +', new Commissions: ' 

					+ cast((@rowsNew - @rowsError) as varchar) + ' / ' + cast((@rowsNew) as varchar) 

					+ iif(@rowsInDraft > 0, ', draft trades: ' + cast(@rowsInDraft as varchar), '') logMessage

				, iif(@rowsError > 0 or @rowsInDraft > 0, 1001, 2001) errorLevel, (@rowsNew - @rowsError) logRecords

		end





	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		if @message not like '%Cannot initialize the data source%' insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

