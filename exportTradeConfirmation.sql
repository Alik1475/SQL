





-- exec QORT_ARM_SUPPORT_TEST.dbo.exportTradeConfirmation @TradeId = 6916



CREATE PROCEDURE [dbo].[exportTradeConfirmation]

	@TradeId bigint

	, @resultStatus varchar(1024) out

	, @resultPath varchar(255) out

	, @resultColor varchar(32) out

	, @resultDateTime varchar(32) out

AS

BEGIN



	SET NOCOUNT ON



	begin try

		--declare @resultStatus varchar(1024)

		--declare @resultPath varchar(255)

		--declare @resultColor varchar(32)

		--declare @resultDateTime varchar(32)



		declare @Message varchar(1024)

		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\out'

		declare @FileDirRes varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\result'

		if right(@FileDir, 1) <> '' set @FileDir = @FileDir + '\'

		if right(@FileDirOut, 1) <> '' set @FileDirOut = @FileDirOut + '\'

		if right(@FileDirRes, 1) <> '' set @FileDirRes = @FileDirRes + '\'

		declare @FileNameData varchar(128) = 'sec_04.xlsx'

		--declare @FileNameEmpty varchar(128) = 'sec_01a.xlsx'

		declare @FileNameEmpty varchar(128) = 'sec_04e.xlsx'





		declare @NewFileName varchar(255) = 'trade_'+ cast(@TradeID as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx'

		declare @NewFileNameRes varchar(255) = 'trade_'+ cast(@TradeID as varchar) + '.xlsx'

		print @NewFileName



		declare @res table(r varchar(255))



		declare @cmd varchar(512)





		--select @execres



		--return



		declare @Sheet varchar(64) = 'Security'

		declare @sql varchar(max)



		if OBJECT_ID('tempdb..##t07', 'U') is not null drop table ##t07

		if OBJECT_ID('tempdb..##rep07', 'U') is not null drop table ##rep07

		create table ##rep07 (repFrom varchar(128), repTo varchar(128))



		--insert into ##rep07(repFrom, repTo) values ('aa', 'a0'), ('cc', 'c0')

		--insert into ##rep07(repFrom, repTo) values ('0', '(zero)'), ('1', '(one)')



		declare @TrueTradeId int

		declare @TradeDate int

		declare @SubAccCode varchar(128)

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

		declare @OrderType varchar(128)

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



		select @TrueTradeId = t.id, @TradeDate = t.TradeDate, @TradeTime = t.TradeTime, @SubAccCode = s.SubAccCode, @firmShortName = fo.FirmShortName

			, @ISIN = a.ISIN, @AssetShortName = a.ShortName

			, @AssetName = a.Name

			, @AssetClass_Const = a.AssetClass_Const, @AssetType_Const = a.AssetType_Const, @AssetSort_Const = a.AssetSort_Const

			, @IssuerShortName = fi.FirmShortName

			, @TransactionType = iif(t.BuySell = 1, 'Buy', 'Sell')

			, @TSSectionName = tss.Name, @TransactionMarket = ts.Code

			, @OrderType = 'OrderType'

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

		from QORT_BACK_DB_TEST.dbo.Trades t with (nolock)

		left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		left outer join QORT_BACK_DB_TEST.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB_TEST.dbo.Firms fi with (nolock) on fi.id = a.EmitentFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		left outer join QORT_BACK_DB_TEST.dbo.TSs ts with (nolock) on ts.id = tss.TS_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets aPrice with (nolock) on aPrice.id = t.CurrPriceAsset_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets aCur with (nolock) on aCur.id = a.BaseCurrencyAsset_ID

		left outer join QORT_ARM_SUPPORT_TEST.dbo.Assets_AS AssetSort with (nolock) on AssetSort.ConstInt = a.AssetSort_Const

		left outer join QORT_BACK_DB_TEST.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		outer apply (select -sum(p.QtyBefore * p.QtyAfter) Comm, max(p.PhaseAsset_ID) CommAsset from QORT_BACK_DB_TEST.dbo.Phases p with (nolock) where p.Trade_ID = @TradeId and p.IsCanceled = 'n' and p.Enabled = 0 and p.PC_Const = 9) Comm

		left outer join QORT_BACK_DB_TEST.dbo.Assets aCommCur with (nolock) on aCommCur.id = Comm.CommAsset

		where t.id = @TradeId

		order by 1 desc



		if @TrueTradeId is null RAISERROR ('Trade Not Found', 16, 1);





		set @cmd = 'copy "' + @FileDir + @FileNameEmpty + '" "' + @FileDirOut + @NewFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @FileDirOut + @NewFileName

			RAISERROR (@execres, 16, 1);

		end



		if (@IsAccrued <> 'y' or @SecurityType <> 'Bonds') set @CleanValue = @Volume1 else set @CleanValue = @Volume1 - @Accruedint

		if (@IsAccrued <> 'y' or @SecurityType <> 'Bonds') set @TotalValue = @Volume1 else set @TotalValue = @Volume1 + @Accruedint

		set @OtherPartyOfTransaction = iif(@OtherPartyOfTransaction = 'ArmBrok', @OtherPartyOfTransaction, 'Other')

		if @ISIN = '' set @ISIN = @AssetShortName



		insert into ##rep07(repFrom, repTo)

		select *

		from (values 

			('@TradeId', cast(@TradeId as varchar(128))) 

			, ('@TradeDate', QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarchar(@TradeDate))

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

			, ('@SecurityType', @SecurityType)

			, ('@TradeTime', QORT_ARM_SUPPORT_TEST.dbo.fIntToTimeVarchar(@TradeTime))

			, ('@ExpectedSettlementDate', QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarchar(@ExpectedSettlementDate))

			, ('@SettlementDate', QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarchar(@SettlementDate))

			, ('@PaymentDate', QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarchar(@PaymentDate))

			, ('@NominalValue', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@NominalValue))

			, ('@TradeCurrency', @TradeCurrency)

			, ('@PriceCurrency', @PriceCurrency)

			, ('@AssetCurrency', isnull(@AssetCurrency, ''))

			, ('@Quantity', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Quantity))

			, ('@Yield', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Yield)+ '%')

			, ('@TotalNominal', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@TotalNominal))--*/

			, ('@Price', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Price))

			, ('@Volume1', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Volume1))

			, ('@Accruedint', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Accruedint))

			, ('@CleanValue', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@CleanValue))

			, ('@TotalValue', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@TotalValue))

			, ('@CommissionCurrrency', isnull(@CommissionCurrrency, ''))

			, ('@Commission', QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar(@Commission))

			, ('@TransactionStatus', @TransactionStatus)

			, ('@OtherPartyOfTransaction', @OtherPartyOfTransaction)

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

		--insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @resultStatus = @Message, @resultColor = 'red'

	end catch



	set @resultDateTime = convert(varchar, getdate(), 102) + ' ' + convert(varchar, getdate(), 108)

	--select @TradeId, @resultStatus, @resultPath, @resultColor, @resultDateTime



END

