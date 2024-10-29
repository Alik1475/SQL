





-- exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 6916

-- exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 5843

/*

	exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 6709

	exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 6916

	exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 6948

	exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 6245 -- с поручением

	exec QORT_ARM_SUPPORT.dbo.exportTradeConfirmation @TradeId = 7071



	6245, 6916

*/



CREATE PROCEDURE [dbo].[exportTradeConfirmation]

	@TradeId bigint

	, @resultStatus varchar(1024) = null out 

	, @resultPath varchar(255) = null out

	, @resultColor varchar(32) = null out

	, @resultDateTime varchar(32) = null out

AS

BEGIN



	SET NOCOUNT ON



	begin try

		--declare @resultStatus varchar(1024)

		--declare @resultPath varchar(255)

		--declare @resultColor varchar(32)

		--declare @resultDateTime varchar(32)



		declare @Message varchar(1024)

		declare @ArmBrokShortName varchar(32) = 'Armbrok OJSC'

		/*declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\out'

		declare @FileDirResOTC varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\OTC_Sec'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\FX'*/

		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Technical do not delete\Templates for Confo'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\Archive'

		declare @FileDirResOTC varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\OTC_SPOT'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\OTC_FX'

		if right(@FileDir, 1) <> '' set @FileDir = @FileDir + '\'

		if right(@FileDirOut, 1) <> '' set @FileDirOut = @FileDirOut + '\'

		if right(@FileDirResOTC, 1) <> '' set @FileDirResOTC = @FileDirResOTC + '\'

		if right(@FileDirResFX, 1) <> '' set @FileDirResFX = @FileDirResFX + '\'

		declare @FileDirRes varchar(255)

		declare @FileNameData varchar(128) --= 'sec_06.xlsx'

		declare @FileNameEmpty varchar(128) --= 'sec_06e.xlsx'

		declare @ReportDate int = cast(convert(varchar, getdate(), 112) as int)

		declare @Sheet varchar(64) = 'Security'



		declare @NewFileName varchar(255) = 'trade_'+ cast(@TradeID as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx'

		declare @NewFileNameRes varchar(255) = 'trade_'+ cast(@TradeID as varchar) + '.xlsx'

		print @NewFileName



		declare @res table(r varchar(255))



		declare @cmd varchar(512)





		--select @execres



		--return



		declare @sql varchar(max)



		if OBJECT_ID('tempdb..##t07', 'U') is not null drop table ##t07

		if OBJECT_ID('tempdb..##rep07', 'U') is not null drop table ##rep07

		if OBJECT_ID('tempdb..##bal07', 'U') is not null drop table ##bal07

		if OBJECT_ID('tempdb..##balPos', 'U') is not null drop table ##balPos

		create table ##rep07 (repFrom varchar(128), repTo varchar(128))

		create table ##bal07 (Num int identity, Currency varchar(32), Balance float)

		create table ##balPos (a int, c varchar(32))



		--insert into ##rep07(repFrom, repTo) values ('aa', 'a0'), ('cc', 'c0')

		--insert into ##rep07(repFrom, repTo) values ('0', '(zero)'), ('1', '(one)')



		declare @TrueTradeId int

		declare @TradeDate int

		declare @SubAccCode varchar(128)

		declare @SubAccID int

		declare @FirmShortName varchar(128)

		declare @ISIN varchar(128)

		declare @AssetShortName varchar(128)

		declare @AssetName varchar(128)

		declare @AssetClass_Const int

		declare @AssetType_Const int

		declare @AssetSort_Const int

		declare @SecurityType varchar(128) = '??? @SecurityType ???'

		declare @IssuerShortName varchar(128)

		declare @TransactionType varchar(128)

		declare @TSSectionName varchar(128)

		declare @TransactionMarket varchar(128)

		declare @TradeTime int

		declare @ExpectedSettlementDate int

		declare @SettlementDate int

		declare @PaymentDate int

		declare @NominalValue float

		declare @TradeCurrency varchar(128)

		declare @PriceCurrency varchar(128)

		declare @AssetCurrency varchar(128)

		declare @Quantity float

		declare @Yield float

		declare @TotalNominal float

		declare @Price float

		declare @PricePercent float

		declare @Volume1 float

		declare @Accruedint float

		declare @CleanValue float

		declare @TotalValue float

		declare @Commission float

		declare @CommissionCurrrency varchar(128)

		declare @TransactionStatus varchar(128) = 'Settled'

		declare @OtherPartyOfTransaction varchar(128) = 'Other'

		declare @IsAccrued varchar(1)

		declare @IsBond bit

		declare @Bonus float

		declare @BonusString varchar(32)

		declare @TrnType varchar(32)



		declare @CurrencyBuy varchar(32)

		declare @CurrencySell varchar(32)

		declare @VolumeBuy float

		declare @VolumeSell float

		declare @RateBuy float

		declare @RateSell float



		declare @OrderType varchar(128) = ''

		declare @OrderNums varchar(512) = ''

		declare @OrderComments varchar(512) = ''





		select @TrueTradeId = t.id, @TradeDate = t.TradeDate, @TradeTime = t.TradeTime, @SubAccCode = s.SubAccCode, @firmShortName = fo.FirmShortName

			, @ISIN = a.ISIN, @AssetShortName = a.ShortName

			, @AssetName = a.Name

			, @AssetClass_Const = a.AssetClass_Const, @AssetType_Const = a.AssetType_Const, @AssetSort_Const = a.AssetSort_Const

			, @IssuerShortName = fi.FirmShortName

			, @TransactionType = iif(t.BuySell = 1, 'Buy', 'Sell')

			, @TSSectionName = tss.Name, @TransactionMarket = ts.Code

			--, @OrderType = 'OrderType'

			, @ExpectedSettlementDate = t.PutPlannedDate, @SettlementDate = t.PutDate, @PaymentDate = t.PayDate

			, @NominalValue = a.BaseValue, @TradeCurrency = aPay.ShortName

			, @PriceCurrency = aPrice.ShortName

			, @AssetCurrency = aCur.ShortName

			, @Quantity = t.Qty

			, @Yield = t.Yield 

			, @TotalNominal = t.Qty * a.BaseValue

			, @Price = t.Price, @Volume1 = t.Volume1, @Accruedint = t.Accruedint

			, @SecurityType = isnull(AssetSort.SecType, @SecurityType)

			, @IsAccrued = t.IsAccrued

			, @Commission = isnull(Comm.Comm, 0)

			, @CommissionCurrrency = aCommCur.ShortName

			, @OtherPartyOfTransaction = fcp.FirmShortName

			, @Bonus = pBonus.pBonus

			, @BonusString = aBonusCur.ShortName

			, @SubAccID = s.id

		from QORT_BACK_DB.dbo.Trades t with (nolock)

		left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.Firms fi with (nolock) on fi.id = a.EmitentFirm_ID

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		left outer join QORT_BACK_DB.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_BACK_DB.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

		left outer join QORT_BACK_DB.dbo.Assets aCur with (nolock) on aCur.id = a.BaseCurrencyAsset_ID

		left outer join QORT_ARM_SUPPORT.dbo.Assets_AS AssetSort with (nolock) on AssetSort.ConstInt = a.AssetSort_Const

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		outer apply (select -sum(p.QtyBefore * p.QtyAfter) Comm, max(p.PhaseAsset_ID) CommAsset from QORT_BACK_DB.dbo.Phases p with (nolock) where p.Trade_ID = @TradeId and p.IsCanceled = 'n' and p.Enabled = 0 and p.PC_Const = 9) Comm

		outer apply (select abs(sum(p.QtyBefore * p.QtyAfter)) pBonus, max(p.PhaseAsset_ID) pBonusAsset from QORT_BACK_DB.dbo.Phases p with (nolock) where p.Trade_ID = @TradeId and p.IsCanceled = 'n' and p.Enabled = 0 and p.PC_Const = 11) pBonus

		left outer join QORT_BACK_DB.dbo.Assets aCommCur with (nolock) on aCommCur.id = Comm.CommAsset

		left outer join QORT_BACK_DB.dbo.Assets aBonusCur with (nolock) on aBonusCur.id = pBonus.pBonusAsset

		where t.id = @TradeId

		order by 1 desc



		if @TrueTradeId is null RAISERROR ('Trade Not Found', 16, 1);



		if @SecurityType = 'Currency' begin

			set @FileDirRes = @FileDirResFX

			set @FileNameData = 'fx_02.xlsx'

			set @FileNameEmpty = 'fx_02e.xlsx'

			set @Sheet = 'FX'



			if @TransactionType = 'Buy' begin

				set @CurrencyBuy = @AssetName

				set @CurrencySell = @PriceCurrency

				set @VolumeBuy = @Quantity

				set @VolumeSell = @Volume1

				set @RateBuy = @Volume1 / nullif(@Quantity, 0)

				set @RateSell = @Quantity / nullif(@Volume1, 0)

			end else begin

				set @CurrencyBuy = @PriceCurrency

				set @CurrencySell = @AssetName

				set @VolumeBuy = @Volume1

				set @VolumeSell = @Quantity

				set @RateBuy = @Quantity / nullif(@Volume1, 0)

				set @RateSell = @Volume1 / nullif(@Quantity, 0)

			end



			if @RateBuy < 0.5 set @RateBuy = 0

			if @RateSell < 0.5 set @RateSell = 0



		end else begin

			set @FileDirRes = @FileDirResOTC

			set @FileNameData = 'sec_06.xlsx'

			set @FileNameEmpty = 'sec_06e.xlsx'

			set @Sheet = 'Security'

		end



		set @cmd = 'copy "' + @FileDir + @FileNameEmpty + '" "' + @FileDirOut + @NewFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @FileDirOut + @NewFileName

			RAISERROR (@execres, 16, 1);

		end



		if (@IsAccrued <> 'y' or @SecurityType <> 'Bonds') set @CleanValue = @Volume1 else set @CleanValue = @Volume1 - @Accruedint

		if (@IsAccrued = 'y' or @SecurityType <> 'Bonds') set @TotalValue = @Volume1 else set @TotalValue = @Volume1 + @Accruedint

		set @OtherPartyOfTransaction = iif(@OtherPartyOfTransaction = @ArmBrokShortName, @OtherPartyOfTransaction, 'Other')

		if @ISIN = '' set @ISIN = @AssetShortName

		set @TransactionStatus = iif(@PaymentDate > 0 and @SettlementDate > 0, 'Settled', 'Unsettled')

		set @IsBond = iif(@SecurityType = 'Bonds', 1, 0)

		if @Bonus <> 0 and @BonusString <> '' 

			set @BonusString = @BonusString + ' ' + QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Bonus)

			else set @BonusString = '0%'

		set @TrnType = iif(@OtherPartyOfTransaction = @ArmBrokShortName, 'internal', 'external')



		declare @BalancesTitle varchar(256)

		if @PaymentDate > 0 

			set @BalancesTitle = 'Balance as of the end of ' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@PaymentDate)

			else set @BalancesTitle = 'Balance at the time of report creation'





		--select top 1 @OrderType = 'Partial, ' + case ti.PRC_Const when 2 then 'Limit, ' when 3 then 'Market, ' else 'Other, ' end + iif(ti.Date2> 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.Date2), 'Open')

		--select top 1 @OrderType = iif(ti.IsComplete = 'y', 'All or none, ', 'Partial, ') + case ti.PRC_Const when 2 then 'Limit, ' when 3 then 'Market, ' else 'Other, ' end + iif(ti.Date2> 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.Date2), 'Open')		

		select top 1 @OrderType = iif(ti.IsComplete = 'y', 'All or none, ', 'Partial, ') 

			+ case ti.PRC_Const when 2 then 'Limit, ' when 3 then 'Market, ' when 4 then 'Limit, ' when 5 then 'Limit, ' else 'Other, ' end 

			+ iif(ti.Date2> 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.Date2), 'Open')		

		from QORT_BACK_DB.dbo.TradeInstrLinks til with (nolock)

		inner join QORT_BACK_DB.dbo.TradeInstrs ti with (nolock) on ti.id = til.TradeInstr_ID

		where til.Trade_ID = @TradeId

		order by til.id



		if @OrderType <> '' begin

			select @OrderNums = isnull(cast((

				select ti.RegisterNum + '; '

				from QORT_BACK_DB.dbo.TradeInstrLinks til with (nolock)

				inner join QORT_BACK_DB.dbo.TradeInstrs ti with (nolock) on ti.id = til.TradeInstr_ID

				where til.Trade_ID = @TradeId and ti.RegisterNum <> ''

				order by til.id

				for xml path('')

			) as varchar(max)), '')

			if @OrderNums <> '' set @OrderNums = left(@OrderNums, len(@OrderNums)-1)



			select @OrderComments = isnull(cast((

				select ti.AuthorComment + '; '

				from QORT_BACK_DB.dbo.TradeInstrLinks til with (nolock)

				inner join QORT_BACK_DB.dbo.TradeInstrs ti with (nolock) on ti.id = til.TradeInstr_ID

				where til.Trade_ID = @TradeId and ti.AuthorComment <> ''

				order by til.id

				for xml path('')

			) as varchar(max)), '')

			if @OrderComments <> '' set @OrderComments = left(@OrderComments, len(@OrderComments)-1)

		end



		insert into ##rep07(repFrom, repTo)

		select *

		from (values 

			('@TradeId', cast(@TradeId as varchar(128))) 

			, ('@ReportDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@ReportDate))

			, ('@TradeDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@TradeDate))

			, ('@SubAccCode', @SubAccCode)

			, ('@FirmShortName', isnull(@FirmShortName, ''))

			, ('@ISIN', @ISIN)

			, ('@AssetShortName', @AssetShortName)

			, ('@AssetName', @AssetName)

			, ('@IssuerShortName', isnull(@IssuerShortName, ''))

			, ('@TransactionType', @TransactionType)

			, ('@TSSectionName', @TSSectionName)

			, ('@TransactionMarket', @TransactionMarket)

			, ('@OrderType', @OrderType)

			, ('@OrderNums', @OrderNums)

			, ('@OrderComments', @OrderComments)

			, ('@SecurityType', @SecurityType)

			, ('@TradeTime', QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(@TradeTime))

			, ('@ExpectedSettlementDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@ExpectedSettlementDate))

			, ('@SettlementDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@SettlementDate))

			, ('@PaymentDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@PaymentDate))

			, ('@NominalValue', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@NominalValue))

			, ('@TradeCurrency', @TradeCurrency)

			, ('@PriceCurrency', @PriceCurrency)

			, ('@AssetCurrency', isnull(@AssetCurrency, ''))

			, ('@Quantity', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Quantity))

			--, ('@Yield', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Yield)+ '%')

			--, ('@Yield', cast(@Yield as varchar)+ '%')

			, ('@Yield', QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(@Yield)+ '%')

			, ('@TotalNominal', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@TotalNominal))--*/

			, ('@PricePercents', iif(@IsBond = 1, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Price) + '%', ''))

			, ('@Price', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Price * iif(@IsBond = 1, @NominalValue / 100, 1)))

			, ('@Volume1', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Volume1))

			, ('@Accruedint', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Accruedint))

			, ('@CleanValue', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@CleanValue))

			, ('@TotalValue', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@TotalValue))

			, ('@CommissionCurrrency', isnull(@CommissionCurrrency, ''))

			, ('@Commission', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Commission))

			, ('@TransactionStatus', @TransactionStatus)

			, ('@OtherPartyOfTransaction', @OtherPartyOfTransaction)

			, ('@Bonus', @BonusString)

			, ('@TrnType', @TrnType)



			, ('@CurrencyBuy', @CurrencyBuy)

			, ('@CurrencySell', @CurrencySell)

			, ('@VolumeBuy', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@VolumeBuy))

			, ('@VolumeSell', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@VolumeSell))

			, ('@RateBuy', QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(round(@RateBuy, 4)))

			, ('@RateSell', QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(round(@RateSell, 4)))

			, ('@BalancesTitle', @BalancesTitle)


		) as t(repFrom, repTo)





		SET @sql = 'SELECT * INTO ##t07

		FROM OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDir+@FileNameData + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet + '$A1:U100000]'')'



		exec(@sql)









		declare @columns varchar(1024)

		declare @columnsCount int



		select @columnsCount = count(*)

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##t07')

		and c.name like 'F_%'





		select @columns = cast((

		select c.name + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##t07')

		and c.name like 'F_%'

		order by column_id

		for xml path('')) as varchar(1024))



		select @columns = left(@columns, len(@columns) - 1)

		--select @columnsCount, @columns





		select @sql = cast((

		select 't.' + c.name + ' = replace(t.' + c.name + ', ''@repFrom'', ''@repTo'')' + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##t07')

		and c.name like 'F%'

		order by column_id

		for xml path('')) as varchar(1024))



		select @sql = 'update t set ' + left(@sql, len(@sql) - 1) + ' from ##t07 t'



		select @sql = cast((

		select replace(replace(@sql, '@repFrom', r.repFrom), '@repTo', r.repTo) + ';'

		from ##rep07 r

		for xml path('')) as varchar(max))



		print @sql



		exec(@sql)



		delete t

		from ##t07 t

		where a is null



		/*

		select *

		from ##t07 t

		order by a

		*/

		declare @BalanceDate int

		if @PaymentDate > 0 set @BalanceDate = @PaymentDate else set @BalanceDate = @ReportDate

		declare @TodayInt int = cast(convert(varchar, getdate(), 112) as int)

		declare @BalanceTitleStart varchar(32) = '@CashBalanceStart'

		declare @BalanceColumn1 varchar(32)

		declare @BalanceColumn2 varchar(32)

		declare @BalanceRowStart int



		select @sql = cast((

		select 'select a, ''' + c.name + ''' c from ##t07 where cast(' + c.Name + ' as varchar) = ''' + @BalanceTitleStart + ''' union all '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##t07')

		and c.name like 'F%'

		order by column_id

		for xml path('')) as varchar(max))



		set @sql = 'insert into ##balPos(a, c) ' + left(@sql, len(@sql) - 10)



		print @sql

		exec(@sql)



		select top 1 @BalanceRowStart = a, @BalanceColumn1 = c, @BalanceColumn2 = left(c, 1) + cast(cast(right(c, len(c)-1) as int) + 2 as varchar)

		from ##balPos p



		if @BalanceDate < @TodayInt begin

			insert into ##bal07(Currency, Balance)

			select a.ShortName, sum(ph.VolFree)

			from QORT_BACK_DB.dbo.PositionHist ph with (nolock)

			inner join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = ph.Asset_ID

			where ph.OldDate = @BalanceDate and ph.Subacc_ID = @SubAccID and a.AssetType_Const = 3 and abs(ph.VolFree) > 1e-8

			group by a.ShortName order by 1

		end else begin

			insert into ##bal07(Currency, Balance)

			select a.ShortName, sum(ph.VolFree)

			from QORT_BACK_DB.dbo.Position ph with (nolock)

			inner join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = ph.Asset_ID

			where ph.Subacc_ID = @SubAccID and a.AssetType_Const = 3 and abs(ph.VolFree) > 1e-8

			group by a.ShortName order by 1

		end



		set @sql = 'update t set t.' + @BalanceColumn2 + ' = b.Currency, t.' + @BalanceColumn1 + ' = QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(b.Balance)

			from ##bal07 b

			inner join ##t07 t on t.a = b.Num*2 + ' + cast(@BalanceRowStart as varchar) + ' - 2'

		

		--select @BalanceRowStart, @BalanceColumn2, @BalanceColumn1, @BalanceTitleStart



		if @BalanceRowStart > 0 

		exec(@sql)





		SET @sql = 'insert into OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet + '$B1:'+char(ascii('B') + @columnsCount-1)+'1]'')

		select ' + @columns + ' from ##t07 order by a'





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

		--return

		/*

		insert into OPENROWSET (

		'Microsoft.ACE.OLEDB.12.0',

		'Excel 12.0; Database=\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\sec_01a.xlsx; HDR=YES;IMEX=0',

		'SELECT * FROM [Security$B1:P1]')

		select F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16 from ##t07 order by a

		*/





	end try

	begin catch

		--while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		--insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @resultStatus = @Message, @resultColor = 'red'

	end catch



	set @resultDateTime = convert(varchar, getdate(), 102) + ' ' + convert(varchar, getdate(), 108)

	--select @TradeId, @resultStatus, @resultPath, @resultColor, @resultDateTime



END

