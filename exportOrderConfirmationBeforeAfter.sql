









/*

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5061, @BeforeAfter = 1

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5061, @BeforeAfter = 2

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5302, @BeforeAfter = 1

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5604, @BeforeAfter = 2

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5619, @BeforeAfter = 2

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5635, @BeforeAfter = 2

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5622, @BeforeAfter = 1

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = 5637, @BeforeAfter = 1

*/



CREATE PROCEDURE [dbo].[exportOrderConfirmationBeforeAfter]

	@OrderId bigint

	, @BeforeAfter tinyint -- 1 - before, 2 - after

	, @resultStatus varchar(1024) = null out 

	, @resultPath varchar(255) = null out

	, @resultColor varchar(32) = null out

	, @resultDateTime varchar(32) = null out

AS

BEGIN



	SET NOCOUNT ON



	begin try



		set @BeforeAfter = 1 -- всегда только Before

		declare @IsSettled bit = 0



		declare @Message varchar(1024)

		declare @ArmBrokShortName varchar(32) = 'Armbrok OJSC'

		declare @SinaraBeforeAdd varchar(255) = '* Please note that regardless of the specified expected date of delivery, the actual delivery date of the securities can be finalized within 20 calendar days from the transaction date.'



		/*

		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Technical do not delete\New Order Confo\templates'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\Archive'

		declare @FileDirResBefore varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\Before'

		declare @FileDirResAfter varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\After'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\FX_Long'

		*/



		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Templates'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\Archive'

		declare @FileDirResBefore varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\Before'

		declare @FileDirResAfter varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\After'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\FX_Long'





		if right(@FileDir, 1) <> '' set @FileDir = @FileDir + '\'

		if right(@FileDirOut, 1) <> '' set @FileDirOut = @FileDirOut + '\'

		if right(@FileDirResBefore, 1) <> '' set @FileDirResBefore = @FileDirResBefore + '\'

		if right(@FileDirResAfter, 1) <> '' set @FileDirResAfter = @FileDirResAfter + '\'

		if right(@FileDirResFX, 1) <> '' set @FileDirResFX = @FileDirResFX + '\'

		declare @FileDirRes varchar(255)

		declare @FileNameEmpty varchar(128) --= 'sec_06e.xlsx'

		declare @ReportDate int = cast(convert(varchar, getdate(), 112) as int)

		declare @Sheet varchar(64)



		declare @AddTXT varchar(16)

		if @BeforeAfter = 1 set @AddTXT = '_before' else set @AddTXT = '_after'



		declare @NewFileName varchar(255) = 'order_'+ cast(@OrderID as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + @AddTXT + '.xlsx'

		declare @NewFileNameRes varchar(255) = 'order_'+ cast(@OrderId as varchar) + @AddTXT + '.xlsx'

		print @NewFileName





		declare @res table(r varchar(255))

		declare @cmd varchar(512)

		declare @sql nvarchar(max)







		declare @SecurityType varchar(128) = 'NOT FOUND'

		declare @IsPAIExclusion bit



		if OBJECT_ID('tempdb..##o0323', 'U') is not null drop table ##o0323

		if OBJECT_ID('tempdb..##t0323', 'U') is not null drop table ##t0323

		if OBJECT_ID('tempdb..##f0323', 'U') is not null drop table ##f0323

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



		select top 1 ti.id OrderId

			, s.SubAccCode ConstitutorCode -- s.ConstitutorCode

			, isnull(AssetSort.SecType, @SecurityType) SecurityType

			, a.ShortName AssetShortName

			, aCur.ShortName OrderCurrency

			, ti.Qty

			, iif(ti.CpFirm_ID > 0, iif(fcp.FirmShortName = @ArmBrokShortName, 'internal', 'external'), '') TransactionType -- Если галочка проставлена в поле Counterparty (корт)  заполнено любым значением, кроме  ArmBrok - external, если галочка проставлена и выб
ран Counterparty (корт)  - ArmBrok- internal 

			--, cast(case ti.PRC_Const when 2 then 'Limit' when 3 then 'Market' else '' end as varchar(128)) OrderType --case

			, cast(case ti.PRC_Const when 2 then 'Limit' when 3 then 'Market' when 4 then 'Limit' when 5 then 'Limit' else '' end as varchar(128)) OrderType --case

			, ti.RegisterNum

			, aBaseCur.ShortName AssetBaseCurrency

			, isnull(fi.FirmShortName, '') IssuerFirmShortName

			--, isnull(iif(fip.NameU <> '', fip.NameU, fi.FirmShortName), '') IssuerFirmShortName

			, a.ISIN

			, case ti.Type when 7 then 'Buy' when 8 then 'Sell' else 'unknown' end OrderBuySellTXT

			--, 'Partial' QuantitativeCondition

			, iif(ti.IsComplete = 'y', 'All or none', 'Partial') QuantitativeCondition

			, isnull(a.BaseValue, 0) AssetBaseValue

			, ti.Price OrderPrice

			, iif(ti.PriceType = 20, ti.Price, 0) OrderYield

			, fcp.FirmShortName CPFirmShortName

			, ti.AuthorComment

			, ti.Date OrderDate

			, ti.Date2 OrderDate2

			, case when ti.Date2 = 0 then 'Open' when ti.date2 = ti.date then 'Day only' else 'Good till ' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.date2) end OrderConditions -- case

			, '' OrderDescription

			, '' IssueNumber

			, iif(IsBond = 1 and a.BaseValueOrigin > 0, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(a.BaseValueOrigin), '') NominalPerInstrument

			, ts.Code TSCode

			, aCur.ShortName PaymentCurrency

			, aCur.ShortName SettlementCurrency

			--, aCur.ShortName CommissionCurrency

			, isnull(com3.com3, '') CommissionCurrency

			, fo.IsFirm

			, fo.FirmShortName OwnerFirmShortName

			, com1.com1

			, com2.com2

			, com3.com3

			, iif(a.AssetSort_Const = 14 and charindex('Glocal', fi.FirmShortName) > 0, 1, 0) IsPAIExclusion

		into ##o0323

		from QORT_BACK_DB.dbo.TradeInstrs ti with (nolock)

		left outer join QORT_BACK_DB.dbo.SubAccs s with (nolock) on s.id = ti.AuthorSubAcc_ID

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = ti.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = sec.TSSection_ID

		left outer join QORT_BACK_DB.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_ARM_SUPPORT.dbo.Assets_AS AssetSort with (nolock) on AssetSort.ConstInt = a.AssetSort_Const

		left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = ti.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fop with (nolock) on fop.Firm_ID = ti.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.Assets aCur with (nolock) on aCur.id = ti.CurrencyAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = ti.CpFirm_ID

		left outer join QORT_BACK_DB.dbo.Assets aBaseCur with (nolock) on aBaseCur.id = a.BaseCurrencyAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fi with (nolock) on fi.id = a.EmitentFirm_ID

		left outer join QORT_BACK_DB.dbo.FirmProperties fip with (nolock) on fip.Firm_ID = a.EmitentFirm_ID

		outer apply (select iif(AssetSort.SecType = 'Bonds', 1, 0) IsBond) IsBond

		outer apply (select val com1 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 1) com1

		outer apply (select val com2 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 2) com2

		outer apply (select val com3 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 3) com3

		where ti.id = @OrderId







		select t.id TradeId

			, t.TradeDate, t.TradeTime, t.PayDate, t.PutDate, t.PayPlannedDate, t.PutPlannedDate

			, t.Qty, t.Volume1, t.Price, IsBond, aCur.ShortName PaymentCurrency, aPriceCur.ShortName PriceCurrency

			, t.Accruedint, t.Yield

			, com.Commission , com.CommissionCurrency, comExt.CommissionExt

			, replace(fcp.FirmShortName, 'Glocal GIM non-public, unclassifed, open-ended, conractual investment fund', 'Glocal СJSC') CPFirmShortName

			, t.Qty * a.BaseValue TotalNominal

			, a.BaseValue NominalValue

			, iif(t.IsAccrued <> 'y' or IsBond = 0, t.Volume1, t.Volume1 - t.Accruedint) CleanValue

			, iif(t.IsAccrued = 'y' or IsBond = 0, t.Volume1, t.Volume1 + t.Accruedint) TotalValue

			--, t.Comment

			, ti.AuthorComment Comment

			, t.BuySell

			, a.ShortName TradeAssetShortName

			, ts.Code TSCode

			, ts.IsMarket

			, t.CpFirm_ID	

			, t.CpTrade_ID

			, t.CrossRateDate, t.CurrPriceAsset_ID, t.CurrPayAsset_ID, t.CrossRate

			, t.IsAccrued

			, t.Qty * t.Price * iif(IsBond = 1, a.BaseValue / 100, 1) QtyXPrice

		into #t

		--from QORT_BACK_DB.dbo.TradeInstrLinks til with (nolock)

		from (

			select til1.TradeInstr_ID, til1.Trade_id

			from QORT_BACK_DB.dbo.TradeInstrLinks til1 with (nolock)

			where til1.TradeInstr_ID = @OrderId

			union all

			select til1.TradeInstr_ID, til1.Trade_id

			from QORT_BACK_DB.dbo.TIChangeTrades til1 with (nolock)

			where til1.TradeInstr_ID = @OrderId

		) til

		inner join QORT_BACK_DB.dbo.TradeInstrs ti with (nolock) on ti.id = til.TradeInstr_ID

		inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = til.Trade_ID

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = sec.TSSection_ID

		left outer join QORT_BACK_DB.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_ARM_SUPPORT.dbo.Assets_AS AssetSort with (nolock) on AssetSort.ConstInt = a.AssetSort_Const

		left outer join QORT_BACK_DB.dbo.Assets aCur with (nolock) on aCur.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB.dbo.Assets aPriceCur with (nolock) on aPriceCur.id = t.CurrPriceAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		outer apply (select iif(AssetSort.SecType = 'Bonds', 1, 0) IsBond) IsBond

		outer apply (

			select sum(p.QtyBefore) Commission, max(pCur.ShortName) CommissionCurrency

			from QORT_BACK_DB.dbo.Phases p with (nolock) 

			left outer join QORT_BACK_DB.dbo.Assets pCur with (nolock) on pCur.id = p.CurrencyAsset_ID

			where p.IsCanceled = 'n' and p.PC_Const = 9 and p.Trade_ID = t.id

		) com

		outer apply (

			select sum(p.QtyBefore) CommissionExt, max(pCur.ShortName) CommissionCurrencyExt

			from QORT_BACK_DB.dbo.Phases p with (nolock) 

			left outer join QORT_BACK_DB.dbo.Assets pCur with (nolock) on pCur.id = p.CurrencyAsset_ID

			where p.IsCanceled = 'n' and p.PC_Const = 23 and p.Trade_ID = t.id

		) comExt

		where til.TradeInstr_ID = @OrderId

			and t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y'



		update t set t.CPFirmShortName = 'Glocal СJSC'

		from #t t

		where t.CPFirmShortName like 'Glocal %'

		/*

		select *

		from #t t

		outer apply(select iif(t.PayDate = 0 or t.PutDate = 0, 1, 2) BeforeAfter ) BeforeAfter

		*/



		select top 1 @SecurityType = SecurityType, @IsPAIExclusion = IsPAIExclusion

		from ##o0323



		if @SecurityType = 'Currency' begin



			select ROW_NUMBER() over (order by t.TradeDate, t.TradeTime, t.TradeId) N

				, t.TradeId

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(t.TradeDate) TradeDate

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(t.PutDate) PutDate

				, iif(t.BuySell = 1, t.PaymentCurrency, t.TradeAssetShortName) CurSell

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(iif(t.BuySell = 1, t.Volume1, t.Qty)) VolSell

				, iif(t.BuySell = 2, t.PaymentCurrency, t.TradeAssetShortName) CurBuy

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(iif(t.BuySell = 2, t.Volume1, t.Qty)) VolBuy

				--, QORT_ARM_SUPPORT.dbo.fFloatToCurrency4(iif(t.BuySell = 1, t.Price, 1/nullif(t.Price, 0))) Rate

				, QORT_ARM_SUPPORT.dbo.fFloatToCurrency4(iif(t.Price >= 1, t.Price, 1/nullif(t.Price, 0))) Rate

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Commission) Commission

				, iif(t.CommissionExt > 0, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.CommissionExt), '0') Bonus

				, t.CommissionCurrency

				, t.TSCode

				, iif(t.CpFirm_ID > 0, iif(t.CPFirmShortName = @ArmBrokShortName, 'internal', 'external'), '') TransactionType -- Если галочка проставлена в поле Counterparty (корт)  заполнено любым значением, кроме  ArmBrok - external, если галочка проставлена и выб
ран Counterparty (корт)  - ArmBrok- internal 

				, o.OrderType

				, '' OtherSide

				--, o.com1, o.com2, o.com3

			into ##f0323

			from #t t

			cross join ##o0323 o



			--select * from ##f0323



		end else begin



			update o set o.OrderType = o.QuantitativeCondition +', ' + o.OrderType + ', ' + o.OrderConditions

			from ##o0323 o



			if exists(select top 1 1 from #t t where t.PutDate > 0) set @IsSettled = 1



			select ROW_NUMBER() over (order by t.TradeDate, t.TradeTime, t.TradeId) N

				, t.TradeId

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(t.TradeDate) TradeDate

				--, iif(t.TradeTime > 0, QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(t.TradeTime), '') TradeTime

				--, '' TradeTime

				, iif(t.TradeTime > 0 and t.IsMarket = 'y', QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(t.TradeTime), '') TradeTime				

				--, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(iif(BeforeAfter = 1, t.PayPlannedDate, t.PayDate)) PayDate

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(iif(BeforeAfter = 1, iif(@BeforeAfter = 1, t.PayDate, t.PayPlannedDate), t.PayDate)) PayDate

				--, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(iif(BeforeAfter = 1, t.PutPlannedDate, t.PutDate)) PutDate

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(iif(t.PutDate <= 1, t.PutPlannedDate, t.PutDate)) PutDate

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Qty) Qty

				, iif(t.TotalNominal > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.TotalNominal), '') TotalNominal

				--, iif(t.IsBond = 1, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Price) + '%', '') PricePercent

				, iif(t.IsBond = 1, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(t.Price) + '%', '') PricePercent

				, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(t.Price * iif(t.IsBond = 1, t.NominalValue / 100, 1)) Price

				--, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.CleanValue/TrueCrossRate) CleanValue

				--, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Accruedint/TrueCrossRate) ACI

				--, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.TotalValue/TrueCrossRate) TotalValuePrice



				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.QtyXPrice) CleanValue

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Accruedint/TrueCrossRate) ACI

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(iif(t.IsAccrued = 'y' and IsBond = 1, t.QtyXPrice + t.Accruedint/TrueCrossRate, t.QtyXPrice)) TotalValuePrice



				--, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(TrueCrossRate) TrueCrossRate

				, QORT_ARM_SUPPORT.dbo.fFloatCrossRateToVarchar(TrueCrossRate) TrueCrossRate				

				, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.TotalValue) TotalValuePay

				--, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Yield) Yield

				, iif(t.IsBond = 1, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(t.Yield) + '%', '') Yield

				--, iif(BeforeAfter = 1, t.Comment, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Commission)) Commission

				--, iif(BeforeAfter = 1, '0', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.CommissionExt)) Bonus

				, iif(@BeforeAfter = -1, isnull(com1, ''), iif(t.Commission > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(t.Commission), '')) Commission

				, iif(@BeforeAfter = -1, isnull(com2, ''), QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(isnull(t.CommissionExt, 0))) Bonus

				, iif(t.CPFirmShortName in (@ArmBrokShortName, 'Glocal СJSC'), CPFirmShortName, iif(CPFirmShortName <> '' and t.CpTrade_ID > 0, 'Other Client', '')) OtherPartyOfTransaction

				, iif(t.PutDate > 0 /*and @BeforeAfter = 2*/, 'Settled', 'Not settled') Settled

				--, o.com1, o.com2, o.com3

			into ##t0323

			from #t t

			outer apply(select iif(/*t.PayDate = 0 or*/ t.PutDate = 0, 1, 2) BeforeAfter ) BeforeAfter

			outer apply (select case when CurrPriceAsset_ID = t.CurrPayAsset_ID then 1 

				when CurrPriceAsset_ID <> t.CurrPayAsset_ID and t.CrossRate <> 1 and t.CrossRateDate = 0 then t.CrossRate

				when CurrPriceAsset_ID <> t.CurrPayAsset_ID and t.CrossRate = 1 and t.CrossRateDate > 0 then QORT_ARM_SUPPORT.dbo.fCrossRateOnDate(t.CrossRateDate, t.CurrPriceAsset_ID, t.CurrPayAsset_ID)

				else 1 end TrueCrossRate) CR

			cross join (select com1, com2, com3 from ##o0323 o) o

			-- where BeforeAfter = @BeforeAfter or @BeforeAfter = 1

			-- where @BeforeAfter = 1 and (t.PayDate = 0 or t.PutDate = 0)

			-- where @BeforeAfter = 2 and (t.PayDate > 0 and t.PutDate > 0)



			--select * from #t

			--select * from ##t0323

			if @IsPAIExclusion = 1 begin

				update t set t.CleanValue = t.TotalValuePay, t.TotalValuePrice = t.TotalValuePay

				from ##t0323 t

			end



		end

		

		--update o set o.PaymentCurrency = isnull(t.PaymentCurrency, o.PaymentCurrency)

		update o set o.PaymentCurrency = isnull(t.PriceCurrency, o.PaymentCurrency)

			, o.SettlementCurrency = isnull(t.PaymentCurrency, o.SettlementCurrency)

			, o.CommissionCurrency = coalesce(t.CommissionCurrency/*, t.PaymentCurrency*/, o.CommissionCurrency)

		from ##o0323 o

		outer apply( select top 1 PaymentCurrency, CommissionCurrency, PriceCurrency from #t t) t



		update o set o.CommissionCurrency = 'AMD' -- для ЦБ для физиков ставим AMD

		from ##o0323 o

		where  o.IsFirm = 'n' and o.SecurityType <> 'Currency'



		--select * from ##o0323

		--select * from ##t0323







		if @SecurityType = 'Currency' begin

				set @FileNameEmpty = 'trade_fx_02.xlsx'

				set @Sheet = '1 TC_Currecny_Long'

				set @FileDirRes = @FileDirResFX

				set @NewFileName = 'order_'+ cast(@OrderID as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '_fx_long' + '.xlsx'

				set @NewFileNameRes = 'order_'+ cast(@OrderId as varchar) + '_fx_long' + '.xlsx'

		end else begin

			if @BeforeAfter = 1 begin

				set @FileNameEmpty = 'trade_before_02.xlsx'

				set @Sheet = '3Trade Confirm Before sett_Long'

				set @FileDirRes = @FileDirResBefore

			end else begin

				set @FileNameEmpty = 'trade_after_02.xlsx'

				set @Sheet = '4 Trade Confirmation_Long'

				set @FileDirRes = @FileDirResAfter

			end

		end



		--select @SecurityType, @FileNameEmpty, @Sheet, @FileDirRes





		set @cmd = 'copy "' + @FileDir + @FileNameEmpty + '" "' + @FileDirOut + @NewFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @FileDirOut + @NewFileName

			RAISERROR (@execres, 16, 1);

		end







		if @SecurityType = 'Currency' begin



			SET @sql = N'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$D3:D3]'')

			select ConstitutorCode from ##o0323 order by 1;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$H3:H3]'')

			select QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(cast(convert(varchar, getdate(), 112) as int));'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$K3:K3]'')

			select RegisterNum from ##o0323 order by 1;'

			/*

			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$K4:K4]'')

			select ' + cast(@OrderId as varchar) + ';'

			*/

			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$O3:O3]'')

			select QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(OrderDate) from ##o0323 order by 1;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A7:P7]'')

			select * from ##f0323 order by 1;'



		end else begin



			SET @sql = N'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$H3:H3]'')

			select ConstitutorCode from ##o0323 order by 1;'

			/*

			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$M3:M3]'')

			select ' + cast(@OrderId as varchar) + ';'

			*/

			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$R3:R3]'')

			select QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(cast(convert(varchar, getdate(), 112) as int));'

			--select QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(OrderDate) from ##o0323 order by 1;'





			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$B7:B7]'')

			select IssuerFirmShortName from ##o0323 order by 1;;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$E7:E7]'')

			select ISIN from ##o0323 order by 1;;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$G7:K7]'')

			select IssueNumber, NominalPerInstrument, SecurityType, AssetBaseCurrency, OrderDescription from ##o0323 order by 1;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$B11:B11]'')

			select OrderType from ##o0323 order by 1;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$E11:K11]'')

			select RegisterNum, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(OrderDate), OrderBuySellTXT, TSCode, PaymentCurrency, SettlementCurrency, CommissionCurrency from ##o0323 order by 1;'

			--select RegisterNum, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(OrderDate), TransactionType, TSCode, PaymentCurrency, SettlementCurrency, CommissionCurrency from ##o0323 order by 1;'



			+ 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$B14:U14]'')

			select * from ##t0323 order by 1;'



			--*/

			/*

			if @IsSettled = 1 begin

				set @sql = @sql		

					+ N' UPDATE t SET t.F1 = N''Առաքման ամսաթիվ/Delivery date''

					from OPENROWSET (

					''Microsoft.ACE.OLEDB.12.0'',

					''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

					''SELECT * FROM [' + @Sheet + '$G13:G14]'') t;'

			end

			*/



			if @BeforeAfter = 1 and exists(select top 1 1 from ##o0323 o where o.OwnerFirmShortName like '% Sinara %') begin



				set @sql = @sql

					+ 'insert into OPENROWSET (

					''Microsoft.ACE.OLEDB.12.0'',

					''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

					''SELECT * FROM [' + @Sheet + '$B24:B24]'')

					select ''' + @SinaraBeforeAdd + ''';'



				set @sql = @sql		

					+ ' UPDATE t SET t.F1 = t.F1 + ''*''

					from OPENROWSET (

					''Microsoft.ACE.OLEDB.12.0'',

					''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

					''SELECT * FROM [' + @Sheet + '$G13:G14]'') t;'



			end





		end



		--set @sql = cast(@sql as nvarchar(max))



		--select IssuerFirmShortName, ISIN, IssueNumber, NominalPerInstrument, SecurityType, AssetBaseCurrency, OrderDescription from ##o0323 order by 1;

		--select OrderType, RegisterNum, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(OrderDate), TransactionType, TSCode, PaymentCurrency, SettlementCurrency, CommissionCurrency	from ##o0323 order by 1;



		print @sql

		exec(@sql)





		



		set @cmd = 'copy "' + @FileDirOut + @NewFileName + '" "' + @FileDirRes + @NewFileNameRes + '" /Y'



		delete r from @res r

		insert into @res(r) exec master.dbo.xp_cmdshell @cmd

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @FileDirRes + @NewFileNameRes

			RAISERROR (@execres, 16, 1);

		end



		select @resultStatus = 'Done', @resultPath = @FileDirRes, @resultColor = 'green'



	end try

	begin catch

		--while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		print @Message

		--insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @resultStatus = @Message, @resultColor = 'red'

	end catch



	set @resultDateTime = convert(varchar, getdate(), 102) + ' ' + convert(varchar, getdate(), 108)

	--select @TradeId, @resultStatus, @resultPath, @resultColor, @resultDateTime



END

