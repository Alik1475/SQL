



-- exec QORT_ARM_SUPPORT.dbo.upload_Reconcilation







CREATE PROCEDURE [dbo].[upload_Reconcilation]

	

AS



BEGIN



	begin try



		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reconcilation'

		declare @Sheet varchar(16) 

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'

		declare @InfoSource varchar(64) = object_name(@@procid)

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		declare @aid int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int

		declare @rowsDone int

		declare @rowsError int

		declare @CheckDate as varchar(16)

		declare @CheckDateInt int 

		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)



		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

		declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		insert into @files(filename) exec master..xp_cmdshell @cmd

		

		/*delete f

		from @files f

		where not filename like '%Y.xls%'*/

		SELECT * FROM @FILES 

		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)



		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId

		SET @rowsInFile = (SELECT MAX(fileId) FROM @FILES)

		

		while (@rowsInFile > 0)

	

	begin

		select @FileName = f.filename

		from @files f

		where f.fileId = @rowsInFile

			print @FileName



			

	if @filename = 'DEPO_liteY.xlsx'	

	--------------------------------------------------------------------------------------------------------------------------------------------------------

	    begin



		  set @Sheet = 'Corporate'

		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=NO;IMEX=1'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)



			set @CheckDate  = REPLACE((select top 1 [F3] from ##comms),'.','')

		

			set @CheckDateInt = cast( RIGHT(@CheckDate,4)+left(RIGHT(@CheckDate,6),2)+left(@CheckDate,2) as int)

			

			delete from ##comms where left([F8],1) <> '4' or [F8] is null  



           select * from ##comms



			select row_number() over(order by [F8]) rn

				, @CheckDateInt Checkdate

				, [F8] Depocount

				, [F11] ISIN

				, cast([F13] as float) Qty

				, CASE  [F17]

					WHEN 'BTA' THEN 'ARMBR_DEPO_BTA'

					WHEN 'GPP' THEN 'ARMBR_DEPO_GPP'

					WHEN 'Halyk Finance' THEN 'ARMBR_DEPO_HFN'

					WHEN 'Method Investments and Advisory LTD' THEN 'ARMBR_DEPO_MTD'

					WHEN 'RONIN EUROPE LIMITED' THEN 'ARMBR_DEPO_RON'

					WHEN 'Freedom Finance' THEN 'ARMBR_DEPO_FDF'

					WHEN 'Astana International Exchange' THEN 'ARMBR_DEPO_AIX'

					WHEN 'GTN Technologies (Private) Limited' THEN 'ARMBR_DEPO_GTN'

					WHEN 'MADA CAPITAL' THEN 'ARMBR_DEPO_MAD'

					WHEN 'MAREX PRIME SERVICES LIMITED' THEN 'ARMBR_DEPO_MAREX'

					ELSE 

					iif(left([F8],14) = '42000116594323', 'GX2IN_ARMBR_DEPO_'+cast(right([F8],4) as varchar(128)),

					'ARMBR_DEPO') END Depository

					

				, isnull(da.Code,isnull(cast([F8]+'_'+isnull(Cl.NAME_Translate,'ClientNameNotFound') as varchar),'ClientNameNotFound')) code

				, isnull(a.ShortName,'AssetNoQort'+[F11]) Asset_ShortName

				 , @TodayDateInt date -- дата всегда текущая, иначе сверка в Корт не отработает. Сверяет только с данными, где текущая дата.



			into #comms 

			from ##comms t

			left join QORT_BACK_DB..FirmDEPOAccs  da on  da.DEPODivisionCode = [F8]

			left outer join QORT_BACK_DB..Assets a on a.isin = [F11] and a.IsTrading = 'y'

			left outer join QORT_ARM_SUPPORT..ClientNameTranslate cl on cl.account = [F8]

			--where da.code = 'AS1105'

			select * from #comms 



			DELETE from QORT_BACK_TDB..CheckPositions -- удаляем значения перед загрузкой новых.

			where CheckDate = @CheckDateInt and InfoSource = 'DEPOLITE' 

			or (Date = @TodayDateInt and InfoSource = 'DEPOLITE')



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			

			--/*

			INSERT INTO QORT_BACK_TDB..CheckPositions (
							Subacc_Code, 
							Account_ExportCode, 
							Asset_ShortName, 
							VolFree, 
							Date, 
							InfoSource, 
							CheckDate, 
							IsAnalytic, 
							PosDate
						)
						--*/
			SELECT 

							code, 
							Depository, 
							Asset_ShortName, 
							SUM(Qty) AS Qty, -- Суммируем значения Qty
							date, 
							'DEPOLITE' AS INFOSOURCE, 
							checkdate, 
							'n' AS IsAnalytic, 
							checkdate AS PosDate
						FROM 
							#com
ms
						GROUP BY 
							checkdate, 
							ISIN, 
							Depository, 
							code, 
							Asset_ShortName, 
							date;

		

				-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd



			

		end

		--------------------------------------------------------------------------------------------------------------------



		if left(@filename,8) = 'DEPO_CDA'

		--------------------------------------------------------------------------------------------------------------------

		begin

		   



		  set @Sheet = 'Sheet'

		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

		  IF OBJECT_ID('tempdb..#comm', 'U') IS NOT NULL DROP TABLE #comm;

		  -- IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;



			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=yes;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)



			

			set @CheckDateInt = cast(convert(varchar, left(RIGHT(@FileName,13),8), 112) as int)

		--	delete from ##comms where left([F1],3) = 'A/c'  

		select * from ##comms

		

			select row_number() over(order by [A/c Ref]) rn

				, @CheckDateInt Checkdate

				, [A/c Ref] Depocount

				, iif(left([Sec ISIN],4) = 'NONE', left([Sec ISIN],8),[Sec ISIN]) ISIN

				, [Bal Free] Qty

				, [Bal Qty] Volume

				, [Lstc Stat] LstcStat

				, 'CLIENT_CDA_Own' Depository

				, isnull(da.Code,isnull(cast(cast([A/c Ref] as nvarchar(32))+'_'+iif(Cl.NAME_Translate = '',Cl.NAME_TranslateU, Cl.NAME_Translate)  as nvarchar(32)),CAST('ClientNameNotFound'+cast([A/c Ref] as nvarchar(32)) as nvarchar(32)))) code 

				, isnull(a.ShortName,'AssetNoQort'+[Sec ISIN]) Asset_ShortName

				 , @TodayDateInt date -- дата всегда текущая, иначе сверка в Корт не отработает. Сверяет только с данными, где текущая дата.

				 , cast([A/c Own List] as nvarchar(50)) OwnName

			into #comm 

			from ##comms t

			left outer join QORT_BACK_DB..FirmDEPOAccs  da on  da.DEPOCode = [A/c Ref] and da.DEPOCode <> ''

			left outer join QORT_BACK_DB..Assets a on a.isin = iif(left([Sec ISIN],4) = 'NONE', left([Sec ISIN],8),[Sec ISIN]) and a.Enabled <> a.id and a.IsTrading = 'y'

			left outer join QORT_ARM_SUPPORT..ClientNameTranslate cl on cl.account = [A/c Ref]

			where LEFT([A/c Ref],1) = '7' 

			select * from #comm-- where ISIN = 'AMGB1029A250'



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			

			--/*

				INSERT INTO QORT_BACK_TDB..CheckPositions (

								Subacc_Code, 

								Account_ExportCode, 

								Asset_ShortName, 

								VolFree, 

								Volume, 

								Date, 

								InfoSource, 

								CheckDate, 

								IsAnalytic, 

								PosDate

							)

							--*/

				SELECT 

								code, 

								Depository, 

								Asset_ShortName,

								SUM(IIF(LstcStat = 'Not Current', CONVERT(Float, Volume), CONVERT(Float, Qty))) AS Qty, -- Суммируем свободный остаток

								SUM(CONVERT(Float, Volume) - IIF(LstcStat = 'Not Current', CONVERT(Float, Volume), CONVERT(Float, Qty))) AS Volume, -- Суммируем заблокированные средства

								date, 

								'DEPEND' AS INFOSOURCE, 

								checkdate AS CheckDate, 

								'n' AS IsAnalytic, 

								checkdate AS PosDate

							FROM 

								#comm

							GROUP BY 

								checkdate, 

								ISIN, 

								Depository, 

								code, 

								Asset_ShortName, 

								date;



			--return

			





			INSERT INTO QORT_ARM_SUPPORT..ClientNameTranslate (Account, NAME_TranslateU, NAME_Translate)

		    select distinct Depocount, OwnName as TranslateU, cast(dbo.fArmenianCharsToENG(OwnName) as varchar(50)) as NAME_Translate

			from #comm com

			 where LEFT(code,18) = 'ClientNameNotFound'







			-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd

		end

		--------------------------------------------------------------------------------------------------------------------

			if @filename = 'Register_Y.xlsb'

		--------------------------------------------------------------------------------------------------------------------

		begin

			  set @Sheet = 'Client'

		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

		  IF OBJECT_ID('tempdb..#co', 'U') IS NOT NULL DROP TABLE #co;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=yes;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)



			

			set @CheckDateInt = @TodayDateInt 

		

		select * from ##comms

		

			select row_number() over(order by [Customer Code(New)]) rn

				, @CheckDateInt Checkdate

				,ISNULL([Balance in AMD],0) AMD

				,ISNULL([Balance in USD],0) USD 

				,ISNULL([Balance in EUR],0) EUR

				,ISNULL([Balance in RUB],0) RUB

				,ISNULL([Balance in CAD],0) CAD

				,ISNULL([Balance in GBP],0) GBP

				,ISNULL([Balance in CHF],0) CHF

				,ISNULL([Balance in AED],0) AED

				,ISNULL([Balance in UAH],0) UAH

				,[Customer Code(New)] Depocount

				, 'ARMBR_MONEY' Depository

	        	 , @TodayDateInt date -- дата всегда текущая, иначе сверка в Корт не отработает. Сверяет только с данными, где текущая дата.



			into #co 

			from ##comms t

			WHERE [Customer Code(New)] is not null

		

			select * from #co



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms



			SET @rowsInFile = (SELECT MAX(rn) FROM #co)

			Declare @cc table (CheckDate int, VOL float, Depocount varchar(12) , Depository varchar(12), DATE int, currency varchar(12))

			

			while @rowsInFile > 0

		  begin

			 

			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, AMD, Depocount, Depository, DATE, 'AMD'		

			from #co co

			where @rowsInFile = co.rn and co.AMD <> 0

					

			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, USD, Depocount, Depository, DATE, 'USD'

			from #co co

			where @rowsInFile = co.rn and co.USD <> 0

			

			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, EUR, Depocount, Depository, DATE, 'EUR'

			from #co co

			where @rowsInFile = co.rn and co.EUR <> 0

			

			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, RUB, Depocount, Depository, DATE, 'RUB'

			from #co co

			where @rowsInFile = co.rn and co.RUB <> 0

			

			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, CAD, Depocount, Depository, DATE, 'CAD'

			from #co co

			where @rowsInFile = co.rn and co.CAD <> 0



			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, GBP, Depocount, Depository, DATE, 'GBP'

			from #co co

			where @rowsInFile = co.rn and co.GBP <> 0



			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, CHF, Depocount, Depository, DATE, 'CHF'

			from #co co

			where @rowsInFile = co.rn and co.CHF <> 0 



			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, AED, Depocount, Depository, DATE, 'AED'

			from #co co

			where @rowsInFile = co.rn and co.AED <> 0 



			insert into @cc(CheckDate, VOL, Depocount, Depository, DATE, currency)

			select CheckDate, UAH, Depocount, Depository, DATE, 'UAH'

			from #co co

			where @rowsInFile = co.rn and co.UAH <> 0 



			if (@rowsInFile = 1) begin-- and (@rowsInFile = @rowsDone) begin

				-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd



			end 

			set @rowsInFile = @rowsInFile - 1

		  	  

		  end

		  select * from @cc



		  INSERT INTO QORT_BACK_TDB..CheckPositions ( Subacc_Code, Account_ExportCode, Asset_ShortName, VolFree, Date, InfoSource, CheckDate, IsAnalytic, PosDate)

			SELECT Depocount, Depository, currency, ROUND(VOL,2), Date, 'REGISTER' AS INFOSOURCE, CHECKDATE, 'n' as IsAnalytic, CHECKDATE as PosDate

			FROM @cc

			--WHERE Depocount = 'AS1105'



		end

		--------------------------------------------------------------------------------------------------------------------------------------------------------

			if @filename = 'SyntheticAccountsRemains_cash.xlsx'	

	--------------------------------------------------------------------------------------------------------------------------------------------------------

	    begin



		  set @Sheet = 'Sheet1'

		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

		  IF OBJECT_ID('tempdb..#cs', 'U') IS NOT NULL DROP TABLE #cs;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=NO;IMEX=1'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)

			

			set @CheckDateint  = cast(cast(cast((left(right((select top 1 [F1] from ##comms),12),2) + 2000) as int) as varchar)

							   + cast(left(right((select top 1 [F1] from ##comms),15),2) as varchar)

							   + cast(left(right((select top 1 [F1] from ##comms),18),2) as varchar) as int)



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms



			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=NO;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:BB1000000]'')'



			exec(@sql)

			

			delete from ##comms where [F4]  is null OR [F6] IS NULL 



		

           select * from ##comms



			select row_number() over(order by [F4]) rn

				, @CheckDateInt Checkdate

				, [F4] Depocount

				, [F2] Asset_ShortName

				, CAST([F7] AS FLOAT) Qty

				, CAST([F6] AS FLOAT) QtyPlan

				, 'ARMBR_MONEY' Depository				

				, isnull(sa.SubAccCode,isnull(cast([F4]+'_'+Cl.NAME_Translate as varchar),'ClientNameNotFound')) code

				, @TodayDateInt date -- дата всегда текущая, иначе сверка в Корт не отработает. Сверяет только с данными, где текущая дата.



			into #cos

			from ##comms t

			left outer join QORT_BACK_DB..Subaccs sa on sa.Comment = [f4]

			left outer join QORT_ARM_SUPPORT..ClientNameTranslate cl on cl.account = [F4]

			select * from #cos



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			



			INSERT INTO QORT_BACK_TDB..CheckPositions (Subacc_Code, Account_ExportCode, Asset_ShortName, VolFree, VolPlan, Date, InfoSource, CheckDate, IsAnalytic, PosDate)

			SELECT CODE, Depository, Asset_ShortName, Qty, QtyPlan, Date, 'ARMSOFT' AS INFOSOURCE, CHECKDATE, 'n' as IsAnalytic, CHECKDATE as PosDate

			FROM #cos

			--WHERE code = 'AS1105'



			-- весь файл обработан, надо переложить в history

			select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

			set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

			exec master.dbo.xp_cmdshell @cmd, no_output

			--select @NewFileName, @cmd



		end

		--------------------------------------------------------------------------------------------------------------------



			-- exec QORT_ARM_SUPPORT.dbo.upload_Reconcilation

				/*INSERT INTO QORT_BACK_TDB_UAT..CheckPositions ( Subacc_Code, Account_ExportCode, Asset_ShortName, VolFree, Date, InfoSource, CheckDate, IsAnalytic, PosDate)

			SELECT CODE, Depository, Asset_ShortName, CONVERT(Float,Qty), Date, 'DEPEND' AS INFOSOURCE, CHECKDATE, 'n' as IsAnalytic, CHECKDATE as PosDate

			FROM #comm*/



			/* select @rowsInFile = count(*) from #comms

			select @rowsDone = 0, @rowsNew = 0, @rowsError = 0



			if @rowsInFile > 0 BEGIN



				update t set t.AssetId = a.Id, t.AssetShortName = isnull(a.ShortName, isnull(t.Currency, 'NULL') + ' - asset not found')

					, t.SubAccId = s.id, t.SubAccCode = s.SubAccCode

					, t.GetSubAccId = gs.id, t.GetSubAccCode = isnull(gs.SubAccCode, isnull(t.SubAccForCrediting, 'NULL') + ' - NOT FOUND')

					, t.AccountId = acc.id, t.AccountExportCode = acc.ExportCode

					, t.GetAccountId = acc.id, t.GetAccountExportCode = acc.ExportCode

					, t.trueTradeId = tt.id

					, t.IsDraft = tt.IsDraft

				from #comms t

				left outer join QORT_BACK_DB.dbo.Trades tt with (nolock) on tt.id = t.TradeId-- * 1000

				left outer join QORT_BACK_DB.dbo.Subaccs s with (nolock) on s.id = tt.SubAcc_ID

				left outer join QORT_BACK_DB.dbo.Subaccs gs with (nolock) on gs.SubAccCode = t.SubAccForCrediting collate Cyrillic_General_CS_AS

				left outer join QORT_BACK_DB.dbo.Accounts acc with (nolock) on acc.id = tt.PayAccount_ID

				outer apply (

					select top 1 a.id, a.ShortName

					from QORT_BACK_DB.dbo.Assets a with (nolock) 

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





--select * from #comms t



				set @aid = isnull((select max(aid) from QORT_BACK_TDB.dbo.Phases with (nolock)), 0)



				/*

				delete p

				from #comms t

				left outer join QORT_BACK_TDB.dbo.Phases p with (nolock) on p.Trade_SID = t.TradeId and p.PC_Const = 9 --*/



				--/*

				insert into QORT_BACK_TDB.dbo.Phases( IsProcessed, ET_Const, PC_Const, BackID, Date

					, InfoSource, PhaseAccount_ExportCode, Subacc_Code, PhaseAsset_ShortName, CurrencyAsset_ShortName

					, QtyBefore, QtyAfter, GetSubacc_Code, GetAccount_ExportCode, Trade_SID, SystemID

					, Comment) --*/

				select distinct 1 IsProcessed, 2 ET_Const, 9 PC_Const, t.BackID, cast(convert(varchar, t.Date, 112) as int) PhaseDate

					, left(@InfoSource, 64) InfoSource, t.AccountExportCode, isnull(t.SubaccCode, '') + iif(t.IsDraft = 'y', ' - DRAFT TRADE', '') SubaccCode, t.AssetShortName, t.AssetShortName CurrencyShortName

					, cast(t.Amount as decimal(32,2)) QtyBefore, -1 QtyAfter, t.GetSubaccCode, t.GetAccountExportCode, t.TradeId, -1 SystemID

					, left(@FileName, 64) Comment

				from #comms t

				left outer join QORT_BACK_DB.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.PC_Const = 9 and p.IsCanceled = 'n' and p.Enabled = 0

				where p.id is null or t.trueTradeId is null



				set @rowsNew = @@ROWCOUNT



				set @WaitCount = 1200

				while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Phases t with (nolock) where t.IsProcessed in (1,2)))

				begin

					waitfor delay '00:00:03'

					set @WaitCount = @WaitCount - 1

				end



				insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel)

				select 'TDB Commission Error: ' + @FileName +', ' + isnull(BackId, '') + ' - ' + isnull(ErrorLog, '') logMessage, 1001 errorLevel

				from QORT_BACK_TDB.dbo.Phases a with (nolock)

				where aid > @aid

					and IsProcessed = 4

					and InfoSource = @InfoSource



				set @rowsError = @@ROWCOUNT



				select @rowsDone = count(*)

				from #comms t

				inner join QORT_BACK_DB.dbo.Phases p with (nolock) on p.Trade_ID = t.TradeId and p.BackId = t.BackId and p.IsCanceled = 'n'

					

				if @rowsInFile > 0 begin

					insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel, logRecords)

					select 'File uploaded: ' + @FileName + ', lines: ' + cast(@rowsInFile as varchar) +', new Commissions: ' + cast((@rowsNew - @rowsError) as varchar) + ' / ' + cast((@rowsNew) as varchar) logMessage, iif(@rowsError > 0, 1001, 2001) errorLevel, (@rowsN
ew - @rowsError) logRecords

				end



				--select @rowsInFile, @rowsNew, @rowsError, @rowsDone



			END



			if (@rowsInFile > 0) begin-- and (@rowsInFile = @rowsDone) begin

				-- весь файл обработан, надо переложить в history

				select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

				set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

				exec master.dbo.xp_cmdshell @cmd, no_output

				--select @NewFileName, @cmd

			end



			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

			set @FileName = null



			select top 1 @FileId = f.fileId, @FileName = f.filename

			from @files f

			where f.fileId > @FileId*/

		SET @rowsInFile = @rowsInFile - 1

		PRINT @rowsInFile

		end



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

