





-- exec QORT_ARM_SUPPORT_TEST.dbo.exportTrades_RegulatoryNY11FX '20240115'

-- exec QORT_ARM_SUPPORT_TEST.dbo.exportTrades_RegulatoryNY11FX '20231011'



CREATE PROCEDURE [dbo].[exportTrades_RegulatoryNY11FX]

	@TradeDate date

AS

BEGIN



	begin try



		SET NOCOUNT ON



		declare @Message varchar(1024)

		declare @TradeDateFrom int = cast(convert(varchar, dateadd(day, -1, @TradeDate), 112) as int)

		declare @TradeDateTo int = cast(convert(varchar, @TradeDate, 112) as int)

		declare @TradeTimeFrom int = 160000000 --(16:00:00.000)

		declare @ArmBrokFirmShortName varchar(16) = 'ArmBrok'



		declare @sql varchar(max)

		declare @TemplateFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\Temp\42000_NY11_workTemplate_10.xlsx'

		declare @TempFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\NY11_workTemplate (FX)\Temp\42000_NY11_workTemplate_at_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.xlsx'


		declare @ResultFileName varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\Regulatory Reports\42000_NY11_'+cast(@TradeDateTo as varchar)+'.xlsx'

		declare @Sheet varchar(32) = 'Sheet1'



		declare @res table(r varchar(255))

		declare @cmd varchar(512)





		/*

		set @cmd = 'copy "' + @TemplateFileName + '" "' + @TempFileName + '"'



		insert into @res(r) exec master.dbo.xp_cmdshell @cmd



		declare @execres varchar(1024)

		select @execres = cast((select r + '; ' from @res for xml path('') ) as varchar(1024))



		if charindex('copied', @execres) = 0 begin

			set @execres = 'File Copy Error: ' + @execres + ' - ' + @TempFileName

			RAISERROR (@execres, 16, 1);

		end

		*/

		declare @CurOrder table(Currency varchar(8) primary key, OrderBy int)



		insert into @CurOrder(Currency, OrderBy) values ('EUR', 1), ('USD', 2), ('RUB', 3)

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

		into #r

		from QORT_BACK_DB_TEST.dbo.Trades t with (nolock, index = PK_Trades)

		left outer join QORT_BACK_DB_TEST.dbo.TSSections tss with (nolock) on tss.id = t.TSSection_ID

		--left outer join QORT_BACK_DB_TEST.dbo.Subaccs s with (nolock) on s.id = t.SubAcc_ID

		--left outer join QORT_BACK_DB_TEST.dbo.Firms fo with (nolock) on fo.id = s.OwnerFirm_ID

		left outer join QORT_BACK_DB_TEST.dbo.Securities sec with (nolock) on sec.id = t.Security_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets a with (nolock) on a.id = sec.Asset_ID

		left outer join QORT_BACK_DB_TEST.dbo.Assets aPay with (nolock) on aPay.id = t.CurrPayAsset_ID

		left outer join QORT_BACK_DB_TEST.dbo.Firms fcp with (nolock) on fcp.id = t.CpFirm_ID

		where t.TradeDate between @TradeDateFrom and @TradeDateTo

			and (t.TradeDate = @TradeDateFrom or t.TradeTime < @TradeTimeFrom)

			and (t.TradeDate = @TradeDateTo or t.TradeTime >= @TradeTimeFrom)

			and t.NullStatus = 'n' and t.Enabled = 0 and t.IsDraft = 'n' and t.IsProcessed = 'y'

			and tss.MT_Const = 5 /*OTC*/ and tss.TT_Const = 8 /*FX/Metals*/





		update r set r.BackOrder = 1

		from #r r

		left outer join @CurOrder co1 on co1.Currency = r.TradeCur

		left outer join @CurOrder co2 on co2.Currency = r.PayCur

		where isnull(co2.OrderBy, 4) < isnull(co1.OrderBy, 4)



		--select * from #r r



		--select QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(@TradeDateTo) ReportDate



		select r.Num A

			, case when r.FirmShortName = @ArmBrokFirmShortName then '2' when r.FirmShortName is null then '0' else '1' end  + '/' + case r.IsResident when 'y' then '1' when 'n' then '2' else '0' end B

			, cast('ãÏ³ñ·³íáñíáÕ ßáõÏ³' as nvarchar(64)) C

			, iif(r.BackOrder = 0, r.TradeCur + '/' + r.PayCur, r.PayCur + '/' + r.TradeCur) D

			, iif(q.IsFirstCell = 1, q.Qty, '') E

			, iif(q.IsFirstCell = 1, q.Rate, '') F

			, iif(q.IsFirstCell = 0, q.Qty, '') G

			, iif(q.IsFirstCell = 0, q.Rate, '') H

			, q.Rate I

			, QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(r.TradeDate) J

			, QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(isnull(nullif(r.PutDate, 0), r.PutPlannedDate)) K

			, TradeId

		into ##42000_NY11_workTemplate

		from #r r

		outer apply(select QORT_ARM_SUPPORT_TEST.dbo.fFloatToCurrencyInt(round(iif(r.BackOrder = 0, r.Qty, r.Volume1), 0)) Qty

				, QORT_ARM_SUPPORT_TEST.dbo.fFloatToCurrencyInt(round(iif(r.BackOrder = 0, r.Volume1 / r.Qty, r.Qty / r.Volume1), 0)) Rate

				, iif((r.BuySell = 1 and r.BackOrder = 0) or (r.BuySell = 2 and r.BackOrder = 1), 1, 0) IsFirstCell

			) q

		order by 1



/*

		update t set t.C = l.v1

		from ##42000_NY11_workTemplate t

		inner join QORT_ARM_SUPPORT_TEST.dbo.lang_const l on l.c1 = '42000_NY11_workTemplate'

*/

--/*

		select *

		from ##42000_NY11_workTemplate

		order by 1

--*/

/*

		SET @sql = 'insert into OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$A11:K12]'')

			select * from ##42000_NY11_workTemplate order by A'

		print @sql

		exec(@sql)







		SET @sql = 'UPDATE t SET t.F1 = ''' + QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(@TradeDateTo) + '''

			from OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @TempFileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet + '$E9:E10]'') t'

		print @sql

		exec(@sql)



		SET @sql = 'UPDATE t SET t.F1 = ''' + QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarcharShort(@TradeDateTo) + '''

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

*/

	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		select @Message ResultStatus, 'red' ResultColor

	end catch



END

