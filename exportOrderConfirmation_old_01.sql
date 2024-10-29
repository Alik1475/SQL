







/*

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 10

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 11

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 4877

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 4900

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 5454

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 5454, @repoStep = 1

	exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = 5616

*/



CREATE PROCEDURE [dbo].[exportOrderConfirmation]

	@OrderId bigint

	, @resultStatus varchar(1024) = null out 

	, @resultPath varchar(255) = null out

	, @resultColor varchar(32) = null out

	, @resultDateTime varchar(32) = null out

	, @repoStep tinyint = 0 -- 0 - order, 1 - trade, 2- change

AS

BEGIN



	SET NOCOUNT ON



	begin try





		declare @Message varchar(1024)

		declare @ArmBrokShortName varchar(32) = 'Armbrok OJSC'

		/*declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\out'

		declare @FileDirResOTC varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\OTC_Sec'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Отчет по сделкам\temp\FX'*/



		/*declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Technical do not delete\Templates for Confo'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\Archive'

		declare @FileDirResOTC varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\OTC_SPOT'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Trade Confo\OTC_FX'*/



		/*

		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Technical do not delete\New Order Confo\templates'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\Archive'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\FX'

		declare @FileDirResSPOT varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Trade Confo OLD\Actual Order Confo\SPOT'

		*/



		declare @FileDir varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Templates'

		declare @FileDirOut varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Order Confirmations\Archive'

		declare @FileDirResFX varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Order Confirmations\FX'

		declare @FileDirResSPOT varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Order Confirmations\SPOT'

		declare @FileDirResREPO varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Order Confirmations\REPO'



		declare @FileDirOutTrades varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\Archive'

		declare @FileDirResREPO2 varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Trade Confirmations\REPO'





		if right(@FileDir, 1) <> '' set @FileDir = @FileDir + '\'

		if right(@FileDirOut, 1) <> '' set @FileDirOut = @FileDirOut + '\'

		if right(@FileDirOutTrades, 1) <> '' set @FileDirOutTrades = @FileDirOutTrades + '\'

		if right(@FileDirResFX, 1) <> '' set @FileDirResFX = @FileDirResFX + '\'

		if right(@FileDirResSPOT, 1) <> '' set @FileDirResSPOT = @FileDirResSPOT + '\'

		if right(@FileDirResREPO, 1) <> '' set @FileDirResREPO = @FileDirResREPO + '\'

		if right(@FileDirResREPO2, 1) <> '' set @FileDirResREPO2 = @FileDirResREPO2 + '\'

		declare @FileDirRes varchar(255)

		declare @FileNameData varchar(128) --= 'sec_06.xlsx'

		declare @FileNameEmpty varchar(128) --= 'sec_06e.xlsx'

		declare @ReportDate int = cast(convert(varchar, getdate(), 112) as int)

		declare @Sheet varchar(64) = '5 Currency order_eng'

		declare @Sheet2 varchar(64) = 'TextForEMail'





		declare @NewFileName varchar(255) = 'order_'+ cast(@OrderID as varchar) + '_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx'

		declare @NewFileNameRes varchar(255) = 'order_'+ cast(@OrderId as varchar) + iif(@repoStep = 1, '_confo', '') + '.xlsx'

		print @NewFileName





		declare @res table(r varchar(255))

		declare @cmd varchar(512)

		declare @sql nvarchar(max)







		declare @ConstitutorCode varchar(128)

		declare @SecurityType varchar(128) = 'NOT FOUND'

		declare @AssetShortName varchar(128)

		declare @AssetCurrency varchar(128)

		declare @Quantity float

		declare @TransactionType varchar(128)

		declare @OrderType varchar(128)

		declare @RegisterNum varchar(128)



		declare @AssetBaseCurrency varchar(128)

		declare @AssetDescription varchar(128)

		declare @Issuer nvarchar(128)

		declare @ISIN varchar(128)



		declare @BuySell varchar(16)



		declare @QuantitativeCondition varchar(128)

		declare @BaseValue float

		declare @Price float

		declare @Yield float

		declare @PlaceOfSettlement varchar(128)



		declare @OtherInstructions varchar(1024)

		declare @2OtherInstructions varchar(1024) = ''

		declare @3OtherInstructions varchar(1024) = ''

		declare @CPFirmShortName varchar(128)



		--declare @Comment varchar(255)

		declare @OrderDate int

		declare @OrderDate2 int

		declare @OrderConditions varchar(128) = 'Open'



		declare @IsRepo bit = 0

		declare @RepoDate2 int

		declare @RepoRate float

		declare @RepoTerm int

		declare @PutPlannedDate int



		declare @Com1 varchar(255)

		declare @Com2 varchar(255)

		declare @Com3 varchar(255)



		declare @ReportDateVarchar varchar(16) = QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(cast(convert(varchar, getdate(), 112) as int))





		select top 1 @ConstitutorCode = s.SubAccCode  -- s.ConstitutorCode s.ConstitutorCode

			, @SecurityType = isnull(AssetSort.SecType, @SecurityType)

			, @AssetShortName = a.ShortName

			, @AssetCurrency = aCur.ShortName

			, @Quantity = ti.Qty

			, @TransactionType = iif(ti.CpFirm_ID > 0, iif(fcp.FirmShortName = @ArmBrokShortName, 'internal', 'external'), '') -- Если галочка проставлена в поле Counterparty (корт)  заполнено любым значением, кроме  ArmBrok - external, если галочка проставлена и
 выбран Counterparty (корт)  - ArmBrok- internal 

			--, @OrderType = case ti.PRC_Const when 2 then 'Limit' when 3 then 'Market' else '' end --case

			, @OrderType = case ti.PRC_Const when 2 then 'Limit' when 3 then 'Market' when 4 then 'Limit' when 5 then 'Limit' else '' end --case

			, @RegisterNum = ti.RegisterNum

			, @AssetBaseCurrency = aBaseCur.ShortName

			, @AssetDescription = ''

			, @Issuer = fi.FirmShortName

			--, @Issuer = isnull(iif(fip.NameU <> '', fip.NameU, fi.FirmShortName), '')

			, @ISIN = a.ISIN

			, @BuySell = case ti.Type when 7 then 'Buy' when 8 then 'Sell' else 'unknown' end

			, @QuantitativeCondition = iif(ti.IsComplete = 'y', 'All or none', 'Partial')--'Partial'

			, @BaseValue = isnull(a.BaseValue, 0)

			, @Price = ti.Price

			, @Yield = iif(ti.PriceType = 20, ti.Price, 0)

			, @CPFirmShortName = fcp.FirmShortName

			--, @Comment = ti.AuthorComment

			, @OrderDate = ti.Date

			, @OrderDate2 = ti.Date2

			, @OrderConditions = case when ti.Date2 = 0 then 'Open' when ti.date2 = ti.date then 'Day only' else 'Good till ' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.date2) end -- case

			, @IsRepo = iif(ti.RepoDate2 > 0 or ti.RepoRate > 0 or ti.RepoTerm > 0, 1, 0)

			, @RepoDate2 = ti.RepoDate2

			, @RepoRate = ti.RepoRate

			, @RepoTerm = ti.RepoTerm

			, @PutPlannedDate = ti.PutPlannedDate

			, @Com1 = isnull(com1.com1, '')

			, @Com2 = isnull(com2.com2, '')

			, @Com3 = isnull(com3.com3, '')

			, @PlaceOfSettlement = isnull(com11.com11, '')

			, @OtherInstructions = isnull(com12.com12, '')

			, @2OtherInstructions = isnull(com13.com13, '')

			, @3OtherInstructions = isnull(com14.com14, '')

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

		outer apply (select val com1 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 1) com1

		outer apply (select val com2 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 2) com2

		outer apply (select val com3 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AuthorComment, '*') where num = 3) com3

		outer apply (select val com11 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AgentComment, '*') where num = 1) com11

		outer apply (select val com12 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AgentComment, '*') where num = 2) com12

		outer apply (select val com13 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AgentComment, '*') where num = 3) com13

		outer apply (select val com14 from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(ti.AgentComment, '*') where num = 4) com14

		where ti.id = @OrderId



		declare @Volume1 float = 0

		declare @Volume2 float = 0

		declare @TradeDate int = 0

		declare @TradeTime int = 0

		declare @EndDate int = 0



		if @IsRepo = 1 and @repoStep = 1 begin

			select top 1 @TradeDate = t1.TradeDate

				, @TradeTime = t1.TradeTime

				, @AssetCurrency = aCur.ShortName

				, @EndDate = t2.PutPlannedDate

				, @Volume1 = iif(t1.IsAccrued = 'n' and IsBond = 1, t1.Volume1 + t1.Accruedint, t1.Volume1)

				, @Volume2 = iif(t2.IsAccrued = 'n' and IsBond = 1, t2.Volume1 + t2.Accruedint, t2.Volume1)

				, @Com1 = isnull(QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(com.Commission), '')

			from QORT_BACK_DB.dbo.TradeInstrs ti with (nolock)

			inner join QORT_BACK_DB.dbo.TradeInstrLinks til with (nolock) on til.TradeInstr_ID = ti.id

			inner join QORT_BACK_DB.dbo.Trades t1 with (nolock) on t1.id = til.Trade_ID and t1.IsRepo2 = 'n'

			inner join QORT_BACK_DB.dbo.Trades t2 with (nolock) on t2.id = t1.RepoTrade_ID

			left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t1.Security_ID

			left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

			left outer join QORT_ARM_SUPPORT.dbo.Assets_AS AssetSort with (nolock) on AssetSort.ConstInt = a.AssetSort_Const

			left outer join QORT_BACK_DB.dbo.Assets aCur with (nolock) on aCur.id = t1.CurrPayAsset_ID

			outer apply (select iif(AssetSort.SecType = 'Bonds', 1, 0) IsBond) IsBond

			outer apply (

				select sum(p.QtyBefore) Commission, max(pCur.ShortName) CommissionCurrency

				from QORT_BACK_DB.dbo.Phases p with (nolock) 

				left outer join QORT_BACK_DB.dbo.Assets pCur with (nolock) on pCur.id = p.CurrencyAsset_ID

				where p.IsCanceled = 'n' and p.PC_Const = 9 and p.Trade_ID = t1.id

			) com

			where ti.id = @OrderId

			order by t1.id desc

		end

		/*

		Если buy - I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order. 

		Если sell - пусто. 

		Если Buy и Counterparty Glocal OJSC…. Добавляем 

		I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order + Please purchase securities from entities/individuals, which are not entities/individuals from unfriendly st
ates, provided that such securities were purchased by such entities/individuals from entities/individuals, which themselves are not entities/individuals from unfriendly states (as described in President Decree No. 81 of 01.03.2022 (as amended) and Governm
ent Order No. 430-r of 05.03.2022 (as amended)). 

		с возможность редактировать 

		*/

		/*

		if @SecurityType = 'Currency' begin

			if @BuySell = 'Buy' begin

				set @OtherInstructions = 'I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order.'

				if @CPFirmShortName = 'Glocal CJSC' set @OtherInstructions = @OtherInstructions + ' ' + 'I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order + Please purchase 
securities from entities/individuals, which are not entities/individuals from unfriendly states, provided that such securities were purchased by such entities/individuals from entities/individuals, which themselves are not entities/individuals from unfrie
ndly states (as described in President Decree No. 81 of 01.03.2022 (as amended) and Government Order No. 430-r of 05.03.2022 (as amended)).'

			end else set @OtherInstructions = ''

		end else begin*/

			/*

			Петя, сделай плиз правку для формы по Бумагам

			поле Other Instruction (и на печатном листе. и том, что для Email). Если сделка sell = пусто 

			Если buy и не заполнено в ордере в Корт поле контрагент пишем это =  

			I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order.

			Если Buy и заполнено поле  Counterparty  то это = 

			1)  I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order 

			2) Please purchase securities from entities/individuals, which are not entities/individuals from unfriendly states, provided that such securities were purchased by such entities/individuals from entities/individuals, which themselves are not entities/i
ndividuals from unfriendly states (as described in President Decree No. 81 of 01.03.2022 (as amended) and Government Order No. 430-r of 05.03.2022 (as amended)).

 			*/

			/*if @BuySell = 'Buy' begin				

				if @CPFirmShortName <> '' begin

					set @OtherInstructions = '1) I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order ' 

					set @2OtherInstructions = '2) Please purchase securities from entities/individuals, which are not entities/individuals from unfriendly states, provided that such securities were purchased by such entities/individuals from entities/individuals,'

					set @3OtherInstructions = 'which themselves are not entities/individuals from unfriendly states (as described in President Decree No. 81 of 01.03.2022 (as amended) and Government Order No. 430-r of 05.03.2022 (as amended)).'

				end else set @OtherInstructions = 'I hereby give my consent to the use of my funds by ARMBROK OJSC at its own discretion within the framework of the execution of this Trade order.'

			end else set @OtherInstructions = ''

		end*/



		--print @OtherInstructions



		if @IsRepo = 1 begin

			if @repoStep = 0 begin

				set @FileNameData = 'order_repo_02.xlsx'

				set @FileNameEmpty = 'order_repo_02e.xlsx'

				set @Sheet = 'Repo order'

				set @FileDirRes = @FileDirResREPO			

			end else begin

				set @FileDirOut = @FileDirOutTrades

				set @FileDirResREPO = @FileDirResREPO2



				set @FileNameData = 'trade_repo_03.xlsx'

				set @FileNameEmpty = 'trade_repo_03e.xlsx'

				set @Sheet = 'Repo confirmation'

				set @FileDirRes = @FileDirResREPO			

			end

		end else if @SecurityType = 'Currency' begin

			set @FileNameData = 'order_fx_02.xlsx'

			set @FileNameEmpty = 'order_fx_02e.xlsx'

			set @Sheet = '5 Currency order_eng'

			set @FileDirRes = @FileDirResFX

			--set @PlaceOfSettlement = 'Settle on Armbrok account'



			if @buysell = 'Sell' begin

				-- если продажа FX, то меняем местами актив и валюту

				set @AssetBaseCurrency = @AssetShortName

				set @AssetShortName = @AssetCurrency

				set @AssetCurrency = @AssetBaseCurrency

			end



		end else if @SecurityType = 'NOT FOUND' begin

			set @Message = 'Order Not Found'

			RAISERROR (@Message, 16, 1);

		end else begin --if @SecurityType in ('NOT FOUND123') begin

			set @FileNameData = 'order_buysell_02.xlsx'

			set @FileNameEmpty = 'order_buysell_02e.xlsx'

			set @Sheet = '2 Trade order'

			set @FileDirRes = @FileDirResSPOT

			--set @PlaceOfSettlement = ''

		end/* else begin

			set @Message = 'Unknown Security Type: ' + isnull(@SecurityType, 'NULL')

			RAISERROR (@Message, 16, 1);

		end*/





		if OBJECT_ID('tempdb..##OrderConfo', 'U') is not null drop table ##OrderConfo

		if OBJECT_ID('tempdb..##MailConfo', 'U') is not null drop table ##MailConfo

		if OBJECT_ID('tempdb..##repOC', 'U') is not null drop table ##repOC

		create table ##repOC (repFrom nvarchar(128), repTo nvarchar(1024))



		SET @sql = 'SELECT * INTO ##OrderConfo

		FROM OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDir+@FileNameData + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet + '$A1:Z1000]'')'



		exec(@sql)



		--alter table ##OrderConfo alter column F5 varchar(1024)

--select * from ##OrderConfo order by a



		SET @sql = 'SELECT * INTO ##MailConfo

		FROM OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDir+@FileNameData + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet2 + '$A1:Z1000]'')'



		exec(@sql)



		--select * from ##OrderConfo





		set @cmd = 'copy "' + @FileDir + @FileNameEmpty + '" "' + @FileDirOut + @NewFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @FileDirOut + @NewFileName

			RAISERROR (@execres, 16, 1);

		end













		insert into ##repOC(repFrom, repTo)

		select *

		from (values 

			('@OrderId', cast(@OrderId as varchar(128))) 

			, ('@RegisterNum', isnull(@RegisterNum, '')) 

			, ('@ConstitutorCode', isnull(@ConstitutorCode, '')) 

			, ('@AssetShortName', @AssetShortName)

			, ('@AssetCurrency', isnull(@AssetCurrency, ''))



			, ('@AssetBaseCurrency', isnull(@AssetBaseCurrency, ''))

			, ('@SecurityType', isnull(@SecurityType, ''))

			, ('@AssetDescription', isnull(@AssetDescription, ''))

			, ('@Issuer', isnull(@Issuer, ''))

			, ('@ISIN', isnull(@ISIN, ''))



			, ('@BuySell', isnull(@BuySell, ''))

			, ('@QuantitativeCondition', isnull(@QuantitativeCondition, ''))

			, ('@Quantity', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Quantity))

			--, ('@TotalNominal', iif(@SecurityType = 'Bonds', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Quantity * @BaseValue), ''))

			--, ('@TotalNominal', iif(@SecurityType = 'Bonds', QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(@Quantity * @BaseValue), ''))

			, ('@TotalNominal', iif(@BaseValue > 1e-8, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(@Quantity * @BaseValue), ''))



			, ('@PriceAbsolute', iif(@SecurityType <> 'Bonds' and @Price <> 0, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Price), '-'))

			, ('@Yield', iif(@Yield <> 0, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(@Yield) + '%', '-'))

			, ('@PricePercent', iif(@SecurityType = 'Bonds' and @Price <> 0 and abs(@Yield) < 1e-8, QORT_ARM_SUPPORT.dbo.fFloatYieldToVarchar(@Price) + '%', '-'))

			, ('@TransactionValue', iif(@SecurityType <> 'Bonds' and @Price <> 0 and @OrderType <> '@Market', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Price*@Quantity), '-'))

			

			, ('@QtyToBuy', iif(@buysell = 'Buy', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Quantity), ''))

			, ('@QtyToSell', iif(@buysell = 'Sell', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Quantity), ''))

			, ('@Rate', iif(@Price <> 0, QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(iif(@buysell = 'Sell', 1 / @Price, @Price)), ''))

			, ('@TransactionType', @TransactionType)

			, ('@OrderType', @OrderType)

			, ('@OrderConditions', @OrderConditions)

			, ('@OrderPeriod', '')

			--, ('@Commission', '???')

			--, ('@Commission', @Comment)

			--, ('@Bonus', '0')

			, ('@Commission', @Com1)

			, ('@Bonus', @Com2)

			, ('@BonCurrency', @Com3)



			, ('@PlaceOfSettlement', @PlaceOfSettlement)

			, ('@NameAndPosition', '??? список ???')



			, ('@OtherInstructions', @OtherInstructions)

			, ('@2OtherInstructions', @2OtherInstructions)

			, ('@3OtherInstructions', @3OtherInstructions)



			, ('@RepoRate', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@RepoRate) + '%')

			, ('@RepoTermDay', iif(@RepoTerm > 0, cast(@RepoTerm as varchar(128)), ''))

			, ('@RepoBackDate', iif(@RepoDate2 > 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@RepoDate2), ''))

			, ('@CounterpartyName', isnull(@CPFirmShortName, ''))

			, ('@RepoDeliveryDate', iif(@PutPlannedDate > 0, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@PutPlannedDate), ''))



			, ('@Volume1', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Volume1))

			, ('@Volume2', QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(@Volume2))

			, ('@TradeDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@TradeDate))

			, ('@TradeTime', iif(@TradeTime > 0, QORT_ARM_SUPPORT.dbo.fIntToTimeVarchar(@TradeTime), ''))

			, ('@EndDate', isnull(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@EndDate), ''))

			, ('@IssueNumber', '')

			, ('@ReportDate', QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(@ReportDate))



		) as t(repFrom, repTo)





		declare @columns varchar(1024)

		declare @columnsCount int





		select @columnsCount = count(*)

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##OrderConfo') and c.name like 'F_%'





		select @columns = cast((

		select c.name + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##OrderConfo') and c.name like 'F_%'

		order by column_id

		for xml path('')) as varchar(1024))



		select @columns = left(@columns, len(@columns) - 1)

		--select @columnsCount, @columns



		select @sql = cast((

		select 't.' + c.name + ' = replace(t.' + c.name + ', ''@repFrom'', ''@repTo'')' + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##OrderConfo') and c.name like 'F%'

		order by column_id

		for xml path('')) as varchar(max))



--select * from ##OrderConfo t

--select * from ##MailConfo t

--select * from ##repOC r



		select @sql = 'update t set ' + left(@sql, len(@sql) - 1) + ' from ##OrderConfo t'



		select @sql = cast((

		select replace(replace(@sql, '@repFrom', r.repFrom), '@repTo', r.repTo) + ';'

		from ##repOC r

		for xml path('')) as varchar(max))



		print @sql



		exec(@sql)



		delete t

		from ##OrderConfo t

		where a is null



--select F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16 from ##OrderConfo order by a



		SET @sql = 'insert into OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet + '$B1:'+char(ascii('B') + @columnsCount-1)+'1]'')

		select ' + @columns + ' from ##OrderConfo order by a'



		print @sql

		exec(@sql)











		select @columnsCount = count(*)

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##MailConfo') and c.name like 'F_%'





		select @columns = cast((

		select c.name + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##MailConfo') and c.name like 'F_%'

		order by column_id

		for xml path('')) as varchar(1024))



		select @columns = left(@columns, len(@columns) - 1)

		--select @columnsCount, @columns



		select @sql = cast((

		select 't.' + c.name + ' = replace(t.' + c.name + ', ''@repFrom'', N''@repTo'')' + ', '

		from tempdb.sys.columns c with (nolock)

		where c.object_id = object_id('tempdb.dbo.##MailConfo') and c.name like 'F%'

		order by column_id

		for xml path('')) as varchar(max))



--select * from ##OrderConfo t



		select @sql = 'update t set ' + left(@sql, len(@sql) - 1) + ' from ##MailConfo t'



		select @sql = cast((

		select replace(replace(@sql, '@repFrom', r.repFrom), '@repTo', r.repTo) + ';'

		from ##repOC r

		for xml path('')) as varchar(max))



		print @sql



		exec(@sql)



		delete t

		from ##MailConfo t

		where a is null



		SET @sql = 'insert into OPENROWSET (

		''Microsoft.ACE.OLEDB.12.0'',

		''Excel 12.0; Database='+ @FileDirOut + @NewFileName + '; HDR=YES;IMEX=0'',

		''SELECT * FROM [' + @Sheet2 + '$B1:'+char(ascii('B') + @columnsCount-1)+'1]'')

		select ' + @columns + ' from ##MailConfo order by a'



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

