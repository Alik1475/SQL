







-- exec QORT_ARM_SUPPORT.dbo.exportTrades_RegulatoryNY11FX '20241226'

-- exec QORT_ARM_SUPPORT.dbo.exportTrades_RegulatoryNY11FX '20240627'



CREATE PROCEDURE [dbo].[exportTrades_RegulatoryNY11FX]

	@TradeDate date

AS

BEGIN



	begin try



		SET NOCOUNT ON



		declare @Message varchar(1024)

		--declare @TradeDateFrom int = cast(convert(varchar, dateadd(day, -1, @TradeDate), 112) as int)

		declare @TradeDateFrom int = cast(convert(varchar, QORT_ARM_SUPPORT.dbo.fGetPrevBusinessDay(@TradeDate), 112) as int)

		declare @TradeDateTo int = cast(convert(varchar, @TradeDate, 112) as int)

		declare @TradeTimeFrom int = 160000000 --(16:00:00.000)

		declare @ArmBrokFirmShortName varchar(16) = 'Armbrok OJSC'



		declare @sql varchar(max)

		/*declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\Temp\42000_NY11_workTemplate_10.xlsx'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\Temp\42000_NY11_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx'


		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY11_'+cast(@TradeDateTo as varchar)+'.xlsx'*/

		/*declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\42000_NY11_workTemplate_12.xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\Temp\42000_NY11_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xls'


		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY11_'+cast(@TradeDateTo as varchar)+'.xls'*/

		--declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\template\42000_NY11_workTemplate_12.xls'

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\template\42000_NY11_workTemplate_14_test.xls'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\archive\42000_NY11_workTemplate_' +cast(@TradeDateTo as varchar) +'_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varch
ar, getdate(), 108), ':', '') + '.xls'

		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\42000_NY11_'+cast(@TradeDateTo as varchar)+'.xls'

		declare @Sheet varchar(32) = 'Sheet1'



		declare @res table(r varchar(255))

		declare @cmd varchar(512)





		set @cmd = 'copy "' + @TemplateFileName + '" "' + @TempFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @TempFileName

			RAISERROR (@execres, 16, 1);

		end



		declare @CurOrder table(Currency varchar(8) primary key, OrderBy int)



		insert into @CurOrder(Currency, OrderBy) values ('GBP', 1), ('EUR', 2), ('USD', 3), ('RUB', 4)

		--Пара валют. Первым идет значение в паре валют - EUR, если евро нет то USD

		--, далее если нет, то RUB, затем значение как в сделке (инструмент/сумма).



		--select @TradeDateFrom, @TradeDateTo



		--select * from @CurOrder



		if OBJECT_ID('tempdb..#r', 'U') is not null drop table #r

		if OBJECT_ID('tempdb..##42000_NY11_workTemplate', 'U') is not null drop table ##42000_NY11_workTemplate



		select t.id TradeId, row_number() over(order by t.TradeDate, t.TradeTime, t.id) Num

			, TradeDate, TradeTime, tss.name

			, t.BuySell, nullif(t.Qty, 0) Qty, nullif(t.Volume1, 0) Volume1, t.PutDate, t.PutPlannedDate

			, a.ShortName TradeCur, aPay.ShortName PayCur

			, fcp.FirmShortName, fcp.IsResident

			, t.CpFirm_ID

			, 0 BackOrder

			, 0 isFirstCell

			, '1234567890' CurrencyCell

			, cast(null as float) TradeQty

			, cast(null as float) TradeRate

			, cast(null as float) AvgRate

			, cast(null as float) AvgWeightRate

			, t.Price

		into #r

		from (

			/*select distinct p.Trade_ID

			from QORT_BACK_DB.dbo.Phases p with (nolock, index = I_Phases_PhaseDate)

			where p.PhaseDate between @TradeDateFrom and @TradeDateTo

				and NOT (p.PhaseDate = @TradeDateFrom and p.PhaseTime < @TradeTimeFrom)

				and NOT (p.PhaseDate = @TradeDateTo and p.PhaseTime >= @TradeTimeFrom)

				and p.IsCanceled = 'n'

				and p.PC_Const in (4)*/

			select t.id Trade_Id, t.TradeDate Trade_Date, t.TradeTime Trade_Time

			from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

			where t.TradeDate between @TradeDateFrom and @TradeDateTo

				and NOT (t.TradeDate = @TradeDateFrom and t.TradeTime < @TradeTimeFrom)

				and NOT (t.TradeDate = @TradeDateTo and t.TradeTime >= @TradeTimeFrom)

				--and (t.EventDate < 20010101 or t.EventDate = @TradeDateTo)

				and (t.EventDate = t.TradeDate) -- Alik change 20/02/2024

			union

			select t.id Trade_Id, t.EventDate Trade_Date, 0 Trade_Time 

			from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

			where t.EventDate = @TradeDateTo and t.EventDate <> t.TradeDate 



		) p

		inner join QORT_BACK_DB.dbo.Trades t with (nolock) on t.id = p.Trade_ID

		--from QORT_BACK_DB.dbo.Trades t with (nolock, index = PK_Trades)

		left outer join QORT_BACK_DB.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		--left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		--left outer join QORT_BACK_DB.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

--		where t.TradeDate between @TradeDateFrom and @TradeDateTo

--			and NOT (t.TradeDate = @TradeDateFrom and t.TradeTime < @TradeTimeFrom)

--			and NOT (t.TradeDate = @TradeDateTo and t.TradeTime >= @TradeTimeFrom)

		where t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y'

			and tss.MT_Const = 5 /*OTC*/ and tss.TT_Const = 8 /*FX/Metals*/





		update r set r.BackOrder = 1

		from #r r

		left outer join @CurOrder co1 on co1.Currency = r.TradeCur

		left outer join @CurOrder co2 on co2.Currency = r.PayCur

		where isnull(co2.OrderBy, 5) < isnull(co1.OrderBy, 5)





		update r set r.isFirstCell = iif((r.BuySell = 1 and r.BackOrder = 0) or (r.BuySell = 2 and r.BackOrder = 1), 1, 0)

			, r.CurrencyCell = iif(r.BackOrder = 0, r.TradeCur + '/' + r.PayCur, r.PayCur + '/' + r.TradeCur)

			, r.TradeQty = iif(r.BackOrder = 0, r.Qty, r.Volume1)

			, r.TradeRate = iif(r.BackOrder = 0, r.Volume1 / r.Qty, r.Qty / r.Volume1)

		from #r r





		--update r set r.AvgWeightRate = t.AvgWeightRate, r.AvgRate = t.AvgRate

		update r set r.AvgWeightRate = iif(t.tc = 1 and t.MaxPrice > 1e-8, t.MaxPrice, t.AvgWeightRate)

			, r.AvgRate = iif(t.tc = 1 and t.MaxPrice > 1e-8, t.MaxPrice, t.AvgRate)

		from #r r

		inner join (

			select r.CurrencyCell, r.IsFirstCell, count(*) tc, sum(r.TradeQty * r.TradeRate) / sum (r.TradeQty) AvgWeightRate, sum(1 * r.TradeRate) / sum (1) AvgRate, max(price) MaxPrice

			from #r r

			group by r.CurrencyCell, r.IsFirstCell

		) t on t.CurrencyCell = r.CurrencyCell and t.isFirstCell = r.isFirstCell



		--select * from #r return



		--select QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(@TradeDateTo) ReportDate



		select r.Num A--, TradeId

			, case when r.FirmShortName = @ArmBrokFirmShortName then '2' when r.FirmShortName is null then '0' else '1' end  + '/' + case r.IsResident when 'y' then '1' when 'n' then '2' else '0' end B

			, cast('ãÏ³ñ·³íáñíáÕ ßáõÏ³' as nvarchar(64)) C

			, iif(r.BackOrder = 0, r.TradeCur + '/' + r.PayCur, r.PayCur + '/' + r.TradeCur) D

			, iif(q.IsFirstCell = 1, q.Qty, null) E

			, iif(q.IsFirstCell = 1, q.Rate1, null) F

			, iif(q.IsFirstCell = 0, q.Qty, null) G

			, iif(q.IsFirstCell = 0, q.Rate1, null) H

			, q.Rate2 I

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(r.TradeDate) J

			, QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(isnull(nullif(r.PutDate, 0), r.PutPlannedDate)) K

		into ##42000_NY11_workTemplate

		from #r r

		/*outer apply(select QORT_ARM_SUPPORT.dbo.fFloatToCurrencyInt(round(iif(r.BackOrder = 0, r.Qty, r.Volume1), 0)) Qty

				, QORT_ARM_SUPPORT.dbo.fFloatToCurrencyInt(round(iif(r.BackOrder = 0, r.Volume1 / r.Qty, r.Qty / r.Volume1), 0)) Rate

				, iif((r.BuySell = 1 and r.BackOrder = 0) or (r.BuySell = 2 and r.BackOrder = 1), 1, 0) IsFirstCell

			) q*/

		/*outer apply(select QORT_ARM_SUPPORT.dbo.fFloatToDecimal2(r.TradeQty) Qty

				, QORT_ARM_SUPPORT.dbo.fFloatToDecimal(r.AvgWeightRate) Rate1

				, QORT_ARM_SUPPORT.dbo.fFloatToDecimal(r.AvgRate) Rate2

				, r.IsFirstCell

			) q*/

		outer apply(select cast(r.TradeQty as decimal(32,2)) Qty

				, cast(r.AvgWeightRate as decimal(32,8)) Rate1

				, cast(r.AvgRate as decimal(32,8)) Rate2

				, r.IsFirstCell

			) q --*/

		order by 1





		update t set t.C = l.v1

		from ##42000_NY11_workTemplate t

		inner join QORT_ARM_SUPPORT.dbo.lang_const l on l.c1 = '42000_NY11_workTemplate'



/*

		select *

		from ##42000_NY11_workTemplate

		order by 1

*/



		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A12:K13]'')

			select * from ##42000_NY11_workTemplate order by A'

		print @sql

		exec(@sql)







		SET @sql = 'UPDATE t SET t.F1 = ''' + QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(@TradeDateTo) + '''

			from OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$E9:E10]'') t'

		print @sql

		exec(@sql)



		SET @sql = 'UPDATE t SET t.F1 = ''' + QORT_ARM_SUPPORT.dbo.fIntToDateVarcharShort(@TradeDateTo) + '''

			from OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$G9:G10]'') t'

		print @sql

		exec(@sql)



		set @cmd = 'copy "' + @TempFileName + '" "' + @ResultFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))

		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @ResultFileName

			RAISERROR (@execres, 16, 1);

		end



		select 'Report Done: ' + @ResultFileName ResultStatus, 'green' ResultColor



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		select @Message ResultStatus, 'red' ResultColor

	end catch



END

